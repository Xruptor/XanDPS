--[[----------------------------------------------------------------------------
Name: XanDPS_Healing
Description: A healing module for the XanDPS mod.
Author: Xruptor
Email: private message (PM) me at wowinterface.com
Credits: Zarnivoop for his work on Skada
------------------------------------------------------------------------------]]

local module_name = "XanDPS_Healing"
local module, oldminor = LibStub:NewLibrary(module_name, 1)
if not module then return end

-------------------
--REPORT
-------------------

function module:Report(chunk, units, uGUID)
	--this function returns the collected data
	
	if uGUID then
		local tmpG = XanDPS:Unit_Fetch(chunk, uGUID)
		if tmpG then
			units = tmpG
		else
			return 0
		end
	end
	
	local totaltime = XanDPS:Unit_TimeActive(chunk, units)
	
	--return HPS
	return units.healing / math.max(1, totaltime)
end

function module:Report_Overheal(chunk, units, uGUID)
	--this function returns the collected data
	
	if uGUID then
		local tmpG = XanDPS:Unit_Fetch(chunk, uGUID)
		if tmpG then
			units = tmpG
		else
			return 0
		end
	end
	
	--return Overhealing
	return units.overhealing
end

-------------------
--PARSERS
-------------------

local heal = {}

local function log_data(chunk, heal)
	if not chunk then return end
	if not heal then return end
	
	--seek the unit (will add unit if not available)
	local uChk =  XanDPS:Unit_Seek(chunk, heal.unitGID, heal.unitName)
	
	if uChk then
		--you need to subtract the overhealing
		local amount = math.max(0, (heal.amount or 0) - (heal.overhealing or 0))

		--add to chunk total
		chunk.healing = (chunk.healing or 0) + amount
		chunk.overhealing = (chunk.overhealing or 0) + (heal.overhealing or 0)
		
		--add to unit total
		uChk.healing = (uChk.healing or 0) + amount
		uChk.overhealing = (uChk.overhealing or 0) + (heal.overhealing or 0)
	end
end

local function SpellHeal(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	local spellId, spellName, spellSchool, samount, soverhealing, absorbed, scritical = ...
	
	heal.unitGID = srcGUID
	heal.unitName = srcName
	heal.unitFlags = srcFlags
	heal.dstname = dstName
	heal.amount = samount
	heal.overhealing = soverhealing

	XanDPS:Pet_Reallocate(heal)
	log_data(XanDPS.timechunk.current, heal)
	log_data(XanDPS.timechunk.total, heal)
	
end

-------------------
--LOAD UP
-------------------

local fd = CreateFrame("Frame", (module_name.."_Frame"), UIParent)
fd:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

function fd:PLAYER_LOGIN()

	XanDPS:Register_CL(SpellHeal, 'SPELL_HEAL', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellHeal, 'SPELL_PERIODIC_HEAL', {SRC_GOOD = true})
	
	fd:UnregisterEvent("PLAYER_LOGIN")
	fd = nil
end

if IsLoggedIn() then fd:PLAYER_LOGIN() else fd:RegisterEvent("PLAYER_LOGIN") end