--[[----------------------------------------------------------------------------
Name: XanDPS_Healing
Description: A healing module for the XanDPS mod.
Author: Xruptor
Email: private message (PM) me at wowinterface.com
Credits: Zarnivoop for his work on Skada
------------------------------------------------------------------------------]]

local module_name = "XanDPS_Healing"

-------------------
--DATA
-------------------

local function UnitHPS(chunk, units, uGUID)
	--this function returns the collected data and returns it as heals per second (effective heals)
	if uGUID and not units then
		local tmpG = XanDPS:Unit_Fetch(chunk, uGUID)
		if tmpG then
			units = tmpG
		else
			return 0
		end
	end
	
	local totaltime = XanDPS:Unit_TimeActive(chunk, units)

	--return HPS
	if units then
		--we want unit HPS
		return ceil((units.healing or 0) / math.max(1, totaltime))
	else
		--we want chunk HPS
		return ceil((chunk.healing or 0) / math.max(1, XanDPS:GetChunkTimeActive(chunk)))
	end
end

local function ChunkHPS(chunk, units, uGUID)
	return UnitHPS(chunk, nil, nil)
end

local function UnitOverheal(chunk, units, uGUID)
	--this function returns the collected data for overhealing
	if uGUID and not units then
		local tmpG = XanDPS:Unit_Fetch(chunk, uGUID)
		if tmpG then
			units = tmpG
		else
			return 0
		end
	end
	
	--return overhealing
	if units then
		--we want unit overhealing
		return units.overhealing or 0
	else
		--we want chunk overhealing
		return chunk.overhealing or 0
	end
end

local function ChunkOverheal(chunk, units, uGUID)
	return UnitOverheal(chunk, nil, nil)
end

local function UnitOHPS(chunk, units, uGUID)
	--this function returns the collected data for overhealing per second OHPS
	if uGUID and not units then
		local tmpG = XanDPS:Unit_Fetch(chunk, uGUID)
		if tmpG then
			units = tmpG
		else
			return 0
		end
	end
	
	--show overhealing per second OHPS
	local totaltime = XanDPS:Unit_TimeActive(chunk, units)
	
	if units then
		--we want unit overhealing
		return ceil((units.overhealing or 0) / math.max(1, totaltime))
	else
		--we want chunk overhealing
		return ceil((chunk.overhealing or 0) / math.max(1, XanDPS:GetChunkTimeActive(chunk)))
	end
end

local function ChunkOHPS(chunk, units, uGUID)
	return UnitOHPS(chunk, nil, nil)
end

local function UnitTotal(chunk, units, uGUID)
	--this function returns the collected data for total heals
	if uGUID and not units then
		local tmpG = XanDPS:Unit_Fetch(chunk, uGUID)
		if tmpG then
			units = tmpG
		else
			return 0
		end
	end
	
	--return total heals
	if units then
		--we want unit total healing
		return (units.healing or 0) + (units.overhealing or 0)
	else
		--we want chunk total healing
		return (chunk.healing or 0) + (chunk.overhealing or 0)
	end
end

local function ChunkTotal(chunk, units, uGUID)
	return UnitTotal(chunk, nil, nil)
end

-------------------
--PARSERS
-------------------

local heal = {}

local function log_data(chunk, heal)
	if not chunk then return end
	if not heal then return end
	
	--seek the unit (will add unit if not available)
	local uChk =  XanDPS:Unit_Check(chunk, heal.unitGUID, heal.unitName)
	
	if uChk then
		--you need to subtract the overhealing
		local amount = math.max(0, heal.amount - heal.overhealing)

		--add to chunk total
		chunk.healing = (chunk.healing or 0) + amount
		chunk.overhealing = (chunk.overhealing or 0) + heal.overhealing
		
		--add to unit total
		uChk.healing = (uChk.healing or 0) + amount
		uChk.overhealing = (uChk.overhealing or 0) + heal.overhealing
	end
end

local function SpellHeal(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	local spellId, spellName, spellSchool, samount, soverhealing, absorbed, scritical = ...
	
	heal.unitGUID = srcGUID
	heal.unitName = srcName
	heal.unitFlags = srcFlags
	heal.dstname = dstName
	heal.amount = samount or 0
	heal.overhealing = soverhealing or 0

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
	
	XanDPS_Display:Register_Mode(module_name, "Player HPS", UnitHPS, { 0, 148/255, 0 }, true)
	XanDPS_Display:Register_Mode(module_name, "Player Healing", UnitTotal, { 0, 148/255, 0 }, true)
	XanDPS_Display:Register_Mode(module_name, "Player Overhealing", UnitOverheal, { 2/255, 165/255, 104/255 }, true)
	XanDPS_Display:Register_Mode(module_name, "Player OHPS", UnitOHPS, { 2/255, 165/255, 104/255 }, true)
	
	XanDPS_Display:Register_Mode(module_name, "Total HPS", ChunkHPS, { 115/255, 124/255, 161/255 }, false)
	XanDPS_Display:Register_Mode(module_name, "Total Healing", ChunkTotal, { 115/255, 124/255, 161/255 }, false)
	XanDPS_Display:Register_Mode(module_name, "Total Overhealing", ChunkOverheal, { 115/255, 124/255, 161/255 }, false)
	XanDPS_Display:Register_Mode(module_name, "Total OHPS", ChunkOHPS, { 115/255, 124/255, 161/255 }, false)
	
	fd:UnregisterEvent("PLAYER_LOGIN")
	fd = nil
end

if IsLoggedIn() then fd:PLAYER_LOGIN() else fd:RegisterEvent("PLAYER_LOGIN") end