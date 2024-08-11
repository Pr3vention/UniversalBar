local addonName, UniversalBar = ...
local L = UniversalBar.L

-- local references
local C_ToyBox, C_MountJournal, C_PetJournal, C_EquipmentSet, GetActionInfo, GetMacroInfo, C_Spell =
	  C_ToyBox, C_MountJournal, C_PetJournal, C_EquipmentSet, GetActionInfo, GetMacroInfo, C_Spell
	  
local SUMMON_FAVORITE_MOUNT = 268435455

-- blizzard's slotIDs are all over the place... no clue why.
-- Blizzard shouldn't change these without reengineering the entire actionbar system, so we're safe to hardcode them
local ActionBarSlotRanges = {
	[1] = { 1, 12 },
	['1p2'] = { 13, 24 }, -- action bar page 2
	[4] = { 25, 36 },
	[5] = { 37, 48 },
	[3] = { 49, 60 },
	[2] = { 61, 72 },
	['b1'] = { 73, 84 }, -- druid cat, rogue stealth
	['b2'] = { 85, 96 }, -- druid cat stealth
	['b3'] = { 97, 108 }, -- druid bear
	['b4'] = { 109, 120 }, -- druid moonkin
	['b5'] = { 121, 132 }, -- dragonriding (possibly vehicles in general)
	['b6'] = { 133, 144 }, -- doesn't appear to be used but is still allocated slots. Could be for special scenarios
	[6] = { 145, 156 },
	[7] = { 157, 168 },
	[8] = { 169, 180 }
}

local function PrintMessage(msg)
	print(string.format('%s: %s', addonName, msg))
end
local function GetBarInfoForSlot(slotID)
	for barID, range in pairs(ActionBarSlotRanges) do
		local startIndex, endIndex = unpack(range)
		if startIndex <= slotID and slotID <= endIndex then
			return barID, slotID - startIndex + 1
		end
	end
end
local function UpdateSlotConfig(barID, slot, slotID)
	local actionType, id, subType = GetActionInfo(slotID)
	if actionType == 'summonmount' then
		actionType = 'mount'
		if id == SUMMON_FAVORITE_MOUNT then
			id = 0
		else
			local spellID = select(2, C_MountJournal.GetMountInfoByID(id))
			id = spellID
		end
	elseif actionType == 'item' then
		if C_ToyBox.GetToyInfo(id) then
			actionType = 'toy'
		else
			actionType = 'item'
		end
	elseif actionType == 'macro' then
		-- if the macro's ID is queried and nothing is returned, it's more likely a bad query than a bad macro.
		-- this should never happen, but better to ignore it in saved config than to have it throw an error later
		local name = GetMacroInfo(id)
		if name then
			id = name
		else
			actionType = nil
			id = nil
		end
	end
	if actionType then
		UniversalBarSettings.BarConfig[barID][slot] = {
			type = actionType,
			id = id
		}
	else 
		UniversalBarSettings.BarConfig[barID][slot] = nil
	end
end

function UniversalBar:SetBarID(barID, state)
	if not ActionBarSlotRanges[barID] then
		PrintMessage(L.Errors.UnsupportedBar)
		return
	end
	UniversalBarSettings.Bars[barID] = state
end
function UniversalBar:SaveBarConfig()
	if not UniversalBarSettings.BarConfig then
		UniversalBarSettings.BarConfig = {}
	end
	
	for barID, state in pairs(UniversalBarSettings.Bars or {}) do
		if state then
			UniversalBarSettings.BarConfig[barID] = {}
			local slot = 1
			local startIndex, endIndex = unpack(ActionBarSlotRanges[barID])
			for slotID = startIndex, endIndex do
				UpdateSlotConfig(barID, slot, slotID)
				slot = slot + 1
			end
		end
	end
end
local function SetBarVisibility(bars)
	if barID == 1 then MainMenuBar:SetShown(state) end
	local bar2, bar3, bar4, bar5, bar6, bar7, bar8 = GetActionBarToggles()
	SetActionBarToggles(
		bars[2] or bar2, 
		bars[3] or bar3, 
		bars[4] or bar4, 
		bars[5] or bar5, 
		bars[6] or bar6, 
		bars[7] or bar7, 
		bars[8] or bar8
	)
	if bar2 then MultiBarBottomLeft:SetShown(bars[2] or bar2) end
	if bar3 then MultiBarBottomRight:SetShown(bars[3] or bar3) end
	if bar4 then MultiBarRight:SetShown(bars[4] or bar4) end
	if bar5 then MultiBarLeft:SetShown(bars[5] or bar5) end
	if bar6 then MultiBar5:SetShown(bars[6] or bar6) end
	if bar7 then MultiBar6:SetShown(bars[7] or bar6) end
	if bar8 then MultiBar7:SetShown(bars[8] or bar6) end
end
function UniversalBar:LoadBarConfig()
	SetBarVisibility(UniversalBarSettings.Bars or {})
	local Barloader = coroutine.create(function()
		for barID, state in pairs(UniversalBarSettings.Bars or {}) do
			if state then
				local needPlaceAction = true
				local startIndex, endIndex = unpack(ActionBarSlotRanges[barID])
				for slot = 1, endIndex-startIndex+1 do
					local currentActionType, currentActionID = GetActionInfo(startIndex+slot-1)
					if UniversalBarSettings.BarConfig[barID][slot] then
						local actionType, actionID = UniversalBarSettings.BarConfig[barID][slot].type, UniversalBarSettings.BarConfig[barID][slot].id
						-- if the current slot's type and identifier are the same as what's already on the bar, we don't have to bother processing it
						if currentActionType ~= actionType or currentActionID ~= actionID then
							needPlaceAction = false
							if actionType == 'spell' then
								C_Spell.PickupSpell(actionID)
								if not GetCursorInfo() then 
									-- some abilities that override a base spell get placed on the action bar as the base spell even though it isn't available in the spellbook anymore
									-- when this happens, we should be able to get the base spell and pick that one up.
									C_Spell.PickupSpell(FindBaseSpellByID(actionID))
								end
								needPlaceAction = true
							elseif actionType == 'mount' then
								if actionID == 0 then
									C_MountJournal.Pickup(0)
									needPlaceAction = true
								else
									for i=1, C_MountJournal.GetNumMounts() do
										local spellID = select(2, C_MountJournal.GetDisplayedMountInfo(i))
										if spellID == actionID then
											C_MountJournal.Pickup(i)
											needPlaceAction = true
											break
										end
									end
								end
							elseif actionType == 'item' or actionType == 'toy' then
								local item = Item:CreateFromItemID(actionID)
								if not item:IsItemEmpty() then
									local itemSlot = (startIndex+slot-1)
									item:ContinueOnItemLoad(function()
										if actionType == 'toy' then
											C_ToyBox.PickupToyBoxItem(actionID)
										else
											PickupItem(actionID)
										end
										PlaceAction(itemSlot)
										ClearCursor()
									end)
								end
							elseif actionType == 'summonpet' then
								C_PetJournal.PickupPet(actionID)
								needPlaceAction = true
							elseif actionType == 'macro' then
								PickupMacro(actionID)
								needPlaceAction = true
							elseif actionType == 'equipmentset' then
								local setID = C_EquipmentSet.GetEquipmentSetID(actionID)
								if setID then
									C_EquipmentSet.PickupEquipmentSet(setID)
									needPlaceAction = true
								else
									PrintMessage(string.format(UniversalBar.L.Errors.UnknownEquipmentSet, actionID))
									needPlaceAction = false
								end
							end
							if needPlaceAction then
								PlaceAction(startIndex+slot-1)
								ClearCursor()
							end
						end
					else
						if UniversalBarSettings.ClearUnsavedActionSlots and currentActionType then
							PickupAction(startIndex+slot-1)
							ClearCursor()
						end
					end
					coroutine.yield()
				end
			end
		end
		BarsLoading = false
	end)
	BarsLoading = true
	local ticker 
	ticker = C_Timer.NewTicker(0, function()
		coroutine.resume(Barloader)
		if not BarsLoading then
			ticker:Cancel()
		end
	end)
end
function UniversalBar:SetActionSlotChangeEvent(state)
	if state then
		UniversalBar.eventFrame:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
	else
		UniversalBar.eventFrame:UnregisterEvent('ACTIONBAR_SLOT_CHANGED')
	end
end
function UniversalBar:UpdateConfigForSlot(slotID)
	if not slotID then return end
	local barID, slot = GetBarInfoForSlot(slotID)
	if barID and UniversalBarSettings.Bars[barID] then
		if not UniversalBarSettings.BarConfig[barID] then 
			UniversalBarSettings.BarConfig[barID] = {}
		end
		UpdateSlotConfig(barID, slot, slotID)
	end
end

local keys = 0
local eventFrame = CreateFrame("FRAME")
-- loginEvents are specific to the timing of when the action bar should get loaded
local loginEvents = {
	ADDON_LOADED = true,
	PLAYER_ENTERING_WORLD = true,
	SPELLS_CHANGED = true,
	PET_JOURNAL_LIST_UPDATE = true,
	TOYS_UPDATED = true
}
function eventFrame:EventHandler(event, ...)
	if loginEvents[event] then
		if event == 'ADDON_LOADED' and addonName == select(1,...) then
			UniversalBar:InitializeSettings()
		end
		loginEvents[event] = nil
		keys = keys - 1
		eventFrame:UnregisterEvent(event)
		
		if keys <= 0 then
			if UniversalBarSettings.AutoLoadAtLogin then
				UniversalBar:LoadBarConfig()
			end
		end
		
		UniversalBar:SetActionSlotChangeEvent(UniversalBarSettings.AutosaveSlotChanges)
	elseif event == 'ACTIONBAR_SLOT_CHANGED' and UniversalBarSettings.AutosaveSlotChanges then
		UniversalBar:UpdateConfigForSlot(...)
	end
end
eventFrame:SetScript("OnEvent", eventFrame.EventHandler)
UniversalBar.eventFrame = eventFrame
for event in pairs(loginEvents) do
	eventFrame:RegisterEvent(event)
	keys = keys + 1
end