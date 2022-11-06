local addonName = select(1, ...)
UniversalBar = select(2, ...)

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

function UniversalBar:SetBarID(barID)
	assert(barID >= 1 and barID <= 8, 'Invalid bar selected. You can only select bars 1 through 8')
	UniversalBarSettings.BarID = barID
end
function UniversalBar:SaveBarConfig()
	if not UniversalBarSettings.BarConfig then
		UniversalBarSettings.BarConfig = {}
	end
	
	local slot = 1
	local startIndex, endIndex = unpack(ActionBarSlotRanges[UniversalBarSettings.BarID])
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
			UniversalBarSettings.BarConfig[slot] = {
				type = actionType,
				id = id
			}
		else 
			UniversalBarSettings.BarConfig[slot] = nil
		end
		slot = slot + 1
	end 
end
function UniversalBar:LoadBarConfig()
	assert(UniversalBarSettings.BarID, 'Universal bar has not been set yet.')
	assert(UniversalBarSettings.BarConfig, 'no bar config has been set')
	
	local needPlaceAction = true
	local startIndex, endIndex = unpack(ActionBarSlotRanges[UniversalBarSettings.BarID])
	for slot = 1, endIndex-startIndex+1 do
		if UniversalBarSettings.BarConfig[slot] then
			local actionType = UniversalBarSettings.BarConfig[slot].type
			local actionID = UniversalBarSettings.BarConfig[slot].id
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
			PickupAction(startIndex+slot-1)
			ClearCursor()
		end
	end
end

local eventFrame = CreateFrame("FRAME", "UniversalBarEventFrame", UIParent)
eventFrame.events = {}
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == 'ADDON_LOADED' and addonName == select(1,...) then
		if not UniversalBarSettings then
			UniversalBarSettings = {}
		end
		
		if UniversalBarSettings.AutoSetAtLogin then
			UniversalBar:LoadBarConfig()
		end
		
		eventFrame:UnregisterEvent('ADDON_LOADED')
	end
end)
UniversalBar.frame = eventFrame