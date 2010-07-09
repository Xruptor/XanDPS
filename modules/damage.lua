--[[----------------------------------------------------------------------------
Name: XanDPS_Damage
Description: A damage module for the XanDPS mod.
Author: Xruptor
Email: private message (PM) me at wowinterface.com
Credits: Zarnivoop for his work on Skada
------------------------------------------------------------------------------]]

local module_name = "XanDPS_Damage"

-------------------
--DATA
-------------------

local function UnitDPS(chunk, units, uGUID)
	--this function returns the collected data for DPS
	if uGUID and not units then
		local tmpG = XanDPS:Unit_Fetch(chunk, uGUID)
		if tmpG then
			units = tmpG
		else
			return 0
		end
	end

	local totaltime = XanDPS:Unit_TimeActive(chunk, units)

	--return DPS
	if units then
		--we want unit DPS
		return ceil((units.damage or 0) / math.max(1, totaltime))
	else
		--we want chunk DPS
		return ceil((chunk.damage or 0) / math.max(1, XanDPS:GetChunkTimeActive(chunk)))
	end
end

local function ChunkDPS(chunk, units, uGUID)
	return UnitDPS(chunk, nil, nil)
end

local function UnitTotal(chunk, units, uGUID)
	--this function returns the collected data for total damage
	if uGUID and not units then
		local tmpG = XanDPS:Unit_Fetch(chunk, uGUID)
		if tmpG then
			units = tmpG
		else
			return 0
		end
	end

	--return DPS
	if units then
		--we want unit total damage
		return units.damage or 0
	else
		--we want chunk total damage
		return chunk.damage or 0
	end
end

local function ChunkTotal(chunk, units, uGUID)
	return UnitTotal(chunk, nil, nil)
end

-------------------
--PARSERS
-------------------

local dmg = {}

local function log_data(chunk, dmg)
	if not chunk then return end
	if not dmg then return end
	
	--seek the unit (will add unit if not available)
	local uChk =  XanDPS:Unit_Check(chunk, dmg.unitGUID, dmg.unitName)
	
	if uChk then
		local amount = dmg.amount or 0

		--add to chunk total
		chunk.damage = (chunk.damage or 0) + amount
		
		--add to unit total
		uChk.damage = (uChk.damage or 0) + amount
	end
end

local function SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcGUID ~= dstGUID then
		local spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...

		dmg.unitGUID = srcGUID
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
		
		dmg.unitGUID = srcGUID
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

		dmg.unitGUID = srcGUID
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
		
		dmg.unitGUID = srcGUID
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
	XanDPS:Register_CL(SpellDamage, 'DAMAGE_SHIELD', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellDamage, 'DAMAGE_SPLIT', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellDamage, 'SPELL_DAMAGE', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellDamage, 'SPELL_PERIODIC_DAMAGE', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellDamage, 'SPELL_BUILDING_DAMAGE', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellDamage, 'RANGE_DAMAGE', {SRC_GOOD = true})
	
	XanDPS:Register_CL(SwingDamage, 'SWING_DAMAGE', {SRC_GOOD = true})
	XanDPS:Register_CL(SwingMissed, 'SWING_MISSED', {SRC_GOOD = true})
	
	XanDPS:Register_CL(SpellMissed, 'SPELL_MISSED', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellMissed, 'SPELL_PERIODIC_MISSED', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellMissed, 'RANGE_MISSED', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellMissed, 'SPELL_BUILDING_MISSED', {SRC_GOOD = true})
	XanDPS:Register_CL(SpellMissed, 'DAMAGE_SHIELD_MISSED', {SRC_GOOD = true})
	
	XanDPS_Display:Register_Mode("Damage", "Player DPS", UnitDPS, { 255/255, 51/255, 51/255 }, true)
	XanDPS_Display:Register_Mode("Damage", "Player Damage", UnitTotal, { 255/255, 51/255, 51/255 }, true)
	XanDPS_Display:Register_Mode("Damage", "Total Combat DPS", ChunkDPS, { 115/255, 124/255, 161/255 }, false)
	XanDPS_Display:Register_Mode("Damage", "Total Combat Damage", ChunkTotal, { 115/255, 124/255, 161/255 }, false)
	
	fd:UnregisterEvent("PLAYER_LOGIN")
	fd = nil
end

if IsLoggedIn() then fd:PLAYER_LOGIN() else fd:RegisterEvent("PLAYER_LOGIN") end
