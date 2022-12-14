local addonName, UniversalBar = ...
local blizzardSettings = Settings
local L = UniversalBar.L

-- blizzard's slotIDs are all over the place... no clue why
local ActionBarSlotRanges = {
	[1] = { 1, 12 },
	[2] = { 61, 72 },
	[3] = { 49, 60 },
	[4] = { 25, 36 },
	[5] = { 37, 48 },
	[6] = { 145, 156 },
	[7] = { 157, 168 },
	[8] = { 169, 180 }
}

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
		local spellID = select(2, C_MountJournal.GetMountInfoByID(id))
		actionType = 'mount'
		id = spellID
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
	assert(barID >= 1 and barID <= 8, L.Errors.UnsupportedBar)
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
local function SetBarVisibility(barID, state)
	if barID > 1 then
		blizzardSettings.SetValue('PROXY_SHOW_ACTIONBAR_' .. barID, state)
	end
end
function UniversalBar:LoadBarConfig()
	for barID, state in pairs(UniversalBarSettings.Bars or {}) do
		if state then
			SetBarVisibility(barID, state)
			local needPlaceAction = true
			local startIndex, endIndex = unpack(ActionBarSlotRanges[barID])
			for slot = 1, endIndex-startIndex+1 do
				if UniversalBarSettings.BarConfig[barID][slot] then
					local actionType = UniversalBarSettings.BarConfig[barID][slot].type
					local actionID = UniversalBarSettings.BarConfig[barID][slot].id
					needPlaceAction = false
					if actionType == 'spell' then
						PickupSpell(actionID)
						needPlaceAction = true
					elseif actionType == 'mount' then
						for i=1, C_MountJournal.GetNumMounts() do
							local spellID = select(2, C_MountJournal.GetDisplayedMountInfo(i))
							if spellID == actionID then
								C_MountJournal.Pickup(i)
								needPlaceAction = true
								break;
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
					end
					if needPlaceAction then
						PlaceAction(startIndex+slot-1)
						ClearCursor()
					end
				else
					if UniversalBarSettings.ClearUnsavedActionSlots then
						PickupAction(startIndex+slot-1)
						ClearCursor()
					end
				end
			end
		end
	end
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