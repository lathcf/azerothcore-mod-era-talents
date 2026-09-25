-- ERATAL protocol: receive SYNC (replace-per-message) + ISYNC (inspect replies), send HELLO / LEARN / INSPECT.
-- No WoW API calls at file scope (so this file loads under a headless lua5.1 test).
EraTalents = EraTalents or {}
local ET = EraTalents

-- Inspect state: `current` = the GUID string the stock Inspect frame is showing (set by Inspect.lua),
-- `cache[guid]` = { era, managed, classId, ranks } from ISYNC. Wiped when the Inspect frame closes.
ET.inspect = ET.inspect or { current = nil, cache = {} }

-- Parse "SYNC <era> <managed> <availPts> [<seq>/<total>] <id:rank,...>". A <seq>/<total>
-- sentinel enables multi-chunk accumulation: seq==1 (or no sentinel) resets
-- era/availPts/ranks; seq>1 merges into the existing ranks. Returns true iff SYNC.
-- `managed` (1/0) is SERVER-AUTHORITATIVE: the server owns the implemented-era allowlist, so
-- the client never decides for itself whether to replace the native talent frame. A TBC-era
-- character (no trees built yet) arrives with managed=0 and keeps Blizzard's WotLK frame.
function ET.ParseSync(state, message)
  local era, managed, pts, rest = string.match(message, "^SYNC%s+(%d+)%s+(%d+)%s+(%-?%d+)%s*(.*)$")
  if not era then return false end
  local seq, total, tail = string.match(rest, "^(%d+)/(%d+)%s*(.*)$")
  local isFirst
  if seq then
    isFirst = (tonumber(seq) == 1)
    rest = tail
  else
    isFirst = true   -- sentinel-less message = single chunk = reset
  end
  state.era = tonumber(era)
  state.availPts = tonumber(pts)
  state.isEraChar = (tonumber(managed) == 1)
  if isFirst then state.ranks = {} end
  for id, rank in string.gmatch(rest, "(%d+):(%d+)") do
    state.ranks[tonumber(id)] = tonumber(rank)
  end
  return true
end

-- Parse "ISYNC <guid> <era> <managed> <classId> [<seq>/<total>] <id:rank,...>" into cache[guid].
-- Same accumulate/reset rules as ParseSync (sentinel-less or seq==1 resets that guid's ranks; seq>1
-- merges). A denial is "ISYNC <guid> 0 0 0" (managed=false, no ranks). Returns the guid, or nil if
-- the message is not an ISYNC. Pure: no WoW API.
function ET.ParseInspectSync(cache, message)
  local guid, era, managed, cls, rest =
    string.match(message, "^ISYNC%s+(%S+)%s+(%d+)%s+(%d+)%s+(%d+)%s*(.*)$")
  if not guid then return nil end
  local seq, total, tail = string.match(rest, "^(%d+)/(%d+)%s*(.*)$")
  local isFirst = true
  if seq then
    isFirst = (tonumber(seq) == 1)
    rest = tail
  end
  local e = cache[guid]
  if not isFirst and not e then return guid end   -- orphan continuation (its chunk 1 was dropped): ignore
  if isFirst then
    e = { ranks = {} }
    cache[guid] = e
  end
  e.partial = (seq ~= nil) and (tonumber(seq) < tonumber(total))   -- more chunks still to come
  e.era = tonumber(era)
  e.managed = (tonumber(managed) == 1)
  e.classId = tonumber(cls)
  for id, rank in string.gmatch(rest, "(%d+):(%d+)") do
    e.ranks[tonumber(id)] = tonumber(rank)
  end
  return guid
end

-- Generation canary. The server sends "GEN <stamp>" (from era_talent_meta) after every SYNC;
-- the installed client patch carries the same stamp in sentinel spell 932999's NAME
-- ("EraTalents Gen <stamp>"). A mismatch means the player's Data/patch-V.mpq is a different
-- generation than the server data — tooltips/spells may lie — so warn loudly.
ET.SENTINEL_SPELL_ID = 932999

function ET.CheckGeneration(serverStamp)
  ET.state.serverGen = serverStamp
  local name = GetSpellInfo and GetSpellInfo(ET.SENTINEL_SPELL_ID) or nil
  local clientStamp = name and string.match(name, "Gen (%x+)$") or nil
  ET.state.clientGen = clientStamp
  if clientStamp ~= serverStamp then
    local msg = string.format(
      "|cffff2020EraTalents: your client patch is generation %s but the server is %s. " ..
      "Replace Data/patch-V.mpq with the current one and restart the game.|r",
      clientStamp or "MISSING", serverStamp)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
  end
end

function ET.OnAddonMsg(prefix, message)
  if prefix ~= ET.PREFIX then return end
  local gen = string.match(message, "^GEN%s+(%x+)$")
  if gen then
    ET.CheckGeneration(gen)
    return
  end
  local iguid = string.match(message, "^ISYNC%s+(%S+)")
  if iguid then
    -- Only the target the Inspect frame is showing NOW is cached. A reply that lands after the frame
    -- closed or moved on would otherwise survive the OnHide wipe and be served as a stale (or, for a
    -- late continuation chunk, partial) tree on the next inspect of that character.
    if iguid == ET.inspect.current then
      ET.ParseInspectSync(ET.inspect.cache, message)
      if ET.RefreshInspect then ET.RefreshInspect() end   -- Inspect.lua (absent in tests)
    end
    return
  end
  if ET.ParseSync(ET.state, message) then
    if ET.Refresh then ET.Refresh() end   -- TalentUI hook (may be absent in tests)
  end
end

function ET.Send(payload)
  SendAddonMessage(ET.PREFIX, payload, "WHISPER", UnitName("player"))
end
function ET.RequestSync() ET.Send("HELLO") end
function ET.Learn(id) ET.Send("LEARN " .. id) end
function ET.RequestInspect(guid) ET.Send("INSPECT " .. guid) end

function ET.InitComms()
  local f = CreateFrame("Frame")
  f:RegisterEvent("CHAT_MSG_ADDON")
  f:SetScript("OnEvent", function(self, event, prefix, message)
    ET.OnAddonMsg(prefix, message)
  end)
end
