-- Era talents in the stock Inspect frame (read-only). When the inspected character's talent set is
-- era-managed (server says so in ISYNC), a read-only tree view is overlaid on InspectTalentFrame and
-- the stock WotLK tree is suppressed; otherwise the stock view is left completely alone.
--
-- Trigger: post-hooks on InspectFrame_Show / InspectFrame_UnitChanged -- the stock paths that point
-- the Inspect FRAME at a unit. NOT INSPECT_TALENT_READY: other addons' background NotifyInspect
-- (Grid2's LibTalentQuery inspects party members) fire it too and would spam INSPECT requests.
EraTalents = EraTalents or {}
local ET = EraTalents

-- Stock children the overlay replaces. The scroll frame (talent buttons + branches) and points bar
-- are never re-shown by Blizzard code, so Hide/Show is safe (OnShow guard below as a backstop). The
-- three tabs ARE re-Show()n by InspectTalentFrame_UpdateTabs on every update, so they are suppressed
-- with alpha + mouse instead (same reasoning as Hook.lua's pet-only spec tabs).
local STOCK_HIDE = { "InspectTalentFrameScrollFrame", "InspectTalentFramePointsBar" }
local STOCK_TABS = { "InspectTalentFrameTab1", "InspectTalentFrameTab2", "InspectTalentFrameTab3" }

local suppressed = false   -- stock children are only ever touched while this is true (and once to restore)

local function SetStockSuppressed(on)
  if on == suppressed then return end
  suppressed = on
  for _, n in ipairs(STOCK_HIDE) do
    local fr = _G[n]
    if fr then if on then fr:Hide() else fr:Show() end end
  end
  for _, n in ipairs(STOCK_TABS) do
    local t = _G[n]
    if t then t:SetAlpha(on and 0 or 1); t:EnableMouse(not on) end
  end
end

local function EnsureView()
  if not ET.inspectView then
    ET.inspectView = ET.NewTreeView({ name = "EraInspectTalentFrame", parent = InspectTalentFrame,
                                      chrome = false, tabStyle = "top", readOnly = true, defaultTab = 1 })
  end
  return ET.inspectView
end

-- Show the era overlay iff the Talents tab is up and the CURRENT target's cached ISYNC is managed
-- and has a tree; otherwise hide it and hand the tab back to Blizzard. Called on every ISYNC, on
-- target changes, and on InspectTalentFrame show/hide.
function ET.RefreshInspect()
  if not InspectTalentFrame then return end
  local guid = ET.inspect.current
  local e = guid and ET.inspect.cache[guid]
  local byClass = e and e.managed and EraTalentsData and EraTalentsData[e.era]
  local tree = byClass and byClass[e.classId]
  if tree and InspectTalentFrame:IsShown() then
    local v = EnsureView()
    if v.guid ~= guid or v.pickedPartial then    -- new target (or reply still arriving): primary tree
      v.guid = guid
      v.activeTab = ET.PrimaryTab(tree, e.ranks, 1)
      v.pickedPartial = e.partial
    end
    SetStockSuppressed(true)
    v.frame:Show()
    ET.RenderView(v, { era = e.era, ranks = e.ranks, availPts = 0 }, e.classId)
  else
    if ET.inspectView then ET.inspectView.frame:Hide() end
    SetStockSuppressed(false)
  end
end

local function OnInspectTarget()
  if not (InspectFrame and InspectFrame:IsShown()) then return end   -- CanInspect refused: no frame
  local unit = InspectFrame.unit
  local guid = unit and UnitGUID(unit)
  ET.inspect.current = guid
  if guid and not ET.inspect.cache[guid] then ET.RequestInspect(guid) end
  ET.RefreshInspect()
end

local function AttachInspect()
  if ET._inspectHooked or not InspectFrame or not InspectTalentFrame then return end
  ET._inspectHooked = true
  hooksecurefunc("InspectFrame_Show", OnInspectTarget)
  hooksecurefunc("InspectFrame_UnitChanged", OnInspectTarget)
  -- InspectFrame_Show hides the frame before re-showing it, so every fresh inspect re-requests.
  InspectFrame:HookScript("OnHide", function()
    ET.inspect.current = nil
    wipe(ET.inspect.cache)
    if ET.inspectView then ET.inspectView.guid = nil end   -- reopening = a fresh inspect: primary tree again
    ET.RefreshInspect()
  end)
  InspectTalentFrame:HookScript("OnShow", function() ET.RefreshInspect() end)
  InspectTalentFrame:HookScript("OnHide", function() ET.RefreshInspect() end)
  for _, n in ipairs(STOCK_HIDE) do
    local fr = _G[n]
    if fr then fr:HookScript("OnShow", function(self) if suppressed then self:Hide() end end) end
  end
end

function ET.InitInspect()
  if ET._inspectInit then return end
  ET._inspectInit = true
  -- Blizzard_InspectUI is load-on-demand (InspectUnit -> UIParentLoadAddOn): attach now if it is
  -- already loaded, else when it loads.
  if IsAddOnLoaded("Blizzard_InspectUI") then AttachInspect() end
  local w = CreateFrame("Frame")
  w:RegisterEvent("ADDON_LOADED")
  w:SetScript("OnEvent", function(_, _, name)
    if name == "Blizzard_InspectUI" then AttachInspect() end
  end)
end
