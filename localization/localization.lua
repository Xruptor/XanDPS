﻿
--[[
	XanDPS Localization
--]]

--["english word"] = "translated word",

XanDPS_L = GetLocale() == "zhCN" and {
	--["|cFF99CC33%s|r [v|cFFDF2B2B%s|r] Loaded"] = "|cFF99CC33%s|r [v|cFFDF2B2B%s|r] Loaded",
	--["Player DPS"] = "Player DPS",
	--["Player Damage"] = "Player Damage",
	--["Total DPS"] = "Total DPS",
	--["Total Damage"] = "Total Damage",
	--["Player HPS"] = "Player HPS",
	--["Player Healing"] = "Player Healing",
	--["Player Overhealing"] = "Player Overhealing",
	--["Player OHPS"] = "Player OHPS",
	--["Total HPS"] = "Total HPS",
	--["Total Healing"] = "Total Healing",
	--["Total Overhealing"] = "Total Overhealing",
	--["Total OHPS"] = "Total OHPS",
	--["Do you wish to reset the data?"] = "Do you wish to reset the data?",
	--["Yes"] = "Yes",
	--["No"] = "No"]",
	--["Combat Session"] = "Combat Session"]",
	--["Previous"] = "Previous"]",
	--["Current"] = "Current"]",
	--["Total"] = "Total"]",
	--["Data Type"] = "Data Type"]",
	--["Close"] = "Close"]",
	--["Raid"] = "Raid"]",
	--["Party"] = "Party"]",
	--["Player"] = "Player"]",
} or GetLocale() == "ruRU" and {

} or GetLocale() == "zhTW" and {

} or GetLocale() == "frFR" and {

} or GetLocale() == "koKR" and {

} or GetLocale() == "deDE" and {

} or { }

setmetatable(XanDPS_L, {__index = function(self, key) rawset(self, key, key); return key; end})