--This mod was inspired by Skada and PicoDPS.  Please give all due credit to the original owners.
--Basically this mod is a very small version of Skada and PicoDPS combined.
--I've tried to simplify it as much as possible but retain only the elements I really wanted to use.
--A very special thank you to zarnivoop for his work on Skada.

local playerGUID = 0
local timechunk = {}
local unitpets = {}
local CL_events = {}
local ticktimer = nil
local band = bit.band

local f = CreateFrame("Frame","XanDPS",UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local timerLib = LibStub:GetLibrary("LibSimpleTimer-1.0", true)

--------------------------------------------
-----EVENTS
--------------------------------------------

function f:PLAYER_LOGIN()
	
	--Database creation
	if not XanDPS_DB then XanDPS_DB = {} end
	if XanDPS_DB.bgShown == nil then XanDPS_DB.bgShown = 1 end
	if XanDPS_DB.disabled == nil then XanDPS_DB.disabled = false end
	
	f:RegisterEvent("PLAYER_REGEN_DISABLED")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("PARTY_MEMBERS_CHANGED")
	f:RegisterEvent("RAID_ROSTER_UPDATE")
	f:RegisterEvent("UNIT_PET")
	f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	local ver = GetAddOnMetadata("XanDPS","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format(XANDPS_LOADED, ver or "1.0"))
	
	f:UnregisterEvent("PLAYER_LOGIN")
	f.PLAYER_LOGIN = nil
end

function f:PLAYER_REGEN_DISABLED()
	--initiates the creation of chunked time data
	if not XanDPS_DB.disabled and not timechunk.current then
		f:StartChunk()
	end
end

function f:PLAYER_ENTERING_WORLD()
	--Pet Check
	f:Pet_Parse()
end

function f:PARTY_MEMBERS_CHANGED()
	--Pet Check
	f:Pet_Parse()
end

function f:RAID_ROSTER_UPDATE()
	--Pet Check
	f:Pet_Parse()
end

function f:UNIT_PET()
	--Pet Check
	f:Pet_Parse()
end

--------------------------------------------
-----TIMER (TICK) FUNCTIONS
--------------------------------------------

function f:StartChunk()
	timechunk.current = {units = {}, starttime = time(), ntime = 0}

	--Initiate total if empty
	if timechunk.total == nil then
		timechunk.total = {units = {}, starttime = time(), ntime = 0}
	end

	ticktimer = timerLib:ScheduleRepeatingTimer("Tick", f.ChunkTick, 1)
end

function f:EndChunk()
	--save the previous chunk, in case the user wants to see the data for the last fight
	timechunk.current.endtime = time()
	timechunk.current.ntime = timechunk.current.endtime - timechunk.current.starttime
	f:Unit_UpdateTimeActive(timechunk.current) --update the time data for units in current chunk
	timechunk.previous = timechunk.current --save it as previous chunk
		
	--add current chunk to total chunk time
	timechunk.total.ntime = timechunk.total.ntime + timechunk.current.ntime
	
	--update unit data
	f:Unit_UpdateTimeActive(timechunk.total)
	f:Unit_TimeReset(timechunk.total)
	
	--Reset our timer and current chunk
	timechunk.current = nil
	timerLib:CancelTimer("Tick") --cancel the tick timer
end

function f:NewChunk()
	--adds a new chunk to the data stream
	if timechunk.current then
		f:EndChunk()
		f:StartChunk()
	end
end

function f:ChunkTick()
	if timechunk.current and not InCombatLockdown() and not UnitIsDead("player") and not f:RaidPartyCombat() then
		f:EndChunk()
	end
end

--------------------------------------------
----- UNIT FUNCTIONS
--------------------------------------------

function f:Unit_Fetch(chunk, gid)
	--NOTE: This function simply returns the player but will not create it if it doesn't exsist.
	for k, v in ipairs(chunk.units) do
		if v.gid == gid then
			return v
		end
	end
	return nil
end

function f:Unit_Seek(chunk, gid, pName)
	--NOTE: This function will create the unit if it doesn't exsist, or return the unit if found.
	local unitID = nil

	--return unit if found
	for k, v in ipairs(chunk.units) do
		if v.gid == gid then
			unitID = v
		end
	end
	
	if not unitID then
		if not pName then return end
		unitID = {gid = gid, class = select(2, UnitClass(pName)), name = pName, nfirst = time(), ntime = 0}
		table.insert(chunk.units, unitID)
	end
	
	--set our time slots
	if not unitID.nfirst then
		unitID.nfirst = time()
	end
	unitID.nlast = time() --this updates the last time the player had preformed an action (each Unit_Seek use)

	return unitID
end

function f:Unit_UpdateTimeActive(chunk)
	--update unit time data
	for k, v in ipairs(chunk.units) do
		if v.nlast then
			v.ntime = v.ntime + (v.nlast - v.nfirst)
		end
	end
end

function f:Unit_TimeActive(chunk, units)
	--return unit time data
	local maxtime = 0
	
	if units.ntime > 0 then
		maxtime = units.ntime
	end
	
	if not chunk.endtime and units.nfirst then
		maxtime = maxtime + units.nlast - units.nfirst
	end
	return maxtime
end

function f:Unit_TimeReset(chunk)
	for k, v in ipairs(chunk.units) do
		v.nfirst = nil
		v.nlast = nil
	end
end

--------------------------------------------
----- PET FUNCTIONS
--------------------------------------------

function f:Pet_Seek(unit_id, pet_id)
	--NOTE: This function will return pet if found, if not then it returns new pet data if available
	local uGUID = UnitGUID(unit_id)
	local uName = UnitName(unit_id)
	local pGUID = UnitGUID(pet_id)
	local petUnit = nil
	
	if pGUID and uGUID and uName and not unitpets[pGUID] then
		petUnit = {gid = uGUID, name = uName}
	elseif pGUID and unitpets[pGUID] then
		petUnit = unitpets[pGUID]
	end
	
	return pGUID, petUnit
end

function f:Pet_Fetch(petGUID, petName)
	--NOTE: This function will return the owner id and name of a given pet
	if not UnitIsPlayer(petName) then
		local pet = unitpets[petGUID]
		if pet then
			return pet.gid, pet.name
		end
	end
end

function f:Pet_Parse()
	--NOTE: This function will parse party/raid/player for any given pets and add them if required.
	--NOTE: This function also updates the pet array to keep it fresh and prevent it from growing too large.
	local tmpArray = {}
	
	if GetNumRaidMembers() > 0 then
		for i = 1, GetNumRaidMembers(), 1 do
			if UnitExists("raid"..i.."pet") then
				local pGUID, petUnit = f:Pet_Seek("raid"..i, "raid"..i.."pet")
				if pGUID and petUnit then
					tmpArray[pGUID] = petUnit
				end
			end
		end
	elseif GetNumPartyMembers() > 0 then
		for i = 1, GetNumPartyMembers(), 1 do
			if UnitExists("party"..i.."pet") then
				local pGUID, petUnit = f:Pet_Seek("party"..i, "party"..i.."pet")
				if pGUID and petUnit then
					tmpArray[pGUID] = petUnit
				end
			end
		end
	end
	if UnitExists("pet") then
		local pGUID, petUnit = f:Pet_Seek("player", "pet")
		if pGUID and petUnit then
			tmpArray[pGUID] = petUnit
		end
	end
	
	--update the pet array
	unitpets = tmpArray
end

function f:Pet_Reallocate(cl_action)
	if cl_action and not UnitIsPlayer(cl_action.unitName) then
		if cl_action.unitFlags and band(cl_action.unitFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
			if band(cl_action.unitFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
				--this is for guardian pets, reserved same name as owner
				--this is done to force the guardian pet data to be parsed
				--Greater Fire Elementals, Amry of the Dead, etc..
				cl_action.unitName = UnitName("player")
				cl_action.unitGID = UnitGUID("player")
			else
				--ignore pet parsing (below) by using the unitname
				--this will rarely occur, however it usually occurs due to incorrectly parsed pets
				--so to save us trouble lets just ignore it that one time (not that it makes a huge deal)
				cl_action.unitGID = cl_action.unitName
			end
		end
		--find pet if not a guardian and adjust the data to proper owner
		local uGUID, uName = f:Pet_Fetch(cl_action.unitGID, cl_action.unitName)
		if uGUID and uName then
			cl_action.unitName = uName
			cl_action.unitGID = uGUID
		end
	end
end

--------------------------------------------
----- COMBAT LOG FUNCTIONS
----- NOTE: FULL CREDIT TO (zarnivoop) for SKADA
--------------------------------------------

local PET_FLAGS = COMBATLOG_OBJECT_TYPE_PET + COMBATLOG_OBJECT_TYPE_GUARDIAN
local RAID_FLAGS = COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_RAID

function f:Register_CL(func, event, flags)
	if not CL_events[event] then
		CL_events[event] = {}
	end
	tinsert(CL_events[event], {["func"] = func, ["flags"] = flags})
end

function f:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if XanDPS_DB and XanDPS_DB.disabled return end
	
	local SRC_GOOD = nil
	local DST_GOOD = nil
	local SRC_GOOD_NOPET = nil
	local DST_GOOD_NOPET = nil
	
	if timechunk.current and CL_events[eventtype] then
		for i, mod in ipairs(CL_events[eventtype]) do
			local fail = false
			
			if not fail and mod.flags.SRC_GOOD_NOPET then
				if SRC_GOOD_NOPET == nil then
					SRC_GOOD_NOPET = band(srcFlags, RAID_FLAGS) ~= 0 and band(srcFlags, PET_FLAGS) == 0
					if SRC_GOOD_NOPET then
						SRC_GOOD = true
					end
				end
				if not SRC_GOOD_NOPET then
					fail = true
				end
			end
			if not fail and mod.flags.DST_GOOD_NOPET then
				if DST_GOOD_NOPET == nil then
					DST_GOOD_NOPET = band(dstFlags, RAID_FLAGS) ~= 0 and band(dstFlags, PET_FLAGS) == 0
					if DST_GOOD_NOPET then
						DST_GOOD = true
					end
				end
				if not DST_GOOD_NOPET then
					fail = true
				end
			end
			if not fail and mod.flags.SRC_GOOD or mod.flags.SRC_BAD then
				if SRC_GOOD == nil then
					SRC_GOOD = band(srcFlags, RAID_FLAGS) ~= 0 or (band(srcFlags, PET_FLAGS) ~= 0 and unitpets[srcGUID])
				end
				if mod.flags.SRC_GOOD and not SRC_GOOD then
					fail = true
				end
				if mod.flags.SRC_BAD and SRC_GOOD then
					fail = true
				end
			end
			if not fail and mod.flags.DST_GOOD or mod.flags.DST_BAD then
				if DST_GOOD_ == nil then
					DST_GOOD = band(dstFlags, RAID_FLAGS) ~= 0 or (band(dstFlags, PET_FLAGS) ~= 0 and unitpets[dstGUID])
				end
				if mod.flags.DST_GOOD and not DST_GOOD then
					fail = true
				end
				if mod.flags.DST_BAD and DST_GOOD then
					fail = true
				end
			end
			
			--pass to our module
			if not fail then
				mod.func(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
			end
		end
	end
	
	-- Pet summons, guardians
	if eventtype == 'SPELL_SUMMON' and band(srcFlags, RAID_FLAGS) ~= 0 then
		unitpets[dstGUID] = {gid = srcGUID, name = srcName}
	end

end

--------------------------------------------
----- MISC FUNCTIONS
--------------------------------------------

function f:GetChunkTime(chunk)
	if not chunk then return 0 end
	if chunk.ntime then
		return chunk.ntime
	else
		return (time() - chunk.starttime)
	end
end

function f:RaidPartyCombat()
	if GetNumRaidMembers() > 0 then
		for i = 1, GetNumRaidMembers(), 1 do
			if UnitExists("raid"..i) and UnitAffectingCombat("raid"..i) then
				return true
			end
		end
	elseif GetNumPartyMembers() > 0 then
		for i = 1, GetNumPartyMembers(), 1 do
			if UnitExists("party"..i) and UnitAffectingCombat("party"..i) then
				return true
			end
		end
	end
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end