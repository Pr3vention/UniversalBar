local addonName = select(1, ...)
UniversalBar = select(2, ...)

local frame = UniversalBar.frame
frame.name = addonName
frame:SetScript("OnShow", function(frame)
	local function newCheckbox(name, label)
		local check = CreateFrame("CheckButton", "UniversalBarCheck" .. name, frame, "InterfaceOptionsCheckButtonTemplate")
		check:SetScript("OnClick", function(self)
			UniversalBarSettings.AutoSetAtLogin = self:GetChecked()
		end)
		check.label = _G[check:GetName() .. "Text"]
		check.label:SetText(label)
		return check
	end
	
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(addonName)
	
	local autoLoadAtLoginCheckbox = newCheckbox('AutoLoadAtLogin', 'Automatically load at login')
	autoLoadAtLoginCheckbox:SetChecked(UniversalBarSettings.AutoLoadAtLogin)
	autoLoadAtLoginCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -3, -16)
	
	local clearUnsavedActionSlots = newCheckbox('ClearUnsavedActionSlots', 'Clear slots that are not saved in universal configuration')
	clearUnsavedActionSlots:SetChecked(UniversalBarSettings.ClearUnsavedActionSlots)
	clearUnsavedActionSlots:SetPoint("TOPLEFT", autoLoadAtLoginCheckbox, "BOTTOMLEFT", 0, 0)
	
	local saveBarConfigButton = CreateFrame("Button", "UniversalBarSaveBarConfigButton", frame, "UIPanelButtonTemplate")
	saveBarConfigButton:SetText('Save action bars')
	saveBarConfigButton:SetWidth(200)
	saveBarConfigButton:SetHeight(24)
	saveBarConfigButton:SetPoint("TOPLEFT", clearUnsavedActionSlots, "BOTTOMLEFT", 17, -16)
	saveBarConfigButton:SetScript("OnClick", function()
		UniversalBar:SaveBarConfig()
	end)
	
	local loadBarConfigButton = CreateFrame("Button", "UniversalBarLoadBarConfigButton", frame, "UIPanelButtonTemplate")
	loadBarConfigButton:SetText('Load action bars')
	loadBarConfigButton:SetWidth(200)
	loadBarConfigButton:SetHeight(24)
	loadBarConfigButton:SetPoint("LEFT", saveBarConfigButton, "RIGHT", 16, 0)
	loadBarConfigButton:SetScript("OnClick", function()
		UniversalBar:LoadBarConfig()
	end)
end)

InterfaceOptions_AddCategory(frame)
