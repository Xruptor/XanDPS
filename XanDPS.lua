--This mod was inspired by Skada and PicoDPS.  Please give all due credit to the original owners.
--Basically this mod is a very small version of Skada and PicoDPS combined.
--I've tried to simplify it as much as possible but retain only the elements I really wanted to use.
--A very special thank you to zarnivoop for his work on Skada.

local unitpets = {}
local CL_events = {}
local ticktimer = nil
local band = bit.band
local timerLib = LibStub:GetLibrary("LibSimpleTimer-1.0", true)

--MODULES
local dmgReport = LibStub:GetLibrary("XanDPS_Damage", true)
local healReport = LibStub:GetLibrary("XanDPS_Healing", true)

local f = CreateFrame("Frame", "XanDPS", UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

f.timechunk = {}

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
	if not XanDPS_DB.disabled and not f.timechunk.current then
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
	f.timechunk.current = {units = {}, starttime = time(), ntime = 0}

	--Initiate total if empty
	if f.timechunk.total == nil then
		f.timechunk.total = {units = {}, starttime = time(), ntime = 0}
	end

	ticktimer = timerLib:ScheduleRepeatingTimer("Tick", f.ChunkTick, 1)
end

function f:EndChunk()
	--save the previous chunk, in case the user wants to see the data for the last fight
	f.timechunk.current.endtime = time()
	f.timechunk.current.ntime = f.timechunk.current.endtime - f.timechunk.current.starttime
	f:Unit_UpdateTimeActive(f.timechunk.current) --update the time data for units in current chunk
	f.timechunk.previous = f.timechunk.current --save it as previous chunk
		
	--add current chunk to total chunk time
	f.timechunk.total.ntime = f.timechunk.total.ntime + f.timechunk.current.ntime
	
	--update unit data
	f:Unit_UpdateTimeActive(f.timechunk.total)
	f:Unit_TimeReset(f.timechunk.total)
	
	--Reset our timer and current chunk
	f.timechunk.current = nil
	timerLib:CancelTimer("Tick") --cancel the tick timer
end

function f:NewChunk()
	--adds a new chunk to the data stream
	if f.timechunk.current then
		f:EndChunk()
		f:StartChunk()
	end
end

function f:ChunkTick()
	if f.timechunk.current and not InCombatLockdown() and not UnitIsDead("player") and not f:RaidPartyCombat() then
		f:EndChunk()
	end
	--DEBUG
	-- if dmgReport then
		-- local playerDPS = dmgReport:Data_DPS(f.timechunk.total, nil, UnitGUID("player"))
		-- if playerDPS then print("DPS: "..playerDPS) end
	-- end
	-- if healReport then
		-- local playerHPS = healReport:Data_HPS(f.timechunk.total, nil, UnitGUID("player"))
		-- if playerHPS then print("HPS: "..playerHPS) end
		-- local playerTotalHeals = healReport:Data_Totalheals(f.timechunk.total, nil, UnitGUID("player"))
		-- if playerTotalHeals then print("THeals: "..playerTotalHeals) end
	-- end
end

--------------------------------------------
----- UNIT FUNCTIONS
--------------------------------------------

function f:Unit_Fetch(chunk, gid)
	if not chunk then return nil end
	--NOTE: This function simply returns the player but will not create it if it doesn't exsist.
	return chunk.units[gid] or nil
end

function f:Unit_Seek(chunk, gid, pName)
	--NOTE: This function will create the unit if it doesn't exsist, or return the unit if found.
	if not chunk then return nil end
	
	local uChk = chunk.units[gid] or nil

	if not uChk then
		if not pName then return end
		uChk = {gid = gid, class = select(2, UnitClass(pName)), name = pName, nfirst = time(), ntime = 0}
		chunk.units[gid] = uChk
	end
	
	--set our time slots
	if not uChk.nfirst then
		uChk.nfirst = time()
	end
	uChk.nlast = time() --this updates the last time the player had preformed an action (each Unit_Seek use)

	return uChk
end

function f:Unit_UpdateTimeActive(chunk)
	if not chunk then return nil end
	
	--update unit time data
	for k, v in ipairs(chunk.units) do
		if v.nlast then
			v.ntime = v.ntime + (v.nlast - v.nfirst)
		end
	end
end

function f:Unit_TimeActive(chunk, units)
	--NOTE: This function returns the total time the unit has been active
	local totaltime = 0
	
	if chunk and units and units.ntime then
		if units.ntime > 0 then
			totaltime = units.ntime
		end
		
		if not chunk.endtime and units.nfirst then
			totaltime = totaltime + units.nlast - units.nfirst
		end
	end
	
	return totaltime
end

function f:Unit_TimeReset(chunk)
	if not chunk then return nil end
	--NOTE: This function resets the unit time chunks
	
	for k, v in ipairs(chunk.units) do
		v.nfirst = nil
		v.nlast = nil
	end
end

--------------------------------------------
----- PET FUNCTIONS
--------------------------------------------

function f:Pet_Seek(unit_id, pet_id)
	--NOTE: This function will create pet data if not found
	local uGUID = UnitGUID(unit_id)
	local uName = UnitName(unit_id)
	local pGUID = UnitGUID(pet_id)
	
	if pGUID and uGUID and uName and not unitpets[pGUID] then
		unitpets[pGUID] = {gid = uGUID, name = uName}
	end
end

function f:Pet_Fetch(petGUID)
	--NOTE: This function will return the owner id and name of a given pet
	local uPet = unitpets[petGUID]
	if uPet then
		return uPet.gid, uPet.name
	end
	return nil, nil
end

function f:Pet_Parse()
	--NOTE: This function will parse party/raid/player for any given pets and add them if required.
	if GetNumRaidMembers() > 0 then
		for i = 1, GetNumRaidMembers(), 1 do
			if UnitExists("raid"..i.."pet") then
				f:Pet_Seek("raid"..i, "raid"..i.."pet")
			end
		end
	elseif GetNumPartyMembers() > 0 then
		for i = 1, GetNumPartyMembers(), 1 do
			if UnitExists("party"..i.."pet") then
				f:Pet_Seek("party"..i, "party"..i.."pet")
			end
		end
	end
	if UnitExists("pet") then
		f:Pet_Seek("player", "pet")
	end
end

function f:Pet_Reallocate(cl_action)
if cl_action and cl_action.unitName then
	print('pet parse: '..cl_action.unitName)
end
	if cl_action and not UnitIsPlayer(cl_action.unitName) then
		if cl_action.unitFlags and band(cl_action.unitFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
			if band(cl_action.unitFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
				--if guardian is players then update owner
				--Greater Fire Elementals, Amry of the Dead, etc..
				cl_action.unitName = UnitName("player")
				cl_action.unitGID = UnitGUID("player")
				print('Found1: '..cl_action.unitGID.."<>"..cl_action.unitName)
			end
		end
		--find pet and attach real owner
		local uGUID, uName = f:Pet_Fetch(cl_action.unitGID)
		if uGUID and uName then
			cl_action.unitGID = uGUID
			cl_action.unitName = uName
			print('Found2: '..cl_action.unitGID.."<>"..cl_action.unitName.."<Owner>"..uGUID..":"..uName)
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
	if XanDPS_DB and XanDPS_DB.disabled then return end
	
	--NOTE: RAID_FLAGS is used to only parse events only if they are in a raid/party/or player(mine)
	
	local SRC_GOOD = nil
	local DST_GOOD = nil
	local SRC_GOOD_NOPET = nil
	local DST_GOOD_NOPET = nil

	-- Pet summons, guardians (only for raid/party/mine)
	if eventtype == 'SPELL_SUMMON' and band(srcFlags, RAID_FLAGS) ~= 0 then
		--if a pet summons a pet (IE Fire Elemental Totem -> Summons Greater Fire Elemental)
		--check the source to see if its a pet, if it is then just resync it with actual owner.
		if unitpets[srcGUID] then
			--if the source is already a pet then grab the data and associate with owner
			unitpets[dstGUID] = {gid = unitpets[srcGUID].gid, name = unitpets[srcGUID].name}
			print('Pet is source: '..(srcName or 'unknown').." <> "..(unitpets[srcGUID].name or 'unknown'))
		else
			--if it's not a pet summoning (ie. fire elemental totem), then add pet with owner
			unitpets[dstGUID] = {gid = srcGUID, name = srcName}
			print('New Pet: '..(srcName or 'unknown')..":"..(dstGUID or 'unknown'))
		end
	end
	
	if eventtype == 'UNIT_DIED' and unitpets[dstGUID] then
		--keep the pet array clean and small
		unitpets[dstGUID] = nil
		print('pet died: '..dstGUID.." <> "..(dstName or 'unknown'))
	end

	if f.timechunk.current and CL_events[eventtype] then

		for i, module in ipairs(CL_events[eventtype]) do
			local fail = false
			
			if not fail and module.flags.SRC_GOOD_NOPET then
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
			if not fail and module.flags.DST_GOOD_NOPET then
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
			if not fail and module.flags.SRC_GOOD or module.flags.SRC_BAD then
				if SRC_GOOD == nil then
					SRC_GOOD = band(srcFlags, RAID_FLAGS) ~= 0 or (band(srcFlags, PET_FLAGS) ~= 0 and unitpets[srcGUID])
				end
				if module.flags.SRC_GOOD and not SRC_GOOD then
					fail = true
				end
				if module.flags.SRC_BAD and SRC_GOOD then
					fail = true
				end
			end
			if not fail and module.flags.DST_GOOD or module.flags.DST_BAD then
				if DST_GOOD == nil then
					DST_GOOD = band(dstFlags, RAID_FLAGS) ~= 0 or (band(dstFlags, PET_FLAGS) ~= 0 and unitpets[dstGUID])
				end
				if module.flags.DST_GOOD and not DST_GOOD then
					fail = true
				end
				if module.flags.DST_BAD and DST_GOOD then
					fail = true
				end
			end
			
			--pass to our module
			if not fail then
				module.func(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
			end
			
		end
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