--[[----------------------------------------------------------------------------
Name: XanDPS_Display
Description: The display module for XanDPS
Author: Xruptor
Email: private message (PM) me at wowinterface.com
------------------------------------------------------------------------------]]

local L = XanDPS_L
local viewChange = false
local d_modes = {}
local x_modules = {}
local c_modes = {
	["current"] = true,
	["previous"] = true,
	["total"] = true,
}

local display = CreateFrame("Frame", "XanDPS_Display", UIParent)
display:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

StaticPopupDialogs["XANDPS_RESET"] = {
  text = "XanDPS: "..(L["Do you wish to reset the data?"] or ""),
  button1 = L["Yes"],
  button2 = L["No"],
  sound = "INTERFACESOUND_CHARWINDOWOPEN",
  OnAccept = function()
	  display:ResetStyleView();
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

SLASH_XANDPS1 = "/xandps";
SlashCmdList["XANDPS"] = function()
	if display:IsVisible() then
		display:Hide()
	else
		display:Show()
	end
end

function display:Register_Mode(module, name, func, bgcolor, showAll)
	d_modes[name] = {["module"] = module, ["name"] = name, ["func"] = func, ["bgcolor"] = bgcolor, ["showAll"] = showAll}
	x_modules[module] = true
	--update the dropdown menu list
	display:setupDropDown()
end

function display:CreateDisplay()
	display:SetPoint("CENTER")
	display:SetWidth(200)
	display:SetHeight(250)
	display:SetMinResize(50, 50)
	display:EnableMouse(true)
	display:SetMovable(true)
	display:SetResizable(true)
	display:SetUserPlaced(true)
	display:SetClampedToScreen(true)

	display:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background.tga]], tile = true, tileSize = 16,
		edgeFile = [[Interface\addons\XanDPS\media\otravi-semi-full-border.tga]], edgeSize = 32,
		insets = {left = 0, right = 0, top = 20, bottom = 0},
	})
	
	display:SetBackdropColor(0, 0, 0, XanDPS_DB.bgOpacity or 0.5)
	display:SetBackdropBorderColor(0.48, 0.48, 0.48)
	
	display:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:StartMoving()
		end
	end)

	display:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
			self:SaveLayout(self:GetName());
		end
	end)

	local header = display:CreateFontString(nil, "OVERLAY")
	header:SetFont(STANDARD_TEXT_FONT, 12)
	header:SetJustifyH("CENTER")
	header:SetPoint("CENTER")
	header:SetPoint("TOP", 0, -12)
	display.header = header

	local grip = CreateFrame("Frame", nil, display)
	grip:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -1, 1)
	grip:SetHeight(16)
	grip:SetWidth(16)
	grip:SetFrameLevel(20)
	grip:EnableMouse(true)

	grip:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			display:StartSizing()
		end
	end)
	
	grip:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			display:StopMovingOrSizing()
			display:SaveLayout(display:GetName());
		end
	end)

	local gripTexture = grip:CreateTexture(nil, "OVERLAY")
	gripTexture:SetTexture([[Interface\addons\XanDPS\media\rightgrip.tga]])
	gripTexture:SetBlendMode("ADD")
	gripTexture:SetAlpha(0.6)
	gripTexture:SetAllPoints(grip)

	grip.gripTexture = gripTexture
	display.grip = grip
	
	local closeButton = CreateFrame("Frame", nil, display)
	closeButton:SetPoint("TOPRIGHT", display, "TOPRIGHT", -4, -15)
	closeButton:SetHeight(14)
	closeButton:SetWidth(14)
	closeButton:SetFrameLevel(20)
	closeButton:EnableMouse(true)

	closeButton:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			display:Hide()
		end
	end)
	
	local closeTexture = closeButton:CreateTexture(nil, "OVERLAY")
	closeTexture:SetTexture([[Interface\addons\XanDPS\media\close.tga]])
	closeTexture:SetBlendMode("ADD")
	closeTexture:SetAlpha(0.6)
	closeTexture:SetAllPoints(closeButton)

	closeButton.closeTexture = closeTexture
	display.closeButton = closeButton
	
	local resetButton = CreateFrame("Frame", nil, display)
	resetButton:SetPoint("TOPLEFT", display, "TOPLEFT", 4, -15)
	resetButton:SetHeight(14)
	resetButton:SetWidth(14)
	resetButton:SetFrameLevel(20)
	resetButton:EnableMouse(true)

	resetButton:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			StaticPopup_Show("XANDPS_RESET")
		end
	end)
	
	local resetTexture = resetButton:CreateTexture(nil, "OVERLAY")
	resetTexture:SetTexture([[Interface\addons\XanDPS\media\reset.tga]])
	resetTexture:SetBlendMode("ADD")
	resetTexture:SetAlpha(0.6)
	resetTexture:SetAllPoints(resetButton)

	resetButton.resetTexture = resetTexture
	display.resetButton = resetButton
	
	local settingsButton = CreateFrame("Frame", nil, display)
	settingsButton:SetPoint("TOPLEFT", display, "TOPLEFT", 22, -15.5)
	settingsButton:SetHeight(14)
	settingsButton:SetWidth(14)
	settingsButton:SetFrameLevel(20)
	settingsButton:EnableMouse(true)

	settingsButton:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			ToggleDropDownMenu(1, nil, display.DD, "cursor", 0, 0)
		end
	end)
	
	local settingsTexture = settingsButton:CreateTexture(nil, "OVERLAY")
	settingsTexture:SetTexture([[Interface\addons\XanDPS\media\settings.tga]])
	settingsTexture:SetBlendMode("ADD")
	settingsTexture:SetAlpha(0.6)
	settingsTexture:SetAllPoints(settingsButton)

	settingsButton.settingsTexture = settingsTexture
	display.settingsButton = settingsButton
	
	display.bars = {}
end

function display:CreateBar(size, fontSize)
	local texture = [[Interface\addons\XanDPS\media\minimalist.tga]]
	local bar = CreateFrame("Statusbar", nil, self)
	bar:SetPoint("LEFT", 1, 0)
	bar:SetPoint("RIGHT", - 1, 0)
	bar:SetStatusBarTexture(texture)
	bar:SetMinMaxValues(0, 100)
	bar:EnableMouse(true)
	bar:SetHeight(size)
	
	--create background
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(texture)
	bg:SetAllPoints(bar)
	bar.bg = bg
	
	--bar:SetScript("OnEnter", )
	--bar:SetScript("OnLeave", )

	--left text
	local left = bar:CreateFontString(nil, "OVERLAY")
	left:SetFont(STANDARD_TEXT_FONT, fontSize)
	left:SetPoint("TOP")
	left:SetPoint("BOTTOM")
	left:SetPoint("LEFT", bar, "LEFT", 5, 0)
	left:SetShadowColor(0, 0, 0, 0.8)
	left:SetShadowOffset(0.8, - 0.8)
	bar.left = left

	local right = bar:CreateFontString(nil, "OVERLAY")
	right:SetFont(STANDARD_TEXT_FONT, fontSize)
	right:SetJustifyH("RIGHT")
	right:SetPoint("TOP")
	right:SetPoint("BOTTOM")
	right:SetPoint("RIGHT", self, "RIGHT", - 5, 0)
	right:SetShadowColor(0, 0, 0, 0.8)
	right:SetShadowOffset(0.8, - 0.8)
	bar.right = right
	
	bar:Hide()
	return bar
end

function display:SetViewStyle(style, session, barHeight, fontSize)
	if not d_modes[style] then return end
	if not c_modes[session] then return end
	
	XanDPS_DB.viewStyle = style
	XanDPS_DB.cSession = session
	XanDPS_DB.barHeight = barHeight or XanDPS_DB.barHeight
	XanDPS_DB.fontSize = fontSize or XanDPS_DB.fontSize

	display.viewStyle = style
	display.cSession = session
	display.barHeight = barHeight or XanDPS_DB.barHeight
	display.fontSize = fontSize or XanDPS_DB.fontSize
	display.header:SetText(L[style])
	display:SetBackdropBorderColor(unpack(d_modes[style].bgcolor))
	display:SetBackdropColor(0, 0, 0, XanDPS_DB.bgOpacity or 0.5)
	viewChange = true
	
	display:UpdateViewStyle()
end

function display:UpdateViewStyle()
	if not d_modes[display.viewStyle] then return end
	if not c_modes[display.cSession] then return end
	if not XanDPS.timechunk then return end
	if not XanDPS.timechunk[display.cSession] then
		display:ClearBars()
		return
	end
	
	local dChk = XanDPS.timechunk[display.cSession]
	
	--do local update check, can't use viewChange as it may possibly be overwritten
	local yUdt = false
	if viewChange then
		yUdt = true
		viewChange = false
	end

	if dChk.units then
		local totalC = 0
		
		for k, v in pairs(dChk.units) do
			totalC = totalC + 1
			if not display.bars[totalC] then
				--we don't have a bar to work with so lets create one
				local bar = display:CreateBar(display.barHeight, display.fontSize)
				table.insert(display.bars, bar)
			end
			local bF = display.bars[totalC]
			--fix display if changed
			if yUdt then
				bF:SetHeight(display.barHeight)
				bF.left:SetFont(STANDARD_TEXT_FONT, display.fontSize)
				bF.right:SetFont(STANDARD_TEXT_FONT, display.fontSize)
			end
			--show all players or display only one bar with the data
			if d_modes[display.viewStyle].showAll then
				--store values (strip the name if name-realm
				if string.match(v.name, "^([^%-]+)%-(.+)$") and XanDPS_DB.stripRealm then
					--returns name, realm
					bF.vName = string.match(v.name, "^([^%-]+)%-(.+)$")
				else
					bF.vName = v.name
				end
				bF.vClass = v.class
			else
				if UnitInRaid("player") then
					bF.vName = L["Raid"]
				elseif GetNumPartyMembers() > 0 then
					bF.vName = L["Party"]
				else
					bF.vName = L["Player"]
				end
				bF.vClass = "raidpartyplayer"
			end
			bF.vGID = v.gid
			--lets use the correct display function from our module
			bF.vValue = tonumber(d_modes[display.viewStyle].func(dChk, v, v.gid)) or 0
			--now lets do class color
			local color = RAID_CLASS_COLORS[bF.vClass] or {r=0.305,g=0.57,b=0.345} --forest green
			bF:SetStatusBarColor(color.r, color.g, color.b)
			bF.bg:SetVertexColor(color.r, color.g, color.b, 0.1)
			
			if not d_modes[display.viewStyle].showAll then
				--exit loop if we are displaying only one item
				break
			end
		end
		
		--remove unused bars
		if #display.bars > totalC then
			--delete from the bottom up
			for i = #display.bars, (totalC + 1), -1 do
				if display.bars[i] then
					display.bars[i]:Hide()
					table.remove(display.bars, i)
				end
			end
		end
		
		if #display.bars > 0 then
			--now lets sort
			table.sort(display.bars, function(a,b) return a.vValue > b.vValue end)
			
			--get the total max bars we can display in the current frame height
			local maxBars = math.floor((display:GetHeight() - 32) / display.barHeight)
			
			--reposition and display according to max number of bars we can display
			for i = 1, #display.bars do
				if i < maxBars then
					display.bars[i].left:SetText(i..". "..display.bars[i].vName)
					display.bars[i].right:SetText(display.bars[i].vValue)
					display.bars[i]:SetPoint("TOP", display, "TOP", 0, ((i - 1) * -display.barHeight) - 32)
					display.bars[i]:Show()
				else
					display.bars[i]:Hide()
				end
			end
		end
		
	end
end

function display:ClearBars()
	if display.bars and #display.bars > 0 then
		for i = #display.bars, 1, -1 do
			if display.bars[i] then
				display.bars[i]:Hide()
				table.remove(display.bars, i)
			end
		end
	end
end

function display:ResetStyleView()
	if display.DD and display.DD:IsShown() then
		CloseDropDownMenus()
	end
	XanDPS:ResetAll()
	display:ClearBars()
end

-------------------
--DROPDOWN FUNCTIONS
-------------------

local function pairsByKeys(t, f)
	local a = {}
		for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
			i = i + 1
			if a[i] == nil then return nil
			else return a[i], t[a[i]]
			end
		end
	return iter
end

function display:setupDropDown()
	--close the dropdown menu if shown
	if display.DD and display.DD:IsShown() then
		CloseDropDownMenus()
	end

	local dd1 = LibStub('LibXMenu-1.0'):New("XanDPS_DropDown", XanDPS_DB)
	dd1.initialize = function(self, lvl)
		if lvl == 1 then
			self:AddTitle(lvl, "XanDPS")
			self:AddList(lvl, L["Combat Session"], "combatsession")
			self:AddList(lvl, L["Data Set"], "dataset")
			self:AddList(lvl, L["Settings"], "settings")
			self:AddCloseButton(lvl,  L["Close"])
		elseif lvl and lvl > 1 then
			local sub = UIDROPDOWNMENU_MENU_VALUE
			if sub == "combatsession" then
				self:AddSelect(lvl, L["Previous"], "previous", "cSession")
				self:AddSelect(lvl, L["Current"], "current", "cSession")
				self:AddSelect(lvl, L["Total"], "total", "cSession")
			elseif sub == "dataset" then
				for k, v in pairsByKeys(x_modules) do
					self:AddList(lvl, L[k], "module-"..k)
				end
			elseif strmatch(sub, "(.-%w)-(%w+)") == "module" then
				local _, modName = strmatch(sub, "(.-%w)-(%w+)")
				if modName then
					for k, v in pairsByKeys(d_modes) do
						if v.module == modName then
							self:AddSelect(lvl, L[v.name], v.name, "viewStyle")
						end
					end
				end
			elseif sub == "settings" then
				self:AddList(lvl, L["Background Opacity"], "bgOpacity")
				self:AddList(lvl, L["Font Size"], "fontSize")
				self:AddList(lvl, L["Bar Height"], "barHeight")
				self:AddToggle(lvl, L["Strip realm from character name"], "stripRealm", nil, nil, nil, 1)
				self:AddToggle(lvl, L["Hide display in Arena/Battleground"], "hideInArenaBG", nil, nil, nil, 2)
				self:AddToggle(lvl, L["Disable in Arena/Battleground"], "disableInArenaBG", nil, nil, nil, 3)
				self:AddToggle(lvl, L["Disable XanDPS"], "disabled", nil, nil, nil, 4)
			elseif sub == "bgOpacity" then
				for i = 0, 1, 0.1 do
					self:AddSelect(lvl, i, i, "bgOpacity")
				end
			elseif sub == "fontSize" then
				for i = 5, 18, 1 do
					self:AddSelect(lvl, i, i, "fontSize")
				end
			elseif sub == "barHeight" then
				for i = 10, 30, 2 do
					self:AddSelect(lvl, i, i, "barHeight")
				end
			end
		end
	end
	dd1.doUpdate = function(bOpt)
		if bOpt and (bOpt >= 2) then
			XanDPS:PLAYER_ENTERING_WORLD()
		else
			self:SetViewStyle(XanDPS_DB.viewStyle, XanDPS_DB.cSession, XanDPS_DB.barHeight, XanDPS_DB.fontSize)
		end
	end
	
	display.DD = dd1
end

-------------------
--POSITION FUNCTIONS
-------------------

function display:SaveLayout(frame)
	if not XanDPS_DB then XanDPS_DB = {} end
	if not XanDPS_DB.Frames then XanDPS_DB.Frames = {} end

	local opt = XanDPS_DB.Frames[frame] or nil;

	if opt == nil then
		XanDPS_DB.Frames[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["PosX"] = 0,
			["PosY"] = 0,
			["width"] = 200,
			["height"] = 250,
		}
		opt = XanDPS_DB.Frames[frame];
	end

	local f = getglobal(frame);
	local scale = f:GetEffectiveScale();
	opt.PosX = f:GetLeft() * scale;
	opt.PosY = f:GetTop() * scale;
	opt.width = f:GetWidth();
	opt.height = f:GetHeight();
end

function display:RestoreLayout(frame)
	if not XanDPS_DB then XanDPS_DB = {} end
	if not XanDPS_DB.Frames then XanDPS_DB.Frames = {} end

	local f = getglobal(frame);
	local opt = XanDPS_DB.Frames[frame] or nil;

	if opt == nil then
		XanDPS_DB.Frames[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["PosX"] = 0,
			["PosY"] = 0,
			["width"] = 200,
			["height"] = 250,
		}
		opt = XanDPS_DB.Frames[frame];
	end

	local x = opt.PosX;
	local y = opt.PosY;
	local s = f:GetEffectiveScale();
	
	f:SetWidth(opt.width)
	f:SetHeight(opt.height)
	
	if (not x or not y) or (x==0 and y==0) then
		f:ClearAllPoints();
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		return 
	end

	--calculate the scale
	x,y = x/s,y/s;

	--set the location
	f:ClearAllPoints();
	f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y);

end

-------------------
--LOAD UP
-------------------

local timerCount = 0
local OnUpdate = function(self, elapsed)
	timerCount = timerCount + elapsed
	if timerCount > 0.5 then
		self:UpdateViewStyle()
		timerCount = 0
	end
end

function display:LoadUP()
	--create our display and then restore the layout from the DB
	display:CreateDisplay()
	display:RestoreLayout(display:GetName())
	--load the initial dropdown
	display:setupDropDown()
	--load saved settings and then setup the viewstyle
	display:SetViewStyle(XanDPS_DB.viewStyle, XanDPS_DB.cSession, XanDPS_DB.barHeight, XanDPS_DB.fontSize)
	--initiate the display timer
	display:SetScript("OnUpdate", OnUpdate)
end
