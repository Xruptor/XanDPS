--[[
	XanDPS
	This mod was inspired by Skada and PicoDPS. Please give credit where appropriate.
	I wanted a very simple DPS meter without all the excessive stuff a lot of the others had.
	Basically, I wanted to minimize the amount of stuff used in terms of parsing and GUI.
--]]

local L = XanDPS_L
local unitpets = {}
local CL_events = {}
local band = bit.band
local isInsideInstance = false
local instanceNameStr = "none"
local playerGhost = false
local lastInstanceType = "none"
local bgDisabled = false

local PET_FLAGS = COMBATLOG_OBJECT_TYPE_PET + COMBATLOG_OBJECT_TYPE_GUARDIAN
local GROUP_FLAGS = COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_RAID

local f = CreateFrame("Frame", "XanDPS", UIParent)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

f.timechunk = {}

local timerCount = 0
local OnUpdate = function(self, elapsed)
	timerCount = timerCount + elapsed
	if timerCount >= 1 then
		self:ChunkTick()
		timerCount = 0
	end
end

--------------------------------------------
-----EVENTS
--------------------------------------------

local defaults = {
		["disabled"] = false,
		["fontSize"] = 12,
		["barHeight"] = 16,
		["stripRealm"] = true,
		["viewStyle"] = "Player DPS",
		["cSession"] = "total",
		["hideInArenaBG"] = false,
		["disableInArenaBG"] = false,
		["bgOpacity"] = 0.5,
}

function f:PLAYER_LOGIN()

	--Database creation
	if not XanDPS_DB then XanDPS_DB = {} end
	for k, v in pairs(defaults) do
		if XanDPS_DB[k] == nil then
			XanDPS_DB[k] = v
		end
	end
	
	--load up the display
	XanDPS_Display:LoadUP()

	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("PARTY_MEMBERS_CHANGED")
	f:RegisterEvent("RAID_ROSTER_UPDATE")
	f:RegisterEvent("UNIT_PET")
	f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	local ver = GetAddOnMetadata("XanDPS","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format(L["|cFF99CC33%s|r [v|cFFDF2B2B%s|r] Loaded:   /xandps"], "XanDPS", ver or "1.0"))
	
	f:UnregisterEvent("PLAYER_LOGIN")
	f.PLAYER_LOGIN = nil
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

function f:PLAYER_ENTERING_WORLD()
	--Pet Check
	f:Pet_Parse()

    local inInstance, instanceType  = IsInInstance()

	if ( instanceType ~= "pvp" and instanceType ~= "arena" ) then
		--if not a battleground or arena, do zone checks
		if ( inInstance and isInsideInstance ~= inInstance ) then
			-- Zoned into an instance
			if instanceNameStr ~= GetRealZoneText() then
				instanceNameStr = GetRealZoneText()
				--don't ask just reset
				if XanDPS_Display then XanDPS_Display:ResetStyleView() end
			elseif (playerGhost and instanceNameStr == GetRealZoneText() ) then
				--the player had died and entered the same instance, lets reset switch
				playerGhost = false
			elseif (not playerGhost and instanceNameStr == GetRealZoneText()) then
				--we zoned into a new instance of the same zone name
				--or we walked in and out of the same instance, either way
				--ASK if we want to reset, don't just do it
				StaticPopup_Show("XANDPS_RESET")
			end
		elseif ( inInstance and instanceNameStr ~= GetRealZoneText() ) then
			--we went from one instance to another, ASK for a reset
			instanceNameStr = GetRealZoneText()
			StaticPopup_Show("XANDPS_RESET")
		end
		bgDisabled = false
		
	elseif ( instanceType == "pvp" or instanceType == "arena" ) then
		--we entered a pvp battleground or arena, check if we should show the display
		if XanDPS_Display then
			--don't ask just reset, instance data + pvp data = bad
			XanDPS_Display:ResetStyleView()
			if XanDPS_DB.hideInArenaBG and XanDPS_Display:IsVisible() then
				XanDPS_Display:Hide()
			end
		end
		if XanDPS_DB.disableInArenaBG then
			bgDisabled = true
		end
	
	else
		--just in case ;)
		bgDisabled = false
    end

	if XanDPS_DB.disabled and XanDPS_Display and XanDPS_Display:IsVisible() then
		XanDPS_Display:Hide()
	end

    isInsideInstance = inInstance
	lastInstanceType = instanceType
	playerGhost = UnitIsGhost("player")
end

--------------------------------------------
-----TIMER (TICK) FUNCTIONS
--------------------------------------------

function f:StartChunk()
	--Don't create a chuck if there is one already active
	if f.timechunk.current then return nil end

	--otherwise create a new active chunk
	f.timechunk.current = {units = {}, starttime = time(), ntime = 0, isCurrent = true}

	--Initiate total if empty
	if f.timechunk.total == nil then
		f.timechunk.total = {units = {}, starttime = time(), ntime = 0, isTotal = true}
	end
	
	--initiate the timer
	f:SetScript("OnUpdate", OnUpdate)
end

function f:EndChunk()
	--save the previous chunk, in case the user wants to see the data for the last fight
	f.timechunk.current.endtime = time()
	f.timechunk.current.ntime = f.timechunk.current.endtime - f.timechunk.current.starttime
	f:Unit_UpdateTimeActive(f.timechunk.current) --update the time data for units in current chunk
	
	--setup previous chunk
	f.timechunk.previous = f.timechunk.current --save it as previous chunk
	f.timechunk.previous.isCurrent = false --turn off isCurrent flag for previous

	--add current chunk to total chunk time
	f.timechunk.total.ntime = f.timechunk.total.ntime + f.timechunk.current.ntime
	--update unit data and reset the last time update
	f:Unit_UpdateTimeActive(f.timechunk.total)
	f:Unit_TimeReset(f.timechunk.total)

	--Reset our timer and current chunk
	f.timechunk.current = nil
	f:SetScript("OnUpdate", nil) --cancel the tick timer
end

function f:ChunkTick()
	--if we have a current chunk and were not in combat, end the chunk
	if f.timechunk.current and not f:CombatStatus() and not f.parsingLog then
		f:EndChunk()
	end
end

--------------------------------------------
----- UNIT FUNCTIONS
--------------------------------------------

function f:Unit_Check(chunk, gid, pName)
	--NOTE: This function will create the unit if it doesn't exsist, or return the unit if found.
	if not chunk then return nil end
	if not chunk.units then return nil end
	
	if not chunk.units[gid] then
		if not pName then return nil end
		chunk.units[gid] = {gid = gid, name = pName, class = select(2, UnitClass(pName)), nfirst = time(), ntime = 0}
	end
	
	--set our time slots (this is for total not current, since total gets reset at ChunkEnd)
	if not chunk.units[gid].nfirst then
		chunk.units[gid].nfirst = time()
	end
	chunk.units[gid].nlast = time() --this updates the last time the player had preformed an action (each Unit_Check use)
	
	return chunk.units[gid]
end

function f:Unit_Fetch(chunk, gid)
	if not chunk then return nil end
	--NOTE: This function simply returns the player but will not create it if it doesn't exsist.
	return chunk.units[gid] or nil
end

function f:Unit_UpdateTimeActive(chunk)
	if not chunk then return nil end
	
	--update unit time data
	for k, v in pairs(chunk.units) do
		if v.nlast then
			--since we performed an action and last action is under a second, lets give them a 1 sec
			local dChk = (v.nlast - v.nfirst)
			if dChk <= 0 then dChk = 1 end
			v.ntime = v.ntime + dChk
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
		
		--if a chunk is in progress, add the time to the totaltime.
		if not chunk.endtime and units.nfirst then
			--since we performed an action and last action is under a second, lets give them a 1 sec
			local dChk = (units.nlast - units.nfirst)
			if dChk <= 0 then dChk = 1 end
			totaltime = totaltime + dChk
		end
	end

	return totaltime
end

function f:Unit_TimeReset(chunk)
	if not chunk then return nil end
	--NOTE: This function resets the unit time chunks
	for k, v in pairs(chunk.units) do
		v.nfirst = nil
		v.nlast = nil
	end
end

--------------------------------------------
----- PET FUNCTIONS
--------------------------------------------

function f:Pet_Check(unit_id, pet_id)
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
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			if UnitExists("raid"..i.."pet") then
				f:Pet_Check("raid"..i, "raid"..i.."pet")
			end
		end
	elseif IsInGroup() then
		for i = 1, GetNumSubgroupMembers() do
			if UnitExists("party"..i.."pet") then
				f:Pet_Check("party"..i, "party"..i.."pet")
			end
		end
	end
	if UnitExists("pet") then
		f:Pet_Check("player", "pet")
	end
end

function f:Pet_Reallocate(cl_action)
	if cl_action and band(cl_action.unitFlags, PET_FLAGS) ~= 0 then
		if cl_action.unitFlags and band(cl_action.unitFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
			if band(cl_action.unitFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
				--if guardian belongs to player then update owner
				--Greater Fire Elementals, Amry of the Dead, etc..
				cl_action.unitName = UnitName("player")
				cl_action.unitGUID = UnitGUID("player")
			end
		end
		--find pet and attach real owner if not guardian
		local uGUID, uName = f:Pet_Fetch(cl_action.unitGUID)
		if uGUID and uName then
			cl_action.unitGUID = uGUID
			cl_action.unitName = uName
		end
	end
end

--------------------------------------------
----- COMBAT LOG FUNCTIONS
----- NOTE: Special thanks to (zarnivoop) for Skada
--------------------------------------------

function f:Register_CL(func, event, flags)
	if not CL_events[event] then
		CL_events[event] = {}
	end
	tinsert(CL_events[event], {["func"] = func, ["flags"] = flags})
end

function f:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags, ...)
	if XanDPS_DB.disabled then return end
	if bgDisabled then return end
	
	--we don't want to record friendly fire
	if f:CheckFriendly(srcFlags,dstFlags) then return end
	
	local SRC_GOOD = nil
	local DST_GOOD = nil
	local SRC_GOOD_NOPET = nil
	local DST_GOOD_NOPET = nil

	--only start a session if were not currently in one, check for incombat
	if not f.timechunk.current and band(srcFlags, GROUP_FLAGS) ~= 0 then
		--if things check out and were in a group, check for combat
		if f:CombatStatus(eventtype) then
			f:StartChunk()
		end
	end

	-- Pet summons, guardians (only for raid/party/mine)
	if eventtype == 'SPELL_SUMMON' and band(srcFlags, GROUP_FLAGS) ~= 0 then
		--if a pet summons a pet (IE Fire Elemental Totem -> Summons Greater Fire Elemental)
		--check the source to see if its a pet, if it is then just resync it with actual owner.
		if unitpets[srcGUID] then
			--if the source is already a pet then grab the data and associate with owner
			--ie a fire elemental totem summoning a fire elemental.  Totem = pet, elemental = pet
			unitpets[dstGUID] = {gid = unitpets[srcGUID].gid, name = unitpets[srcGUID].name}
		else
			--if it's NOT a pet summoning (ie. fire elemental totem), then add pet with owner
			unitpets[dstGUID] = {gid = srcGUID, name = srcName}
		end
	end

	if eventtype == 'UNIT_DIED' and unitpets[dstGUID] then
		--keep the pet array clean and small, note for some reason UNIT_DIED is not always fired, blame blizzard
		unitpets[dstGUID] = nil
	end

	if f.timechunk.current and CL_events[eventtype] then
		f.parsingLog = true --to prevent onUpdate from terminating before we've parsed all the data
		
		for i, module in ipairs(CL_events[eventtype]) do
			local fail = false
			
			if not fail and module.flags.SRC_GOOD_NOPET then
				if SRC_GOOD_NOPET == nil then
					SRC_GOOD_NOPET = band(srcFlags, GROUP_FLAGS) ~= 0 and band(srcFlags, PET_FLAGS) == 0
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
					DST_GOOD_NOPET = band(dstFlags, GROUP_FLAGS) ~= 0 and band(dstFlags, PET_FLAGS) == 0
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
					SRC_GOOD = band(srcFlags, GROUP_FLAGS) ~= 0 or (band(srcFlags, PET_FLAGS) ~= 0 and unitpets[srcGUID])
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
					DST_GOOD = band(dstFlags, GROUP_FLAGS) ~= 0 or (band(dstFlags, PET_FLAGS) ~= 0 and unitpets[dstGUID])
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
	
	f.parsingLog = nil
end

function f:CheckFriendly(srcFlags,dstFlags)
	return (band(srcFlags,COMBATLOG_OBJECT_REACTION_FRIENDLY)~=0) and (band(dstFlags,COMBATLOG_OBJECT_REACTION_FRIENDLY)~=0)
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

function f:GetChunkTimeActive(chunk)
	if not chunk then return 0 end
	
	local totaltime = 0
	local uptTime = 0
	
	if chunk.isTotal and chunk.ntime then
		--it's total
		if chunk.ntime > 0 then
			totaltime = chunk.ntime
		end
		if f.timechunk.current then
			uptTime = time() - f.timechunk.current.starttime
		end
		return totaltime + uptTime
		
	elseif chunk.isCurrent then
		--it's current
		return time() - chunk.starttime
		
	elseif chunk.ntime then
		--it's previous (or some chunk that has time)
		return chunk.ntime
	end
	
	return totaltime
end

function f:ResetAll()
	f:SetScript("OnUpdate", nil) --cancel the tick timer
	
	if f.timechunk.previous then
		f.timechunk.previous = nil
	end
	if f.timechunk.current then
		f.timechunk.current = nil
	end
	if f.timechunk.total then
		f.timechunk.total = nil
	end
	if unitpets then
		unitpets = {}
	end
	--refill the pet table
	f:Pet_Parse()
end

function f:CombatStatus(eventtype)
	--There are times where the player can be out of combat and the raid be still in combat.  It happens.
	--So in those situation checking for ONLY if the player is in combat is not accurate.  So we are going
	--to scan the raid/party for the very first person in combat.  If found then return true.
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			if UnitExists("raid"..i) then
				if UnitAffectingCombat("raid"..i) or UnitAffectingCombat("raidpet"..i) then return true end
			end
		end
	elseif IsInGroup() then
		for i = 1, GetNumSubgroupMembers() do
			if UnitExists("party"..i) then
				if UnitAffectingCombat("party"..i) or UnitAffectingCombat("partypet"..i) then return true end
			end
		end
	end
	--the reason I put the player one last, is in the event were dead but the raid/party is still fighting
	if UnitAffectingCombat("player") then return true end
	if UnitAffectingCombat("pet") then return true end

	--sometimes you do damage or kill something SO quickly that your not considered in combat after the event is parsed.
	--because of this we have to track for damage based events, basically ANY DAMAGE BEING DONE = you in combat
	if eventtype then
		local events = {
			SWING_DAMAGE = true, 
			RANGE_DAMAGE = true, 
			SPELL_DAMAGE = true, 
			SPELL_PERIODIC_DAMAGE = true, 
			SPELL_BUILDING_DAMAGE = true,
			DAMAGE_SHIELD = true,
			DAMAGE_SPLIT = true,
			SWING_MISSED = true,
			RANGE_MISSED = true,
			SPELL_MISSED = true,
			SPELL_PERIODIC_MISSED = true,
			SPELL_BUILDING_MISSED = true,
			DAMAGE_SHIELD_MISSED = true
		}
		if events[eventtype] then return true end
	end
	
	return false
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
