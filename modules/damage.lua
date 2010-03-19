--[[----------------------------------------------------------------------------
Name: XanDPS_Damge
Description: A damage module for the XanDPS mod.
Author: Xruptor
Email: private message (PM) me at wowinterface.com
Credits: zarnivoop for his work on Skada
------------------------------------------------------------------------------]]

local module_name = "XanDPS_Damge"
local module, oldminor = LibStub:NewLibrary(module_name, 1)
if not module then return end

-------------------
--REPORT
-------------------

function module:Report(chunk, units)
	--this function returns the collected data
	local totaltime = XanDPS:Unit_TimeActive(chunk, units)
	return units.damage / math.max(1, totaltime)
end

-------------------
--PARSERS
-------------------

local dmg = {}

local function log_data(chunk, dmg)
	if not chunk then return end
	
	--seek the unit (will add it if not available)
	local unitID =  XanDPS:Unit_Seek(chunk, dmg.unitGID, dmg.unitName)
	
	if unitID then
		local amount = dmg.amount or 0

		--add to chunk total
		chunk.damage = (chunk.damage or 0) + amount
		
		--add to unit total
		unitID.damage = (unitID.damage or 0) + amount
	end
end

local function SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcGUID ~= dstGUID then
		local spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...

		dmg.unitGID = srcGUID
		dmg.unitName = srcName
		dmg.unitFlags = srcFlags
		dmg.dstname = dstName
		dmg.amount = samount

		XanDPS:Pet_Reallocate(dmg)
		log_data(XanDPS.timechunk.current, dmg)
		log_data(XanDPS.timechunk.total, dmg)
	end
end

local function SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcGUID ~= dstGUID then
		local samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...
		dmg.unitGID = srcGUID
		dmg.unitName = srcName
		dmg.unitFlags = srcFlags
		dmg.dstname = dstName
		dmg.amount = samount
		
		XanDPS:Pet_Reallocate(dmg)
		log_data(XanDPS.timechunk.current, dmg)
		log_data(XanDPS.timechunk.total, dmg)
	end
end

local function SwingMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcGUID ~= dstGUID then

		dmg.unitGID = srcGUID
		dmg.unitName = srcName
		dmg.unitFlags = srcFlags
		dmg.dstname = dstName
		dmg.amount = 0
		
		XanDPS:Pet_Reallocate(dmg)
		log_data(XanDPS.timechunk.current, dmg)
		log_data(XanDPS.timechunk.total, dmg)
	end
end

local function SpellMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcGUID ~= dstGUID then
		local spellId, spellName, spellSchool, missType, samount = ...
		
		dmg.unitGID = srcGUID
		dmg.unitName = srcName
		dmg.unitFlags = srcFlags
		dmg.dstname = dstName
		dmg.amount = 0
		
		XanDPS:Pet_Reallocate(dmg)
		log_data(XanDPS.timechunk.current, dmg)
		log_data(XanDPS.timechunk.total, dmg)
	end
end

-------------------
--LOAD UP
-------------------

local fd = CreateFrame("Frame", (module_name.."_Frame"), UIParent)
fd:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

function fd:PLAYER_LOGIN()

	XanDPS:Register_CL(SpellDamage, 'DAMAGE_SHIELD', {SRC_GOOD = true, DST_BAD = true})
	XanDPS:Register_CL(SpellDamage, 'SPELL_DAMAGE', {SRC_GOOD = true, DST_BAD = true})
	XanDPS:Register_CL(SpellDamage, 'SPELL_PERIODIC_DAMAGE', {SRC_GOOD = true, DST_BAD = true})
	XanDPS:Register_CL(SpellDamage, 'SPELL_BUILDING_DAMAGE', {SRC_GOOD = true, DST_BAD = true})
	XanDPS:Register_CL(SpellDamage, 'RANGE_DAMAGE', {SRC_GOOD = true, DST_BAD = true})
	
	XanDPS:Register_CL(SwingDamage, 'SWING_DAMAGE', {SRC_GOOD = true, DST_BAD = true})
	XanDPS:Register_CL(SwingMissed, 'SWING_MISSED', {SRC_GOOD = true, DST_BAD = true})
	
	XanDPS:Register_CL(SpellMissed, 'SPELL_MISSED', {SRC_GOOD = true, DST_BAD = true})
	XanDPS:Register_CL(SpellMissed, 'SPELL_PERIODIC_MISSED', {SRC_GOOD = true, DST_BAD = true})
	XanDPS:Register_CL(SpellMissed, 'RANGE_MISSED', {SRC_GOOD = true, DST_BAD = true})
	XanDPS:Register_CL(SpellMissed, 'SPELL_BUILDING_MISSED', {SRC_GOOD = true, DST_BAD = true})
	
	fd:UnregisterEvent("PLAYER_LOGIN")
	fd = nil
end

if IsLoggedIn() then fd:PLAYER_LOGIN() else fd:RegisterEvent("PLAYER_LOGIN") end