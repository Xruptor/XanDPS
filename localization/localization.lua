
--[[
	XanDPS Localization
--]]

XanDPS_L = GetLocale() == "zhCN" and {
	--["|cFF99CC33%s|r [v|cFFDF2B2B%s|r] Loaded"] = "|cFF99CC33%s|r [v|cFFDF2B2B%s|r] Loaded",
} or GetLocale() == "ruRU" and {

} or GetLocale() == "zhTW" and {

} or GetLocale() == "frFR" and {

} or GetLocale() == "koKR" and {

} or GetLocale() == "deDE" and {

} or { }

setmetatable(XanDPS_L, {__index = function(self, key) rawset(self, key, key); return key; end})



	-- XanDPS_Display:Register_Mode("Player DPS", module.UnitDPS)
	-- XanDPS_Display:Register_Mode("Player Damage", module.UnitTotal)
	-- XanDPS_Display:Register_Mode("Total DPS", module.ChunkDPS)
	-- XanDPS_Display:Register_Mode("Total Damage", module.ChunkTotal)

	-- XanDPS_Display:Register_Mode("Player HPS", module.UnitHPS)
	-- XanDPS_Display:Register_Mode("Player Overhealing", module.UnitOverheal)
	-- XanDPS_Display:Register_Mode("Player OHPS", module.UnitOHPS)
	-- XanDPS_Display:Register_Mode("Player Healing", module.UnitTotal)
	
	-- XanDPS_Display:Register_Mode("Total HPS", module.ChunkHPS)
	-- XanDPS_Display:Register_Mode("Total Overhealing", module.ChunkOverheal)
	-- XanDPS_Display:Register_Mode("Total OHPS", module.ChunkOHPS)
	-- XanDPS_Display:Register_Mode("Total Healing", module.ChunkTotal)