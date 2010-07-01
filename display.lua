--[[----------------------------------------------------------------------------
Name: XanDPS_Display
Description: The display module for XanDPS
Author: Xruptor
Email: private message (PM) me at wowinterface.com
------------------------------------------------------------------------------]]
local L = XanDPS_L
local viewChange = false
local d_modes = {}
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

function display:Register_Mode(module, name, func, bgcolor, showAll)
	d_modes[name] = {["module"] = module, ["name"] = name, ["func"] = func, ["bgcolor"] = bgcolor, ["showAll"] = showAll}
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
	
	display:SetBackdropColor(0, 0, 0, 0.5)
	display:SetBackdropBorderColor(0.48, 0.48, 0.48)
	
	display:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:StartMoving()
		elseif button == "RightButton" then
			--ToggleDropDownMenu(1, nil, display.DD, "cursor")
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

function display:SetViewStyle(style, session, barSize, fontSize)
	if not d_modes[style] then return end
	if not c_modes[session] then return end
	
	XanDPS_DB.viewStyle = style
	XanDPS_DB.cSession = session
	XanDPS_DB.barSize = barSize or XanDPS_DB.barSize
	XanDPS_DB.fontSize = fontSize or XanDPS_DB.fontSize

	display.viewStyle = style
	display.cSession = session
	display.barSize = barSize or XanDPS_DB.barSize
	display.fontSize = fontSize or XanDPS_DB.fontSize
	display.header:SetText(L[style])
	display:SetBackdropBorderColor(unpack(d_modes[style].bgcolor))
	viewChange = true
end

function display:UpdateViewStyle()
	if not d_modes[display.viewStyle] then return end
	if not c_modes[display.cSession] then return end
	if not XanDPS.timechunk then return end
	if not XanDPS.timechunk[display.cSession] then return end
	
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
				local bar = display:CreateBar(display.barSize, display.fontSize)
				table.insert(display.bars, bar)
			end
			local bF = display.bars[totalC]
			--fix display if changed
			if yUdt then
				bF:SetHeight(display.barSize)
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
			--exit loop if we are displaying only one item
			if not d_modes[display.viewStyle].showAll then
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
			local maxBars = math.floor((display:GetHeight() - 32) / display.barSize)
			
			--reposition and display according to max number of bars we can display
			for i = 1, #display.bars do
				if i < maxBars then
					display.bars[i].left:SetText(i..". "..display.bars[i].vName)
					display.bars[i].right:SetText(display.bars[i].vValue)
					display.bars[i]:SetPoint("TOP", display, "TOP", 0, ((i - 1) * -display.barSize) - 32)
					display.bars[i]:Show()
				else
					display.bars[i]:Hide()
				end
			end
		end
		
	end
end

function display:ResetStyleView()
	if display.DD and display.DD:IsShown() then
		CloseDropDownMenus()
	end
	XanDPS:ResetAll()
	if display.bars and #display.bars > 0 then
		for i = #display.bars, 1, -1 do
			if display.bars[i] then
				display.bars[i]:Hide()
				table.remove(display.bars, i)
			end
		end
	end
end

-------------------
--DROPDOWN FUNCTIONS
-------------------

function display:setupDropDown()
	--close the dropdown menu if shown
	if display.DD and display.DD:IsShown() then
		CloseDropDownMenus()
	end
	
	local DD = CreateFrame("Frame", "XanDPS_DropDown", UIParent, "UIDropDownMenuTemplate")
	
	local tmpD = {}

	for k, v in pairs(d_modes) do
		table.insert(tmpD, {
				text = L[v.name],
				owner = DD,
				arg1 = v.name,
				arg2 = v.module,
				checked = function() return self.viewStyle == v.name end,
				func = function(drop, arg1, arg2)
					self:SetViewStyle(arg1, self.cSession or "total")
					CloseDropDownMenus()
				end,
			}
		)
	end
	
	--sort it by name
	table.sort(tmpD, function(a,b) return a.text < b.text end)
	
	display.menuTable = {
		{
			{
				text = "XanDPS",
				owner = DD,
				isTitle = true,
				notCheckable = true,
			}, {
				text = L["Combat Session"],
				owner = DD,
				hasArrow = true,
				notCheckable = true,
				menuList = {
					{
						text = L["Previous"],
						owner = DD,
						checked = function() return self.cSession == "previous" end,
						func = function(drop)
							self:SetViewStyle(self.viewStyle, "previous")
						end,
					}, {
						text = L["Current"],
						owner = DD,
						checked = function() return self.cSession == "current" end,
						func = function(drop)
							self:SetViewStyle(self.viewStyle, "current")
						end,
					}, {
						text = L["Total"],
						owner = DD,
						checked = function() return self.cSession == "total" end,
						func = function(drop)
							self:SetViewStyle(self.viewStyle, "total")
						end,
					},
				},
			}, {
				text = L["Data Type"],
				owner = dd,
				hasArrow = true,
				notCheckable = true,
				menuList = tmpD,
			}, {
				text = L["Close"],
				owner = DD,
				func = function() CloseDropDownMenus() end,
				notCheckable = true,
			}
		},
	}

	UIDropDownMenu_Initialize(DD, function(frame, level, list)
		if not (list or self.menuTable[level]) then return end
		for k, v in ipairs(list or self.menuTable[level]) do
			v.value = k
			UIDropDownMenu_AddButton(v, level)
		end
	end, "MENU", 1)
	
	display.DD = DD
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
	display:SetViewStyle(XanDPS_DB.viewStyle, XanDPS_DB.cSession, XanDPS_DB.barSize, XanDPS_DB.fontSize)
	--initiate the display timer
	display:SetScript("OnUpdate", OnUpdate)
end

