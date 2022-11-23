local addonName, UniversalBar = ...
local L = UniversalBar.L

local frame = CreateFrame("FRAME")
frame.name = addonName

local defaultOptions = {
	AutoLoadAtLogin = true,
	ClearUnsavedActionSlots = true,
	AutosaveSlotChanges = false,
	Bars = {},
	BarConfig = {},
}

function UniversalBar:InitializeSettings()
	UniversalBarSettings = UniversalBarSettings or defaultOptions

	local function newCheckbox(name, label, onclick)
		local check = CreateFrame("CheckButton", "UniversalBarCheck" .. name, frame, "InterfaceOptionsCheckButtonTemplate")
		if onclick then 
			check:SetScript("OnClick", onclick)
		end
		check.label = _G[check:GetName() .. "Text"]
		check.label:SetText(label)
		return check
	end

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(addonName)

	local autoLoadAtLoginCheckbox = newCheckbox('AutoLoadAtLogin', L.Settings.AutoLoadAtLogin, 
		function(self) UniversalBarSettings.AutoLoadAtLogin = self:GetChecked() end
	)
	autoLoadAtLoginCheckbox:SetChecked(UniversalBarSettings.AutoLoadAtLogin)
	autoLoadAtLoginCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -3, -16)

	local clearUnsavedActionSlots = newCheckbox('ClearUnsavedActionSlots', L.Settings.ClearUnsavedActionSlots, 
		function(self) UniversalBarSettings.ClearUnsavedActionSlots = self:GetChecked() end
	)
	clearUnsavedActionSlots:SetChecked(UniversalBarSettings.ClearUnsavedActionSlots)
	clearUnsavedActionSlots:SetPoint("TOPLEFT", autoLoadAtLoginCheckbox, "BOTTOMLEFT", 0, 0)

	local AutosaveSlotChangesCheckbox = newCheckbox('AutosaveSlotChanges', L.Settings.AutosaveSlotChanges, 
		function(self)
			UniversalBarSettings.AutosaveSlotChanges = self:GetChecked()
			UniversalBar:SetActionSlotChangeEvent(UniversalBarSettings.AutosaveSlotChanges)
		end
	)
	AutosaveSlotChangesCheckbox:SetChecked(UniversalBarSettings.AutosaveSlotChanges)
	AutosaveSlotChangesCheckbox:SetPoint("TOPLEFT", clearUnsavedActionSlots, "BOTTOMLEFT", 0, 0)

	local unibar1 = newCheckbox('unibar1', L.Bars.Bar1, 
		function(self) UniversalBar:SetBarID(1, self:GetChecked()) end
	)
	unibar1:SetChecked(UniversalBarSettings.Bars[1])
	unibar1:SetPoint("TOPLEFT", AutosaveSlotChangesCheckbox, "BOTTOMLEFT", 0, -16)

	local unibar2 = newCheckbox('unibar2', L.Bars.Bar2, 
		function(self) UniversalBar:SetBarID(2, self:GetChecked()) end
	)
	unibar2:SetChecked(UniversalBarSettings.Bars[2])
	unibar2:SetPoint("TOPLEFT", unibar1, "BOTTOMLEFT", 0, 0)

	local unibar3 = newCheckbox('unibar3', L.Bars.Bar3, 
		function(self) UniversalBar:SetBarID(3, self:GetChecked()) end
	)
	unibar3:SetChecked(UniversalBarSettings.Bars[3])
	unibar3:SetPoint("TOPLEFT", unibar2, "BOTTOMLEFT", 0, 0)

	local unibar4 = newCheckbox('unibar4', L.Bars.Bar4, 
		function(self) UniversalBar:SetBarID(4, self:GetChecked()) end
	)
	unibar4:SetChecked(UniversalBarSettings.Bars[4])
	unibar4:SetPoint("TOPLEFT", unibar3, "BOTTOMLEFT", 0, 0)

	local unibar5 = newCheckbox('unibar5', L.Bars.Bar5, 
		function(self) UniversalBar:SetBarID(5, self:GetChecked()) end
	)
	unibar5:SetChecked(UniversalBarSettings.Bars[5])
	unibar5:SetPoint("LEFT", unibar1.label, "RIGHT", 16, 0)

	local unibar6 = newCheckbox('unibar6', L.Bars.Bar6, 
		function(self) UniversalBar:SetBarID(6, self:GetChecked()) end
	)
	unibar6:SetChecked(UniversalBarSettings.Bars[6])
	unibar6:SetPoint("TOPLEFT", unibar5, "BOTTOMLEFT", 0, 0)

	local unibar7 = newCheckbox('unibar7', L.Bars.Bar7, 
		function(self) UniversalBar:SetBarID(7, self:GetChecked()) end
	)
	unibar7:SetChecked(UniversalBarSettings.Bars[7])
	unibar7:SetPoint("TOPLEFT", unibar6, "BOTTOMLEFT", 0, 0)

	local unibar8 = newCheckbox('unibar8', L.Bars.Bar8, 
		function(self) UniversalBar:SetBarID(8, self:GetChecked()) end
	)
	unibar8:SetChecked(UniversalBarSettings.Bars[8])
	unibar8:SetPoint("TOPLEFT", unibar7, "BOTTOMLEFT", 0, 0)

	local saveBarConfigButton = CreateFrame("Button", "UniversalBarSaveBarConfigButton", frame, "UIPanelButtonTemplate")
	saveBarConfigButton:SetText(L.Settings.Actions.SaveBars)
	saveBarConfigButton:SetWidth(140)
	saveBarConfigButton:SetHeight(24)
	saveBarConfigButton:SetPoint("TOPLEFT", unibar4, "BOTTOMLEFT", 3, -16)
	saveBarConfigButton:SetScript("OnClick", function()
		UniversalBar:SaveBarConfig()
	end)

	local loadBarConfigButton = CreateFrame("Button", "UniversalBarLoadBarConfigButton", frame, "UIPanelButtonTemplate")
	loadBarConfigButton:SetText(L.Settings.Actions.LoadBars)
	loadBarConfigButton:SetWidth(140)
	loadBarConfigButton:SetHeight(24)
	loadBarConfigButton:SetPoint("LEFT", saveBarConfigButton, "RIGHT", 16, 0)
	loadBarConfigButton:SetScript("OnClick", function()
		UniversalBar:LoadBarConfig()
	end)

	local clearBarConfigButton = CreateFrame("Button", "UniversalBarLoadBarConfigButton", frame, "UIPanelButtonTemplate")
	clearBarConfigButton:SetText(L.Settings.Actions.ClearBars)
	clearBarConfigButton:SetWidth(140)
	clearBarConfigButton:SetHeight(24)
	clearBarConfigButton:SetPoint("LEFT", loadBarConfigButton, "RIGHT", 16, 0)
	clearBarConfigButton:SetScript("OnClick", function()
		UniversalBarSettings.BarConfig = {}
		for i=1,8 do
			_G['UniversalBarCheckunibar' .. i]:SetChecked(false)
			UniversalBarSettings.Bars[i] = false
		end
	end)
	
	InterfaceOptions_AddCategory(frame)
end