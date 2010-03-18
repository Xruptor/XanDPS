local playerGUID = 0
local timechunk = {}
local unitpets = {}
local ticktimer = nil

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

	-- Also start the total set if it is nil.
	if timechunk.total == nil then
		timechunk.total = {units = {}, starttime = time(), ntime = 0}
	end

	ticktimer = timerLib:ScheduleRepeatingTimer("Tick", f.ChunkTick, 1)
end

function f:EndChunk()
	--save the last chunk, in case the user wants to see the data for the last fight
	timechunk.current.endtime = time()
	timechunk.last = timechunk.current
		
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
			return p
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
		unitID = {gid = gid, class = select(2, UnitClass(pName)), name = pName, first = time(), ntime = 0}
		table.insert(chunk.units, unitID)
	end
	
	--set our time slots
	if not unitID.first then
		unitID.first = time()
	end
	unitID.last = time()

	return unitID
end

function f:Unit_UpdateTimeActive(chunk)
	--update unit time data
	for k, v in ipairs(chunk.units) do
		if v.last then
			v.ntime = v.ntime + (v.last - v.first)
		end
	end
end

function f:Unit_TimeActive(chunk, units)
	--return unit time data
	local maxtime = 0
	
	if units.ntime > 0 then
		maxtime = units.ntime
	end
	
	if not chunk.endtime and units.first then
		maxtime = maxtime + units.last - units.first
	end
	return maxtime
end

function f:Unit_TimeReset(chunk)
	for k, v in ipairs(chunk.units) do
		v.first = nil
		v.last = nil
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
	return petGUID, petName
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

--------------------------------------------
----- MISC FUNCTIONS
--------------------------------------------

function f:GetChunkTime(chunk)
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