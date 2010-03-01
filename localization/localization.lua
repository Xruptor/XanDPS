--[[
	XanDPS Localization
--]]

if ( GetLocale() == "zhCN" ) then

	XANDPS_LOADED = "|cFF99CC33XanDPS|r [v|cFFDF2B2B%s|r] Loaded: /xandps"
	XANDPS_DPS = "%.1f dps"
	XANDPS_DPS2 = "0.0 dps"
	XANDPS_FRAME_RESET = "XanDPS: Frame position has been reset!"
	XANDPS_OPT1 = "/xandps reset - resets the frame position"
	XANDPS_OPT2 = "/xandps bg - toggles the background on/off"
	XANDPS_OPT1_VALUE = "reset"
	XANDPS_OPT2_VALUE = "bg"
	XANDPS_ERRORU = "XanDPS: Error parsing unit %q"
	XANDPS_TT1 = "Player"
	XANDPS_TT2 = "Damage"
	XANDPS_TT3 = "Total %"
	XANDPS_TT4 = "DPS"
	XANDPS_TTH1 = "|cFF66FF00Right-Click to access the menu.|r"
	XANDPS_TTH2 = "|cFFFF9933Hold SHIFT to drag the frame.|r"
	XANDPS_MNU1 = "Reset Data"
	XANDPS_MNU2 = "Report to /SAY"
	XANDPS_MNU3 = "Report to /WHISPER"
	XANDPS_MNU4 = "Report to /PARTY"
	XANDPS_MNU5 = "Report to /RAID"
	XANDPS_MNU6 = "Report to /GUILD"
	XANDPS_MNU7 = "Resync Data"
	XANDPS_MNU8 = "Close"
	XANDPS_WHISPER1 = "Target player name:"
	XANDPS_WHISPER2 = "Yes"
	XANDPS_WHISPER3 = "No"
	XANDPS_WHISPER4 = "XanDPS: You didn't enter a target player name."
	XANDPS_REPORT1 = "XanDPS Report:"
	XANDPS_BG1 = "XanDPS: Background Shown"
	XANDPS_BG2 = "XanDPS: Background Hidden"
	XANDPS_RESYNC = "XanDPS: Resync in process... (it may take a few seconds)"
	XANDPS_RESYNC2 = "XanDPS: Resync failed! (your not in a group)"
	
	--ONLY USE A 2 LETTER ABBREVIATION FOR THE CLASSES!
	XANDPS_CLASSNUM = {}
	XANDPS_CLASSNUM[1] = "WR" --WARRIOR
	XANDPS_CLASSNUM[2] = "MG" --MAGE
	XANDPS_CLASSNUM[3] = "RO" --ROGUE
	XANDPS_CLASSNUM[4] = "DR" --DRUID
	XANDPS_CLASSNUM[5] = "HN" --HUNTER
	XANDPS_CLASSNUM[6] = "SH" --SHAMAN
	XANDPS_CLASSNUM[7] = "PR" --PRIEST
	XANDPS_CLASSNUM[8] = "WL" --WARLOCK
	XANDPS_CLASSNUM[9] = "PD" --PALADIN
	XANDPS_CLASSNUM[10] = "DK" --DEATHKNIGHT

elseif ( GetLocale() == "ruRU" )  then

	XANDPS_LOADED = "|cFF99CC33XanDPS|r [v|cFFDF2B2B%s|r] Loaded: /xandps"
	XANDPS_DPS = "%.1f dps"
	XANDPS_DPS2 = "0.0 dps"
	XANDPS_FRAME_RESET = "XanDPS: Frame position has been reset!"
	XANDPS_OPT1 = "/xandps reset - resets the frame position"
	XANDPS_OPT2 = "/xandps bg - toggles the background on/off"
	XANDPS_OPT1_VALUE = "reset"
	XANDPS_OPT2_VALUE = "bg"
	XANDPS_ERRORU = "XanDPS: Error parsing unit %q"
	XANDPS_TT1 = "Player"
	XANDPS_TT2 = "Damage"
	XANDPS_TT3 = "Total %"
	XANDPS_TT4 = "DPS"
	XANDPS_TTH1 = "|cFF66FF00Right-Click to access the menu.|r"
	XANDPS_TTH2 = "|cFFFF9933Hold SHIFT to drag the frame.|r"
	XANDPS_MNU1 = "Reset Data"
	XANDPS_MNU2 = "Report to /SAY"
	XANDPS_MNU3 = "Report to /WHISPER"
	XANDPS_MNU4 = "Report to /PARTY"
	XANDPS_MNU5 = "Report to /RAID"
	XANDPS_MNU6 = "Report to /GUILD"
	XANDPS_MNU7 = "Resync Data"
	XANDPS_MNU8 = "Close"
	XANDPS_WHISPER1 = "Target player name:"
	XANDPS_WHISPER2 = "Yes"
	XANDPS_WHISPER3 = "No"
	XANDPS_WHISPER4 = "XanDPS: You didn't enter a target player name."
	XANDPS_REPORT1 = "XanDPS Report:"
	XANDPS_BG1 = "XanDPS: Background Shown"
	XANDPS_BG2 = "XanDPS: Background Hidden"
	XANDPS_RESYNC = "XanDPS: Resync in process... (it may take a few seconds)"
	XANDPS_RESYNC2 = "XanDPS: Resync failed! (your not in a group)"
	
	--ONLY USE A 2 LETTER ABBREVIATION FOR THE CLASSES!
	XANDPS_CLASSNUM = {}
	XANDPS_CLASSNUM[1] = "WR" --WARRIOR
	XANDPS_CLASSNUM[2] = "MG" --MAGE
	XANDPS_CLASSNUM[3] = "RO" --ROGUE
	XANDPS_CLASSNUM[4] = "DR" --DRUID
	XANDPS_CLASSNUM[5] = "HN" --HUNTER
	XANDPS_CLASSNUM[6] = "SH" --SHAMAN
	XANDPS_CLASSNUM[7] = "PR" --PRIEST
	XANDPS_CLASSNUM[8] = "WL" --WARLOCK
	XANDPS_CLASSNUM[9] = "PD" --PALADIN
	XANDPS_CLASSNUM[10] = "DK" --DEATHKNIGHT
	
elseif ( GetLocale() == "zhTW" ) then

	XANDPS_LOADED = "|cFF99CC33XanDPS|r [v|cFFDF2B2B%s|r] Loaded: /xandps"
	XANDPS_DPS = "%.1f dps"
	XANDPS_DPS2 = "0.0 dps"
	XANDPS_FRAME_RESET = "XanDPS: Frame position has been reset!"
	XANDPS_OPT1 = "/xandps reset - resets the frame position"
	XANDPS_OPT2 = "/xandps bg - toggles the background on/off"
	XANDPS_OPT1_VALUE = "reset"
	XANDPS_OPT2_VALUE = "bg"
	XANDPS_ERRORU = "XanDPS: Error parsing unit %q"
	XANDPS_TT1 = "Player"
	XANDPS_TT2 = "Damage"
	XANDPS_TT3 = "Total %"
	XANDPS_TT4 = "DPS"
	XANDPS_TTH1 = "|cFF66FF00Right-Click to access the menu.|r"
	XANDPS_TTH2 = "|cFFFF9933Hold SHIFT to drag the frame.|r"
	XANDPS_MNU1 = "Reset Data"
	XANDPS_MNU2 = "Report to /SAY"
	XANDPS_MNU3 = "Report to /WHISPER"
	XANDPS_MNU4 = "Report to /PARTY"
	XANDPS_MNU5 = "Report to /RAID"
	XANDPS_MNU6 = "Report to /GUILD"
	XANDPS_MNU7 = "Resync Data"
	XANDPS_MNU8 = "Close"
	XANDPS_WHISPER1 = "Target player name:"
	XANDPS_WHISPER2 = "Yes"
	XANDPS_WHISPER3 = "No"
	XANDPS_WHISPER4 = "XanDPS: You didn't enter a target player name."
	XANDPS_REPORT1 = "XanDPS Report:"
	XANDPS_BG1 = "XanDPS: Background Shown"
	XANDPS_BG2 = "XanDPS: Background Hidden"
	XANDPS_RESYNC = "XanDPS: Resync in process... (it may take a few seconds)"
	XANDPS_RESYNC2 = "XanDPS: Resync failed! (your not in a group)"
	
	--ONLY USE A 2 LETTER ABBREVIATION FOR THE CLASSES!
	XANDPS_CLASSNUM = {}
	XANDPS_CLASSNUM[1] = "WR" --WARRIOR
	XANDPS_CLASSNUM[2] = "MG" --MAGE
	XANDPS_CLASSNUM[3] = "RO" --ROGUE
	XANDPS_CLASSNUM[4] = "DR" --DRUID
	XANDPS_CLASSNUM[5] = "HN" --HUNTER
	XANDPS_CLASSNUM[6] = "SH" --SHAMAN
	XANDPS_CLASSNUM[7] = "PR" --PRIEST
	XANDPS_CLASSNUM[8] = "WL" --WARLOCK
	XANDPS_CLASSNUM[9] = "PD" --PALADIN
	XANDPS_CLASSNUM[10] = "DK" --DEATHKNIGHT
	
elseif ( GetLocale() == "frFR" ) then

	XANDPS_LOADED = "|cFF99CC33XanDPS|r [v|cFFDF2B2B%s|r] Loaded: /xandps"
	XANDPS_DPS = "%.1f dps"
	XANDPS_DPS2 = "0.0 dps"
	XANDPS_FRAME_RESET = "XanDPS: Frame position has been reset!"
	XANDPS_OPT1 = "/xandps reset - resets the frame position"
	XANDPS_OPT2 = "/xandps bg - toggles the background on/off"
	XANDPS_OPT1_VALUE = "reset"
	XANDPS_OPT2_VALUE = "bg"
	XANDPS_ERRORU = "XanDPS: Error parsing unit %q"
	XANDPS_TT1 = "Player"
	XANDPS_TT2 = "Damage"
	XANDPS_TT3 = "Total %"
	XANDPS_TT4 = "DPS"
	XANDPS_TTH1 = "|cFF66FF00Right-Click to access the menu.|r"
	XANDPS_TTH2 = "|cFFFF9933Hold SHIFT to drag the frame.|r"
	XANDPS_MNU1 = "Reset Data"
	XANDPS_MNU2 = "Report to /SAY"
	XANDPS_MNU3 = "Report to /WHISPER"
	XANDPS_MNU4 = "Report to /PARTY"
	XANDPS_MNU5 = "Report to /RAID"
	XANDPS_MNU6 = "Report to /GUILD"
	XANDPS_MNU7 = "Resync Data"
	XANDPS_MNU8 = "Close"
	XANDPS_WHISPER1 = "Target player name:"
	XANDPS_WHISPER2 = "Yes"
	XANDPS_WHISPER3 = "No"
	XANDPS_WHISPER4 = "XanDPS: You didn't enter a target player name."
	XANDPS_REPORT1 = "XanDPS Report:"
	XANDPS_BG1 = "XanDPS: Background Shown"
	XANDPS_BG2 = "XanDPS: Background Hidden"
	XANDPS_RESYNC = "XanDPS: Resync in process... (it may take a few seconds)"
	XANDPS_RESYNC2 = "XanDPS: Resync failed! (your not in a group)"
	
	--ONLY USE A 2 LETTER ABBREVIATION FOR THE CLASSES!
	XANDPS_CLASSNUM = {}
	XANDPS_CLASSNUM[1] = "WR" --WARRIOR
	XANDPS_CLASSNUM[2] = "MG" --MAGE
	XANDPS_CLASSNUM[3] = "RO" --ROGUE
	XANDPS_CLASSNUM[4] = "DR" --DRUID
	XANDPS_CLASSNUM[5] = "HN" --HUNTER
	XANDPS_CLASSNUM[6] = "SH" --SHAMAN
	XANDPS_CLASSNUM[7] = "PR" --PRIEST
	XANDPS_CLASSNUM[8] = "WL" --WARLOCK
	XANDPS_CLASSNUM[9] = "PD" --PALADIN
	XANDPS_CLASSNUM[10] = "DK" --DEATHKNIGHT

else

	XANDPS_LOADED = "|cFF99CC33XanDPS|r [v|cFFDF2B2B%s|r] Loaded: /xandps"
	XANDPS_DPS = "%.1f dps"
	XANDPS_DPS2 = "0.0 dps"
	XANDPS_FRAME_RESET = "XanDPS: Frame position has been reset!"
	XANDPS_OPT1 = "/xandps reset - resets the frame position"
	XANDPS_OPT2 = "/xandps bg - toggles the background on/off"
	XANDPS_OPT1_VALUE = "reset"
	XANDPS_OPT2_VALUE = "bg"
	XANDPS_ERRORU = "XanDPS: Error parsing unit %q"
	XANDPS_TT1 = "Player"
	XANDPS_TT2 = "Damage"
	XANDPS_TT3 = "Total %"
	XANDPS_TT4 = "DPS"
	XANDPS_TTH1 = "|cFF66FF00Right-Click to access the menu.|r"
	XANDPS_TTH2 = "|cFFFF9933Hold SHIFT to drag the frame.|r"
	XANDPS_MNU1 = "Reset Data"
	XANDPS_MNU2 = "Report to /SAY"
	XANDPS_MNU3 = "Report to /WHISPER"
	XANDPS_MNU4 = "Report to /PARTY"
	XANDPS_MNU5 = "Report to /RAID"
	XANDPS_MNU6 = "Report to /GUILD"
	XANDPS_MNU7 = "Resync Data"
	XANDPS_MNU8 = "Close"
	XANDPS_WHISPER1 = "Target player name:"
	XANDPS_WHISPER2 = "Yes"
	XANDPS_WHISPER3 = "No"
	XANDPS_WHISPER4 = "XanDPS: You didn't enter a target player name."
	XANDPS_REPORT1 = "XanDPS Report:"
	XANDPS_BG1 = "XanDPS: Background Shown"
	XANDPS_BG2 = "XanDPS: Background Hidden"
	XANDPS_RESYNC = "XanDPS: Resync in process... (it may take a few seconds)"
	XANDPS_RESYNC2 = "XanDPS: Resync failed! (your not in a group)"
	
	--ONLY USE A 2 LETTER ABBREVIATION FOR THE CLASSES!
	XANDPS_CLASSNUM = {}
	XANDPS_CLASSNUM[1] = "WR" --WARRIOR
	XANDPS_CLASSNUM[2] = "MG" --MAGE
	XANDPS_CLASSNUM[3] = "RO" --ROGUE
	XANDPS_CLASSNUM[4] = "DR" --DRUID
	XANDPS_CLASSNUM[5] = "HN" --HUNTER
	XANDPS_CLASSNUM[6] = "SH" --SHAMAN
	XANDPS_CLASSNUM[7] = "PR" --PRIEST
	XANDPS_CLASSNUM[8] = "WL" --WARLOCK
	XANDPS_CLASSNUM[9] = "PD" --PALADIN
	XANDPS_CLASSNUM[10] = "DK" --DEATHKNIGHT
end