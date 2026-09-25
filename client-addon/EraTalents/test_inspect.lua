-- test_inspect.lua — headless: the ISYNC protocol (Comms.lua) and the pure view helpers (TalentUI.lua).
-- Run: lua5.1 client-addon/EraTalents/test_inspect.lua   (cwd = repo root)
dofile("client-addon/EraTalents/Comms.lua")
local ET = EraTalents

local G1, G2 = "0x0000000000000A01", "0x0000000000000B02"

-- single chunk
local cache = {}
assert(ET.ParseInspectSync(cache, "ISYNC " .. G1 .. " 0 1 8 18001:3,18002:1") == G1, "returns the guid")
local e = cache[G1]
assert(e.era == 0 and e.managed == true and e.classId == 8, "header parsed")
assert(e.ranks[18001] == 3 and e.ranks[18002] == 1, "ranks parsed")

-- not an ISYNC
assert(ET.ParseInspectSync(cache, "SYNC 0 1 47 18001:3") == nil, "SYNC is not ISYNC")
assert(ET.ParseInspectSync(cache, "GEN a1b2c3d4") == nil, "GEN is not ISYNC")

-- denial: managed=0, no list; another guid's entry untouched
assert(ET.ParseInspectSync(cache, "ISYNC " .. G2 .. " 0 0 0") == G2, "denial parsed")
assert(cache[G2].managed == false and next(cache[G2].ranks) == nil, "denial has no ranks")
assert(cache[G1].ranks[18001] == 3, "entries are per guid")

-- multi-chunk accumulate; seq 1 resets; sentinel-less resets
cache = {}
ET.ParseInspectSync(cache, "ISYNC " .. G1 .. " 1 1 2 1/2 946001:5")
ET.ParseInspectSync(cache, "ISYNC " .. G1 .. " 1 1 2 2/2 946002:2")
assert(cache[G1].ranks[946001] == 5 and cache[G1].ranks[946002] == 2, "chunk 2 accumulates")
ET.ParseInspectSync(cache, "ISYNC " .. G1 .. " 1 1 2 1/1 946003:1")
assert(cache[G1].ranks[946001] == nil and cache[G1].ranks[946003] == 1, "seq 1 resets")
ET.ParseInspectSync(cache, "ISYNC " .. G1 .. " 1 1 2 946004:1")
assert(cache[G1].ranks[946003] == nil and cache[G1].ranks[946004] == 1, "sentinel-less resets")
assert(cache[G1].era == 1 and cache[G1].classId == 2, "TBC paladin header")
print("ParseInspectSync OK")

-- OnAddonMsg: ISYNC goes to ET.inspect.cache + RefreshInspect, never to ParseSync/Refresh
ET.PREFIX = "ERATAL"
ET.state = { ranks = {} }
ET.inspect = { current = G1, cache = {} }
local refreshed, inspected = false, false
ET.Refresh = function() refreshed = true end
ET.RefreshInspect = function() inspected = true end
ET.OnAddonMsg("ERATAL", "ISYNC " .. G1 .. " 0 1 8 18001:3")
assert(inspected and not refreshed, "ISYNC routed to RefreshInspect only")
assert(ET.inspect.cache[G1].ranks[18001] == 3, "stored in ET.inspect.cache")
assert(ET.state.era == nil, "own state untouched by ISYNC")
-- a reply for a guid the frame is not showing (closed / moved on) is dropped, not cached
inspected = false
ET.OnAddonMsg("ERATAL", "ISYNC " .. G2 .. " 0 1 8 18001:3")
assert(ET.inspect.cache[G2] == nil and not inspected, "non-current ISYNC dropped")
ET.Refresh, ET.RefreshInspect = nil, nil
print("ISYNC routing OK")

-- an orphan continuation chunk (no chunk 1 seen) creates nothing; partial flag tracks arrival
cache = {}
ET.ParseInspectSync(cache, "ISYNC " .. G1 .. " 1 1 2 2/2 946002:2")
assert(cache[G1] == nil, "orphan chunk ignored")
ET.ParseInspectSync(cache, "ISYNC " .. G1 .. " 1 1 2 1/2 946001:5")
assert(cache[G1].partial == true, "chunk 1 of 2 is partial")
ET.ParseInspectSync(cache, "ISYNC " .. G1 .. " 1 1 2 2/2 946002:2")
assert(cache[G1].partial == false and cache[G1].ranks[946001] == 5, "complete after chunk 2")
print("chunk edge cases OK")

-- RequestInspect payload
local sent
_G.SendAddonMessage = function(prefix, msg) sent = prefix .. "|" .. msg end
_G.UnitName = function() return "Me" end
ET.RequestInspect(G1)
assert(sent == "ERATAL|INSPECT " .. G1, "INSPECT payload")
print("RequestInspect OK")

-- Pure view helpers (TalentUI.lua must load headless: no WoW API at file scope).
dofile("client-addon/EraTalents/TalentUI.lua")
local tree = { talents = { { id = 1, tab = 1 }, { id = 2, tab = 1 }, { id = 3, tab = 2 }, { id = 4, tab = 3 } } }
local pts = ET.SpecPoints(tree, { [1] = 5, [2] = 3, [3] = 2, [4] = 0 })
assert(pts[1] == 8 and pts[2] == 2 and pts[3] == 0, "per-tab sums")
assert(ET.SpecPoints(tree, nil)[1] == 0, "nil ranks = nothing spent")
assert(ET.PrimaryTab(tree, { [3] = 5, [4] = 5 }, 1) == 2, "tie -> lowest index")
assert(ET.PrimaryTab(tree, {}, 1) == 1, "nothing spent -> fallback")
assert(ET.PrimaryTab(tree, { [4] = 1 }, 1) == 3, "single tree")
print("test_inspect OK")
