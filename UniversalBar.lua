local addonName, UniversalBar = ...

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

function UniversalBar:SetBarID(barID, state)
	assert(barID >= 1 and barID <= 8, 'Invalid bar being set. You can only set bars 1 through 8')
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
			for i = startIndex, endIndex do
				local actionType, id, subType = GetActionInfo(i)
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
				end
				if actionType then
					UniversalBarSettings.BarConfig[barID][slot] = {
						type = actionType,
						id = id
					}
				else 
					UniversalBarSettings.BarConfig[barID][slot] = nil
				end
				slot = slot + 1
			end
		end
	end
end
function UniversalBar:LoadBarConfig()
	for barID, state in pairs(UniversalBarSettings.Bars or {}) do
		if state then
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

local keys = 0
local eventFrame = CreateFrame("FRAME", "UniversalBarEventFrame", UIParent)
local loginEvents = {
	ADDON_LOADED = true,
	PLAYER_ENTERING_WORLD = true,
	SPELLS_CHANGED = true,
	PET_JOURNAL_LIST_UPDATE = true,
}
for event in pairs(loginEvents) do
	eventFrame:RegisterEvent(event)
	keys = keys + 1
end
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if loginEvents[event] then
		if event == 'ADDON_LOADED' and addonName == select(1,...) then
			if not UniversalBarSettings then
				UniversalBarSettings = {
					AutoLoadAtLogin = true,
					ClearUnsavedActionSlots = true,
					Bars = {},
					BarConfig = {},
				}
			end
		end
		loginEvents[event] = nil
		keys = keys - 1
		eventFrame:UnregisterEvent(event)
		
		if keys <= 0 then
			if UniversalBarSettings.AutoLoadAtLogin then
				UniversalBar:LoadBarConfig()
			end
		end
	end
end)
UniversalBar.frame = eventFrame