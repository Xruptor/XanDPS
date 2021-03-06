﻿
--[[
	XanDPS Localization
--]]

--["english word"] = "translated word",

XanDPS_L = GetLocale() == "zhCN" and {
	--["|cFF99CC33%s|r [v|cFFDF2B2B%s|r] Loaded"] = "|cFF99CC33%s|r [v|cFFDF2B2B%s|r] Loaded",
	--["Player DPS"] = "Player DPS",
	--["Player Damage"] = "Player Damage",
	--["Total Combat DPS"] = "Total Combat DPS",
	--["Total Combat Damage"] = "Total Combat Damage",
	--["Player HPS"] = "Player HPS",
	--["Player Healing"] = "Player Healing",
	--["Player Overhealing"] = "Player Overhealing",
	--["Player OHPS"] = "Player OHPS",
	--["Total Combat HPS"] = "Total Combat HPS",
	--["Total Combat Healing"] = "Total Combat Healing",
	--["Total Combat Overhealing"] = "Total Combat Overhealing",
	--["Total Combat OHPS"] = "Total Combat OHPS",
	--["Do you wish to reset the data?"] = "Do you wish to reset the data?",
	--["Yes"] = "Yes",
	--["No"] = "No",
	--["Combat Session"] = "Combat Session",
	--["Previous"] = "Previous",
	--["Current"] = "Current",
	--["Total"] = "Total",
	--["Data Set"] = "Data Set",
	--["Close"] = "Close",
	--["Raid"] = "Raid",
	--["Party"] = "Party",
	--["Player"] = "Player",
	--["Background Opacity"] = "Background Opacity",
	--["Font Size"] = "Font Size",
	--["Bar Height"] = "Bar Height",
	--["Group"] = "Group",
	--["Settings"] = "Settings",
	--["Hide display in Arena/Battleground"] = "Hide display in Arena/Battleground",
	--["Disable in Arena/Battleground"] = "Disable in Arena/Battleground",
	--["Disable XanDPS"] = "Disable XanDPS",
	--["Strip realm from character name"] = "Strip realm from character name",
	--["Damage"] = "Damage",
	--["Healing"] = "Healing",
} or GetLocale() == "ruRU" and {

} or GetLocale() == "zhTW" and {

} or GetLocale() == "frFR" and {

} or GetLocale() == "koKR" and {

} or GetLocale() == "deDE" and {

} or { }

setmetatable(XanDPS_L, {__index = function(self, key) rawset(self, key, key); return key; end})