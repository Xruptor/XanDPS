local tip = LibStub("tektip-1.0").new(4)

local myDamage, timeincombat, pId = 0, 0
local damagetotals, times, ids, units, unitnames, colors, idnames = {}, {}, {}, {}, {}, {}, {}
local totalbattledmg, partyInvite, isInGroup, switchCustomReset = 0, 0, 0, 0
local processDmgData = ""
local events = {SWING_DAMAGE = true, RANGE_DAMAGE = true, SPELL_DAMAGE = true, SPELL_PERIODIC_DAMAGE = true, DAMAGE_SHIELD = true, DAMAGE_SPLIT = true}

for class,color in pairs(RAID_CLASS_COLORS) do colors[class] = string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) end
colors["UNKNOWN"] = "999999" --grey

local f = CreateFrame("frame","XanDPS",UIParent)
f:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

local menu = X_MenuClass:New()

f:SetScript("OnUpdate", function(self, elap)
	if self.loadingData then return end
	if f:IsInBG() and XanDPS_DB.notBG then return end
	
	if self.TSLU == nil then self.TSLU = 0 end
	self.TSLU = self.TSLU + elap
	
	for unit,id in pairs(ids) do
		if UnitAffectingCombat(unit) then times[id] = (times[id] or 0) + elap end
	end

	if (self.TSLU > 1) then
		getglobal("XanDPSText"):SetText(string.format(XANDPS_DPS, (damagetotals[pId] or 0)/(times[pId] or 1)) or XANDPS_DPS2)
		if GetNumPartyMembers() < 1 and isInGroup == 1 then isInGroup = 0 end
		self.TSLU = 0
	end
	
	-------------------------------------
	--Send the total dmg, in case someone in party has XanDPS and they have incorrect data
	if self.sendDataUpt == nil then self.sendDataUpt = 0 end
	self.sendDataUpt = self.sendDataUpt + elap
	
	--do this every 20 seconds
	if (self.sendDataUpt > 20) then
		--only do if we actually have some battle dmg and that we didn't do a custom reset
		--don't do this in battlegrounds
		if totalbattledmg > 0 and switchCustomReset > 0 and not f:IsInBG() then
			if GetNumRaidMembers() > 0 then
				ChatThrottleLib:SendAddonMessage("NORMAL", "XANDPS", "1:"..totalbattledmg, "RAID")
			elseif GetNumPartyMembers() > 0 then
				ChatThrottleLib:SendAddonMessage("NORMAL", "XANDPS", "1:"..totalbattledmg, "PARTY")
			end
		end
		self.sendDataUpt = 0
	end
	-------------------------------------
	
	--DmgData Timer, to make sure we only send the data every 20 seconds
	if self.sendDmgUpt then
		self.sendDmgUpt = self.sendDmgUpt - elap
		if self.sendDmgUpt <= 0 then
			--reset our last sent
			self.lastSender = nil
			self.sendDmgUpt = nil
		end
	end
	
	--timer for last request for data, make sure we only request data every 20 seconds
	if self.lastReq then
		self.lastReq = self.lastReq - elap
		if self.lastReq <= 0 then
			--reset our last sent
			self.lastReq = nil
		end
	end

end)

function f:PLAYER_LOGIN()
	pId = UnitGUID("player")
	
	if not XanDPS_DB then XanDPS_DB = {} end
	if XanDPS_DB.bgShown == nil then XanDPS_DB.bgShown = 1 end

	f:CreateDPSFrame()
	f:CreateMenuFrame()
	f:RestoreLayout("XanDPS")
	
	ids.player = pId
	units[pId] = pId
	local classN, classNL = UnitClass("player")
	unitnames[pId] = UnitName("player").."#"..f:ClassNumber(classNL, 1)
	idnames[UnitName("player")] = pId
	
	local petid = UnitGUID("pet")
	if petid then
		units[petid], ids.pet = pId, petid
	end

	f:PARTY_MEMBERS_CHANGED()
	f:RAID_ROSTER_UPDATE()

	f:RegisterEvent("PLAYER_REGEN_ENABLED")
	f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	f:RegisterEvent("PARTY_MEMBERS_CHANGED")
	f:RegisterEvent("RAID_ROSTER_UPDATE")
	f:RegisterEvent("UNIT_PET")
	f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	f:RegisterEvent("CHAT_MSG_ADDON")
	
	SLASH_XANDPS1 = "/xandps"
	SlashCmdList["XANDPS"] = XanDPS_SlashCommand
	
	local ver = GetAddOnMetadata("XanDPS","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format(XANDPS_LOADED, ver or "1.0"))
	
	f:UnregisterEvent("PLAYER_LOGIN")
	f.PLAYER_LOGIN = nil
end

function XanDPS_SlashCommand(cmd)
	if cmd and cmd ~= "" then
		if cmd:lower() == XANDPS_OPT1_VALUE then
			DEFAULT_CHAT_FRAME:AddMessage(XANDPS_FRAME_RESET)
			XanDPS:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	
			return nil
		elseif cmd:lower() == XANDPS_OPT2_VALUE then
			XanDPS:BackgroundToggle()
			return nil
		end
	end
	local ver = GetAddOnMetadata("XanDPS","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage("XanDPS ver("..ver..")")
	DEFAULT_CHAT_FRAME:AddMessage(XANDPS_OPT1)
	DEFAULT_CHAT_FRAME:AddMessage(XANDPS_OPT2)
end

function f:UNIT_PET(unit)
	if f:IsInBG() and XanDPS_DB.notBG then return end
	if unit == "player" then
		local petid = UnitGUID("pet")
		ids.pet = petid
		if petid then
			units[petid] = pId
		end
	elseif unit ~= "target" and unit ~= "focus" then
		local group, id = unit:match("^(%D+)(%d+)$")
		if not id then
			print(string.format(XANDPS_ERRORU, unit))
		else
			local petid = UnitGUID(group.."pet"..id)
			if petid then
				units[petid] = ids[unit]
			end
		end
	end
end

function f:PARTY_MEMBERS_CHANGED()
	if f:IsInBG() and XanDPS_DB.notBG then return end
	--check to see if we were invited into a new party, if so reset data.
	--we do this because we don't want to share our old data with everyone
	if isInGroup == 0 and GetNumPartyMembers() > 0 then
		isInGroup = 1
		--switchCustomReset: this allows us to do a custom reset of data during a instance/raid/dungeon without it syncing
		--with others and filling up with data again.  (Unless we sync it manually)
		switchCustomReset = 1
		f:ResetData(1, 1)
	end

	for i=1,4 do
		local id = UnitGUID("party"..i)
		ids["party"..i] = id
		if ids["party"..i] and UnitClass("party"..i) then
			units[id] = id
			local classN, classNL = UnitClass("party"..i)
			unitnames[id] = UnitName("party"..i).."#"..f:ClassNumber(classNL, 1)
			idnames[UnitName("party"..i)] = id
		end

		local petid = UnitGUID("partypet"..i)
		if petid then 
			units[petid] = id
		end
	end
end

function f:RAID_ROSTER_UPDATE()
	if f:IsInBG() and XanDPS_DB.notBG then return end
	for i=1,40 do
		local id = UnitGUID("raid"..i)
		ids["raid"..i] = id
		if ids["raid"..i] and UnitClass("raid"..i) then
			units[id] = id
			local classN, classNL = UnitClass("raid"..i)
			unitnames[id] = UnitName("raid"..i).."#"..f:ClassNumber(classNL, 1)
			idnames[UnitName("raid"..i)] = id
		end

		local petid = UnitGUID("raidpet"..i)
		if petid then
			units[petid] = id;
		end
	end
end

function f:COMBAT_LOG_EVENT_UNFILTERED(_, eventtype, id, _, _, _, _, _, spellid, _, _, damage)
	if f:IsInBG() and XanDPS_DB.notBG then return end
	if not events[eventtype] then return end
	if f.loadingData then return end

	if id == pId or id == ids.pet then
		if eventtype == "SWING_DAMAGE" then
			damage = spellid
		end
		myDamage = myDamage + damage
	end

	if units[id] then
		damagetotals[units[id]] = (damagetotals[units[id]] or 0) + (eventtype == "SWING_DAMAGE" and spellid or damage)
		totalbattledmg = totalbattledmg + (eventtype == "SWING_DAMAGE" and spellid or damage)
	end
end

function f:PLAYER_REGEN_ENABLED()
	if f:IsInBG() and XanDPS_DB.notBG then return end
	if f.loadingData then return end
	getglobal("XanDPSText"):SetText(string.format(XANDPS_DPS, (damagetotals[pId] or 0)/(times[pId] or 1)) or XANDPS_DPS2)
end

local function totalDmgChk(sD)
	if switchCustomReset < 1 then return false end --we don't want to update if we did a custom reset
	if totalbattledmg <= 0 then return true end
	if sD and sD > totalbattledmg then
		local getNum = ceil(((sD - totalbattledmg) / sD) * 100)
		--(larger number - small number / large number) * 100
		--only do if the new number is 20% or greater then what we have stored
		if getNum >= 20 then
			return true
		end
	end
	return false
end

function f:CHAT_MSG_ADDON(prefix, message, channel, sender, ...)
	if f:IsInBG() and XanDPS_DB.notBG then return end
	if channel == "WHISPER" then return end --don't accept whispers
	if sender and sender == UnitName("player") then return end --don't want to accept our own stuff
	if switchCustomReset < 1 then return end --we don't want to update if we did a custom reset
	
	if prefix == "XANDPS" and message and sender then
		local actNum, actData = strsplit(':', message)
		
		--TOTALDMG COMPARE
		if actNum and tonumber(actNum) and tonumber(actNum) == 1 then
			if actData and tonumber(actData) and not f.lastReq then
				if totalDmgChk(tonumber(actData)) then
					--our numbers don't match so lets send a request
					if GetNumRaidMembers() > 0 then
						ChatThrottleLib:SendAddonMessage("NORMAL", "XANDPS", "2:"..sender, "RAID")
						processDmgData = ""
						f.lastReq = 20 --timer to prevent multiple asking of dmg data
					elseif GetNumPartyMembers() > 0 then
						ChatThrottleLib:SendAddonMessage("NORMAL", "XANDPS", "2:"..sender, "PARTY")
						processDmgData = ""
						f.lastReq = 20 --timer to prevent multiple asking of dmg data
					end
				end
			end
		elseif actNum and tonumber(actNum) and tonumber(actNum) == 2 then
			if actData and actData == UnitName("player") then
				--a user is requesting data lets send it if we aren't tagged from previously sending one
				--we don't want to spam, nor do we want people to trick the mod to send multiple times
				if not f.lastSender then
					f.lastSender = sender
					f.sendDmgUpt = 20
					f:SendDmgData()
				elseif f.lastSender and f.lastSender ~= sender then
					f.lastSender = sender
					f.sendDmgUpt = 20
					f:SendDmgData()
				end
			end
		elseif actNum and tonumber(actNum) and tonumber(actNum) == 3 then
		
			local sptD = {strsplit(':', message)}
			
			if sptD and table.getn(sptD) >= 2 then
				--check to see if this data is better then ours, if so then lets use it
				--regardless of who requested it
				if sptD[2] == "START" and sptD[3] and tonumber(sptD[3]) then
					if totalDmgChk(tonumber(sptD[3])) then
						processDmgData = ""
						f.getSenderData = sender
						f.storeDmg = tonumber(sptD[3])
					end
				elseif sptD[2] == "END" and f.getSenderData and f.getSenderData == sender then
					--don't update data via OnUpdate or Combat while we are loading a transmitted update
					f.loadingData = true
						
						totalbattledmg = f.storeDmg
						for k,v in pairs({strsplit(':', processDmgData)}) do
							local dID, dDmg, dTime = strsplit('@', v)
							if dID and dDmg and tonumber(dDmg) and dTime and tonumber(dTime) then
								local actName, actClassNum = strsplit('#', dID)
								if actName and actClassNum and idnames[actName] then
									damagetotals[idnames[actName]] = tonumber(dDmg)
									times[idnames[actName]] = tonumber(dTime)
								end
							end
						end
						f.getSenderData = nil
						f.storeDmg = nil
					
					f.loadingData = nil
				else
					if f.getSenderData and f.getSenderData == sender then
						--aggregate the data together until END
						processDmgData = processDmgData..message:sub(3) --"strip 3:"
					end
				end
				
			end

		end

	end
end

local isInsideInstance = false
local instanceNameStr = "none"
local playerGhost = false

function f:ZONE_CHANGED_NEW_AREA()
	if f:IsInBG() and XanDPS_DB.notBG then return end
    local inInstance = IsInInstance()
	
	if ( not f:IsInBG() and not f:IsInArena() ) then
		if ( inInstance and isInsideInstance ~= inInstance ) then
			-- Zoned into an instance
			if instanceNameStr ~= GetRealZoneText() then
				instanceNameStr = GetRealZoneText()
				--reset our data
				 f:ResetData(nil, 3)
			elseif (playerGhost and instanceNameStr == GetRealZoneText() ) then
				--the player had died lets reset the switch
				playerGhost = false
			elseif (not playerGhost and instanceNameStr == GetRealZoneText()) then
				--we zoned into a new instance of the same zone name
				--reset our data
				f:ResetData(nil, 4)
			end
		elseif( not inInstance and isInsideInstance ~= inInstance ) then
       -- Was zoned out of an instance
		end
	end
	
    if( f:IsInBG() ) then
		--reset our data
		f:ResetData(nil, 5)
	elseif f:IsInArena() then
		--reset our data
		f:ResetData(nil, 6)
    end
	
    isInsideInstance = inInstance
	playerGhost = UnitIsGhost("player")
end

------------------------
--   LOCAL FUNCTIONS  --
------------------------

function f:CreateDPSFrame()

	f:SetWidth(110)
	f:SetHeight(27)
	f:SetMovable(true)
	f:SetClampedToScreen(true)

	if XanDPS_DB.bgShown == 1 then
		f:SetBackdrop( {
			bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border";
			tile = true; tileSize = 32; edgeSize = 16;
			insets = { left = 5; right = 5; top = 5; bottom = 5; };
		} );
		f:SetBackdropBorderColor(0.5, 0.5, 0.5)
		f:SetBackdropColor(0.5, 0.5, 0.5, 0.6)
	else
		f:SetBackdrop(nil)
	end
	
	f:EnableMouse(true)

	local t = f:CreateTexture("$parentIcon", "ARTWORK")
	t:SetTexture("Interface\\Icons\\Ability_Parry.blp")
	t:SetWidth(16)
	t:SetHeight(16)
	t:SetPoint("TOPLEFT",5,-6)

	local g = f:CreateFontString("$parentText", "ARTWORK", "GameFontNormalSmall")
	g:SetJustifyH("LEFT")
	g:SetPoint("LEFT",30,0)
	g:SetText("0.0 dps")

	f:SetScript("OnMouseDown",function()
		if (IsShiftKeyDown()) then
			self.isMoving = true
			self:StartMoving()
	 	end
	end)
	f:SetScript("OnMouseUp",function(self, button)
		if( self.isMoving ) then

			self.isMoving = nil
			self:StopMovingOrSizing()

			self:SaveLayout(self:GetName())
		else
			if button == "RightButton" then
				menu:Show()
			end
		end
	end)

	f:SetScript("OnLeave",function()
		tip:Hide()
	end)

	f:SetScript("OnEnter",function()
		tip:AnchorTo(self)

		tip:AddLine("XanDPS")
		tip:AddLine(" ")
		tip:AddMultiLine(XANDPS_TT1, XANDPS_TT2, XANDPS_TT3, XANDPS_TT4)

		--sort in descneding order by DPS
		local a = {}
		for id in pairs(damagetotals) do
			table.insert(a, { id, (damagetotals[id] or 0)/(times[id] or 1), damagetotals[id] or 0 } )
		end
		table.sort(a, function(a,b) return a[2]>b[2] end)

		--display information
		for i = 1, table.getn(a) do
			local idchk = a[i][1]
			local totaldps = a[i][2]
			local totaldmg = a[i][3]
			local totalpercent = (totaldmg / totalbattledmg) * 100 --calculate total percentage of dmg done
			
			local actName, actClassNum = strsplit('#', unitnames[idchk])
			if actName and actClassNum then
				local className, classShort = XanDPS:ClassNumber(actClassNum, 2)
				actName = "|cff"..colors[className]..actName.."|r"
				tip:AddMultiLine(actName or "???", totaldmg, string.format("%d", totalpercent or 0).."%",  string.format("%.1f", totaldps), nil,nil,nil,nil, 1,1,1,1, 1,1,1,1)
			end
		end
		
		a = nil --empty our temp
		tip:AddLine(" ")
		tip:AddLine(XANDPS_TTH1)
		tip:AddLine(XANDPS_TTH2)

		tip:Show()
	end)
	
	f:Show()
end

function f:CreateMenuFrame()
	menu:AddItem(XANDPS_MNU1, function()
		XanDPS:ResetData(nil, 7)
		--force a custom reset switch, this will prevent syncing (unless we tell it manually)
		switchCustomReset = 0
	end)
	menu:AddItem(XANDPS_MNU7, function() XanDPS:ResetData(nil, 8, true) end)
	menu:AddItem(' ', function() end) --empty space (also closes the window)
	menu:AddItem(XANDPS_MNU2, function() XanDPS:ReportData("SAY") end)
	menu:AddItem(XANDPS_MNU3, function() StaticPopup_Show("XANDPS_WHISPER") end)
	menu:AddItem(XANDPS_MNU4, function() XanDPS:ReportData("PARTY") end)
	menu:AddItem(XANDPS_MNU5, function() XanDPS:ReportData("RAID") end)
	menu:AddItem(XANDPS_MNU6, function() XanDPS:ReportData("GUILD") end)
	menu:AddItem(' ', function() end) --empty space (also closes the window)
	menu:AddItem(XANDPS_MNU8, function() end) --close the window
end

function f:ResetData(sWt, sC, resync)
	--sC: returns what function called the reset by a number
	for i in pairs(damagetotals) do damagetotals[i] = nil end
	for i in pairs(times) do times[i] = nil end
	totalbattledmg = 0

	--reset our localized data
	ids, units, unitnames, idnames = {}, {}, {}, {}
	
	--add the current player first
	ids.player = pId
	units[pId] = pId
	local classN, classNL = UnitClass("player")
	unitnames[pId] = UnitName("player").."#"..f:ClassNumber(classNL, 1)
	idnames[UnitName("player")] = pId

	--get player pet if it exists then populate data
	local petid = UnitGUID("pet")
	if petid then
		units[petid], ids.pet = pId, petid
	end
	
	--populate data if we are in a party
	if not sWt then
		f:PARTY_MEMBERS_CHANGED()
	end
	
	--populate data if we are in a raid
	f:RAID_ROSTER_UPDATE()
	
	--enable the syncing again if it's off
	if resync and isInGroup == 1 then
		switchCustomReset = 1
		print(XANDPS_RESYNC)
	elseif resync and isInGroup == 0 then
		print(XANDPS_RESYNC2)
	end

end

StaticPopupDialogs["XANDPS_WHISPER"] = {
	text = XANDPS_WHISPER1,
	button1 = XANDPS_WHISPER2,
	button2 = XANDPS_WHISPER3,
	OnAccept = function()
		local textg = getglobal(this:GetParent():GetName().."EditBox"):GetText()
		if textg == "" or textg == nil then
			print(XANDPS_WHISPER4)
		else
			XanDPS:ReportData("WHISPER", textg)
		end
	end,
	OnCancel = function (_,reason)
	--do nothing
	end,
	timeout = 30,
	whileDead = false,
	hideOnEscape = true,
	hasEditBox = 1,
	maxLetters = 32,
	OnShow = function()
		getglobal(this:GetName().."EditBox"):SetFocus();
	end,
	OnHide = function()
		getglobal(this:GetName().."EditBox"):SetText("");
	end,
}

--only report top 10
function f:ReportData(channel, target)
	if not channel then return end
	
	ChatThrottleLib:SendChatMessage("NORMAL", "XANDPS", XANDPS_REPORT1, channel, nil, target)
	ChatThrottleLib:SendChatMessage("NORMAL", "XANDPS", "--------------------", channel, nil, target)
	
	--sort in descneding order by DPS
	local a = {}
	local count = 0
	local topTen = 1
	
	for id in pairs(damagetotals) do
		if topTen <= 10 then
			table.insert(a, { id, (damagetotals[id] or 0)/(times[id] or 1), damagetotals[id] or 0 } )
			topTen = topTen + 1
		end
	end
	table.sort(a, function(a,b) return a[2]>b[2] end)

	--display information
	for i = 1, table.getn(a) do

		local idchk = a[i][1]
		local totaldps = a[i][2]
		local totaldmg = a[i][3]
		local totalpercent = (totaldmg / totalbattledmg) * 100 --calculate total percentage of dmg done
		
		local actName, actClassNum = strsplit('#', unitnames[idchk])
		local cN, cS =  f:ClassNumber(actClassNum, 2)
		
		local ttlPer = string.format("%d", totalpercent or 0)
		local ttlDps = string.format("%.1f", totaldps)

		--#1 JohnDoe [DK], 4556543 (23%), 2134.4 dps
		count = count + 1
		local outstr = "#"..count.." "..(actName or "???").." ["..(cS or "??").."], "..totaldmg.." ("..ttlPer.."%), "..ttlDps.." "..string.lower(XANDPS_TT4)

		ChatThrottleLib:SendChatMessage("NORMAL", "XANDPS", outstr, channel, nil, target)
	end
	
end

function f:SendDmgData()
	--don't transmit data while we are updating
	if f.loadingData then return end
	
	local strSend = ""
	local preChan = "PARTY"
	
	if GetNumRaidMembers() > 0 then
		preChan = "RAID"
	elseif GetNumPartyMembers() > 0 then
		preChan = "PARTY"
	else
		return
	end
	
	--transmit that we are starting
	--3:START:736473643
	ChatThrottleLib:SendAddonMessage("BULK", "XANDPS", "3:START:"..totalbattledmg, preChan)
	
	--start string gather, initiate with identifier '3'
	strSend = "3"

	--we could send the GUID, but my gosh are they long... so lets send names instead
	--BOB#1@34557@232445@3.56
	for id in pairs(damagetotals) do
		if id and damagetotals[id] and times[id] and unitnames[id] then
			--use only 3 decimals for the time
			strSend = strSend..":"..unitnames[id].."@"..damagetotals[id].."@"..string.format("%.3f", times[id])
		end
	end

	--there is a chat limit of 255, but we are going to use 250 just in case
	if string.len(strSend) > 250 then
		--break down into peices, we are going to make the chunck size 240 to be safe
		local i = 1
		while true do
		  local chunk = string.sub(strSend, i, i + 240 - 1)
		  i = i + 240
		  if i > string.len(strSend) then
				--last of the chunks, so lets send and break
				ChatThrottleLib:SendAddonMessage("BULK", "XANDPS", "3:"..chunk, preChan)
				break
		  else
				ChatThrottleLib:SendAddonMessage("BULK", "XANDPS", "3:"..chunk, preChan)
		  end
		end
		ChatThrottleLib:SendAddonMessage("BULK", "XANDPS", "3:END", preChan)
	else
		ChatThrottleLib:SendAddonMessage("BULK", "XANDPS", strSend, preChan)
		ChatThrottleLib:SendAddonMessage("BULK", "XANDPS", "3:END", preChan)
	end
	
end

function f:SaveLayout(frame)
	if not XanDPS_DB then XanDPS_DB = {} end

	local opt = XanDPS_DB[frame] or nil

	if opt == nil then
		XanDPS_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanDPS_DB[frame]
	end

	local f = getglobal(frame)
	local scale = f:GetEffectiveScale()
	opt.PosX = f:GetLeft() * scale
	opt.PosY = f:GetTop() * scale
	--opt.Width = f:GetWidth()
	--opt.Height = f:GetHeight()

end

function f:RestoreLayout(frame)
	if not XanDPS_DB then XanDPS_DB = {} end
	
	local f = getglobal(frame)
	local opt = XanDPS_DB[frame] or nil

	if opt == nil then
		XanDPS_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = XanDPS_DB[frame]
	end

	local x = opt.PosX
	local y = opt.PosY
	local s = f:GetEffectiveScale()

	    if not x or not y then
		f:ClearAllPoints()
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		return 
	    end

	--calculate the scale
	x,y = x/s,y/s

	--set the location
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)

end

function f:BackgroundToggle()
	if not XanDPS_DB then XanDPS_DB = {} end
	if XanDPS_DB.bgShown == nil then XanDPS_DB.bgShown = 1 end
	if XanDPS_DB.notBG == nil then XanDPS_DB.notBG = false end
	
	if XanDPS_DB.bgShown == 0 then
		XanDPS_DB.bgShown = 1
		DEFAULT_CHAT_FRAME:AddMessage(XANDPS_BG1)
	elseif XanDPS_DB.bgShown == 1 then
		XanDPS_DB.bgShown = 0
		DEFAULT_CHAT_FRAME:AddMessage(XANDPS_BG2)
	else
		XanDPS_DB.bgShown = 1
		DEFAULT_CHAT_FRAME:AddMessage(XANDPS_BG1)
	end

	--now change background
	if XanDPS_DB.bgShown == 1 then
		f:SetBackdrop( {
			bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border";
			tile = true; tileSize = 32; edgeSize = 16;
			insets = { left = 5; right = 5; top = 5; bottom = 5; };
		} );
		f:SetBackdropBorderColor(0.5, 0.5, 0.5)
		f:SetBackdropColor(0.5, 0.5, 0.5, 0.6)
	else
		f:SetBackdrop(nil)
	end
	
end

function f:IsInBG()
	if (GetNumBattlefieldScores() > 0) then
		return true
	end
	local status, mapName, instanceID, minlevel, maxlevel
	for i=1, MAX_BATTLEFIELD_QUEUES do
		status, mapName, instanceID, minlevel, maxlevel, teamSize = GetBattlefieldStatus(i)
		if status == "active" then
			return true
		end
	end
	return false
end

function f:IsInArena()
	local a,b = IsActiveBattlefieldArena()
	if (a == nil) then
		return false
	end
	return true
end

function f:ClassNumber(sArg, sSwitch)

	if not sSwitch or sSwitch == 1 then 
		if sArg == "WARRIOR" then
			return 1
		elseif sArg == "MAGE" then
			return 2
		elseif sArg == "ROGUE" then
			return 3
		elseif sArg == "DRUID" then
			return 4
		elseif sArg == "HUNTER" then
			return 5
		elseif sArg == "SHAMAN" then
			return 6
		elseif sArg == "PRIEST" then
			return 7
		elseif sArg == "WARLOCK" then
			return 8
		elseif sArg == "PALADIN" then
			return 9
		elseif sArg == "DEATHKNIGHT" then
			return 10
		else
			return 11
		end
	end
	
	if not tonumber(sArg) then return "UNKNOWN", "??" end
	sArg = tonumber(sArg)
	
	if sArg == 1 then
		return "WARRIOR", XANDPS_CLASSNUM[1]
	elseif sArg == 2 then
		return "MAGE", XANDPS_CLASSNUM[2]
	elseif sArg == 3 then
		return "ROGUE", XANDPS_CLASSNUM[3]
	elseif sArg == 4 then
		return "DRUID", XANDPS_CLASSNUM[4]
	elseif sArg == 5 then
		return "HUNTER", XANDPS_CLASSNUM[5]
	elseif sArg == 6 then
		return "SHAMAN", XANDPS_CLASSNUM[6]
	elseif sArg == 7 then
		return "PRIEST", XANDPS_CLASSNUM[7]
	elseif sArg == 8 then
		return "WARLOCK", XANDPS_CLASSNUM[8]
	elseif sArg == 9 then
		return "PALADIN", XANDPS_CLASSNUM[9]
	elseif sArg == 10 then
		return "DEATHKNIGHT", XANDPS_CLASSNUM[10]
	elseif sArg == 11 then
		return "UNKNOWN", "??"
	else
		return "UNKNOWN", "??"
	end
	
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end