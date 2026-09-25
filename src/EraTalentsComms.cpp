#include "EraTalentsComms.h"
#include "EraTalents.h"
#include "EraTalentBots.h"
#include "EraTalentContent.h"
#include "EraTalentIP.h"
#include "EraTalentsConfig.h"
#include "ObjectAccessor.h"
#include "ObjectDefines.h"       // INSPECT_DISTANCE
#include "ScriptMgr.h"
#include "Player.h"
#include "SharedDefines.h"
#include "World.h"               // sWorld->getBoolConfig(CONFIG_TALENTS_INSPECTING)

#include <cctype>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

// ERATAL addon protocol.
//
// Client -> server verbs: HELLO (resync own state), LEARN <talentId>, INSPECT <guidHex>.
// Server -> client:       SYNC <era> <managed> <availPts> [<seq>/<total>] <id:rank,...>   (own state)
//                         GEN <stamp>                                                     (after SYNC)
//                         ISYNC <guidHex> <era> <managed> <classId> [<seq>/<total>] <id:rank,...>
// ISYNC answers INSPECT, ALWAYS (a denial is "ISYNC <guidHex> 0 0 0") so the client never waits.
// It reveals no more than stock CMSG_INSPECT: same gates as WorldSession::HandleInspectOpcode.
//
// Receive: OnPlayerBeforeSendChatMessage fires for EVERY chat send, including the bots'
// own addon traffic and every other addon prefix in play -- guard on Enabled() first
// (module hooks fire regardless of the enable flag) then on lang==LANG_ADDON and the
// "ERATAL" prefix before touching anything else. `type` is left alone; the addon
// channel keeps whatever chat type the client happened to send it as (observed as
// CHAT_MSG_WHISPER in the Task 1 spike), so no type check.
//
// Send: p->Whisper(text, LANG_ADDON, p) is the only delivery path that doesn't crash a
// 3.3.5a client -- CHAT_MSG_ADDON as a msgtype is fatal client-side. The client splits
// the received text on the first '\t' into (prefix, body), so every chunk is sent as
// "ERATAL\t" + body.

namespace
{
    // Leaves headroom under the 255-byte addon cap for the "ERATAL\t" prefix (7 bytes)
    // plus per-packet overhead elsewhere in the chat pipeline.
    constexpr size_t kMaxChunkBody = 230;

    // "0x" + 16 hex digits: the length of a 3.3.5a UnitGUID() string. Also caps the echo.
    constexpr size_t kMaxGuidToken = 18;

    // Split a comma-separated "id:rank" list into chunk bodies "<header>[<seq>/<total> ]<slice>",
    // each <= kMaxChunkBody. Fits in one chunk (the common case) -> one sentinel-less body (the
    // addon treats a sentinel-less message as a full reset). Otherwise every chunk gets a
    // "<seq>/<total> " sentinel right after the header so the addon ACCUMULATES across chunks --
    // without it every chunk but the last would be dropped.
    std::vector<std::string> ChunkRankList(std::string const& header, std::string const& list)
    {
        std::vector<std::string> chunks;

        if (header.size() + list.size() <= kMaxChunkBody)
        {
            chunks.push_back(header + list);
            return chunks;
        }

        // Budget leaves room for the sentinel ("NN/NN " ~= 8 bytes).
        size_t budget = (kMaxChunkBody > header.size() + 8) ? (kMaxChunkBody - header.size() - 8) : 1;
        std::string current;
        size_t start = 0;
        while (start < list.size())
        {
            size_t comma = list.find(',', start);
            std::string entry = (comma == std::string::npos) ? list.substr(start) : list.substr(start, comma - start);

            if (!current.empty() && current.size() + 1 + entry.size() > budget)
            {
                chunks.push_back(header + current);
                current.clear();
            }
            if (!current.empty())
                current += ",";
            current += entry;

            start = (comma == std::string::npos) ? list.size() : comma + 1;
        }
        if (!current.empty())
            chunks.push_back(header + current);

        if (chunks.empty())
            chunks.push_back(header);   // shouldn't happen (list empty already returned above), but stay safe

        for (size_t i = 0; i < chunks.size(); ++i)
        {
            std::string listPart = chunks[i].substr(header.size());
            chunks[i] = header + std::to_string(i + 1) + "/" + std::to_string(chunks.size()) + " " + listPart;
        }
        return chunks;
    }

    // "id:rank,..." for every node of (era, subject's class) with rank > 0, in NodesFor order.
    // ONE by-value copy of the in-memory rank cache (mutex-guarded, no DB read once loaded).
    std::string RankList(Player* subject, EraId era)
    {
        std::unordered_map<uint32, uint8> const ranks = EraTalents::Ranks(subject, era);
        std::string list;
        for (EraTalentNode const* node : sEraTalentContent->NodesFor(uint8(era), subject->getClass()))
        {
            auto it = ranks.find(node->id);
            if (it == ranks.end() || it->second == 0)
                continue;
            list += std::to_string(node->id) + ":" + std::to_string(uint32(it->second)) + ",";
        }
        if (!list.empty())
            list.pop_back();   // trim trailing comma
        return list;
    }

    // "0x<hex>" (<= 16 hex digits) -> ObjectGuid. Anything else is rejected.
    bool ParseGuidToken(std::string const& token, ObjectGuid& out)
    {
        if (token.size() < 3 || token.size() > kMaxGuidToken || token[0] != '0' || (token[1] != 'x' && token[1] != 'X'))
            return false;
        uint64 raw = 0;
        for (size_t i = 2; i < token.size(); ++i)
        {
            unsigned char c = static_cast<unsigned char>(token[i]);
            if (!std::isxdigit(c))
                return false;
            raw = (raw << 4) | uint64(std::isdigit(c) ? c - '0' : std::tolower(c) - 'a' + 10);
        }
        out = ObjectGuid(raw);
        return true;
    }

    // The inspected player iff stock CMSG_INSPECT would show its talents to `requester`
    // (mirrors WorldSession::HandleInspectOpcode) AND its talent set is era-managed.
    Player* InspectTarget(Player* requester, ObjectGuid const& guid)
    {
        Player* t = ObjectAccessor::GetPlayer(*requester, guid);
        if (!t)
            return nullptr;
        if (!requester->IsWithinDistInMap(t, INSPECT_DISTANCE, false))
            return nullptr;
        if (requester->IsValidAttackTarget(t))
            return nullptr;
        if (!sWorld->getBoolConfig(CONFIG_TALENTS_INSPECTING) && !requester->CanBeGameMaster())
            return nullptr;
        if (!EraTalentBots::IsEraManaged(t))
            return nullptr;
        return t;
    }

    // "ISYNC <guidHex> <era> <managed> <classId> [<seq>/<total>] <id:rank,...>". Any gate failure
    // -> the single denial body "ISYNC <guidHex> 0 0 0". The token is echoed (capped) so the
    // client can drop a reply for a target it has stopped inspecting.
    std::vector<std::string> BuildInspectSync(Player* requester, std::string const& token)
    {
        std::string const echo = token.substr(0, kMaxGuidToken);
        ObjectGuid guid;
        Player* t = ParseGuidToken(token, guid) ? InspectTarget(requester, guid) : nullptr;
        if (!t)
            return { "ISYNC " + echo + " 0 0 0" };

        EraId era = EraTalentBots::EraFor(t);
        std::string header = "ISYNC " + echo + " " + std::to_string(uint32(era)) + " 1 "
                           + std::to_string(uint32(t->getClass())) + " ";
        return ChunkRankList(header, RankList(t, era));
    }

    void SendInspectSync(Player* requester, std::string const& token)
    {
        for (std::string const& body : BuildInspectSync(requester, token))
            requester->Whisper(std::string("ERATAL\t") + body, LANG_ADDON, requester);
    }
}

namespace EraTalentsComms
{
    std::vector<std::string> BuildSync(Player* p)
    {
        EraId era = EraFromIP(p);
        int availPts = EraTalents::AvailablePoints(p, era);

        // `managed` (1/0) is server-authoritative: it tells the addon whether to REPLACE the native
        // talent frame with our window. Only an era with authored trees is managed; a TBC character
        // (no trees yet) sends managed=0 and keeps Blizzard's WotLK frame. Header layout:
        //   "SYNC <era> <managed> <availPts> [<seq>/<total>] <id:rank,...>"
        int managed = EraHasTalentTrees(era) ? 1 : 0;
        std::string header = "SYNC " + std::to_string(uint32(era)) + " " + std::to_string(managed)
                           + " " + std::to_string(availPts) + " ";
        return ChunkRankList(header, RankList(p, era));
    }

    void SendSync(Player* p)
    {
        for (std::string const& body : BuildSync(p))
            p->Whisper(std::string("ERATAL\t") + body, LANG_ADDON, p);

        // Generation canary: the addon compares this stamp (from era_talent_meta, i.e. the
        // imported SQL generation) against the client MPQ's sentinel spell 932999 and warns
        // the player when the installed patch-V.mpq is a different generation.
        std::string const& stamp = sEraTalentContent->GenerationStamp();
        if (!stamp.empty())
            p->Whisper(std::string("ERATAL\tGEN ") + stamp, LANG_ADDON, p);
    }
}

class era_talents_comms : public PlayerScript
{
public:
    era_talents_comms() : PlayerScript("era_talents_comms") {}

    void OnPlayerBeforeSendChatMessage(Player* p, uint32& /*type*/, uint32& lang, std::string& msg) override
    {
        if (!sEraTalentsConfig->Enabled() || lang != LANG_ADDON)
            return;

        size_t tab = msg.find('\t');
        if (tab == std::string::npos)
            return;
        if (msg.compare(0, tab, "ERATAL") != 0)
            return;

        std::string body = msg.substr(tab + 1);
        std::istringstream iss(body);
        std::string verb;
        iss >> verb;

        if (verb == "LEARN")
        {
            uint32 talentId = 0;
            iss >> talentId;
            std::string err;
            EraTalents::TryLearn(p, talentId, err);   // engine re-validates authoritatively; client just gets fresh SYNC
        }
        else if (verb == "HELLO")
        {
            // no-op: just resync below -- the addon sends HELLO on login/reload to pull state.
        }
        else if (verb == "INSPECT")
        {
            std::string token;
            iss >> token;
            SendInspectSync(p, token);
            return;   // the requester's own state did not change -- no trailing SYNC
        }
        else
        {
            return;
        }

        EraTalentsComms::SendSync(p);   // always answer with fresh state
    }
};

void AddSC_era_talents_comms()
{
    new era_talents_comms();
}
