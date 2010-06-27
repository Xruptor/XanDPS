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
} or GetLocale() == "ruRU" and {

} or GetLocale() == "zhTW" and {

} or GetLocale() == "frFR" and {

} or GetLocale() == "koKR" and {

} or GetLocale() == "deDE" and {

} or { }

setmetatable(XanDPS_L, {__index = function(self, key) rawset(self, key, key); return key; end})