local addon = select(2, ...)
local L = {}
addon.L = L

BINDING_NAME_UNIVERSALBAR_LOADBARCONFIG = 'Reload bar configuration'

L.Bars = {
	Bar1 = 'Action Bar 1',
	Bar2 = 'Action Bar 2',
	Bar3 = 'Action Bar 3',
	Bar4 = 'Action Bar 4',
	Bar5 = 'Action Bar 5',
	Bar6 = 'Action Bar 6',
	Bar7 = 'Action Bar 7',
	Bar8 = 'Action Bar 8',
	Bonus1 = 'Druid Cat Form / Rogue Stealth',
	Bonus2 = 'Druid Cat Form Stealth',
	Bonus3 = 'Druid Bear Form',
	Bonus4 = 'Druid Moonkin Form',
	Bonus5 = 'Dragonriding',
}
L.Errors = {
	UnsupportedBar = 'Unsupported bar being set. You can only set bars 1 through 8',
	UnknownEquipmentSet = 'Unknown equipment set name in saved configuration: %s',
	UnknownCommand = 'Unknown command: %s',
}
L.MinimapIcon = {
	Commands = {
		ReloadBars = 'Reload Bars'
	},
	Lines = {
		[1] = 'Universal Bar',
		[2] = 'Left-click to open settings',
		[3] = 'Right-click for quick actions'
	}
}
L.Settings = {
	ShowMinimapButton = 'Show minimap button',
	AutoLoadAtLogin = 'Automatically load at login',
	ClearUnsavedActionSlots = 'Clear slots that are not saved in universal configuration',
	AutosaveSlotChanges = 'Automatically update shared bar configuration when a change is made',
	SettingsHeader = 'General Settings',
	MainBarHeader = 'Action Bars',
	BonusBarHeader = 'Bonus Bars',
	Actions = {
		SaveBars = 'Save Bars',
		LoadBars = 'Load Bars',
		ClearBars = 'Clear Bars',
	},
}

setmetatable(addon.L, {
	__index = function(self, key)
		rawset(self, key, (key or ''))
		return key
	end
})