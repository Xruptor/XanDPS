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

display.viewStyle = "default"
display.cSession = "default"

local function lenTable(t)
	if type(t) ~= "table" then return nil end
    local n=0 
	for key in pairs(t) do
		n = n + 1
	end
	return n
end

function display:Register_Mode(module, name, func, bgcolor)
	d_modes[name] = {["module"] = module, ["name"] = name, ["func"] = func, ["bgcolor"] = bgcolor}
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
	
	display:SetBackdropColor(0, 0, 0, 0.8)
	display:SetBackdropBorderColor(0.48, 0.48, 0.48)
	
	display:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:StartMoving()
		elseif button == "RightButton" then
			--ToggleDropDownMenu(1, nil, display.dropDown, "cursor")
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

function display:SetViewStyle(style, session)
	if not d_modes[style] then return end
	if not c_modes[session] then return end
	
	local barSize = XanDPS_DB.barSize or 16
	local fontSize = XanDPS_DB.fontSize or 12
	display.viewStyle = style
	display.cSession = session
	display.barSize = barSize
	display.fontSize = fontSize
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
			--store values
			bF.vName = v.name
			bF.vClass = v.class
			bF.vGID = v.gid
			--lets use the correct display function from our module
			bF.vValue = d_modes[display.viewStyle].func(dChk, v, v.gid)
			--now lets do class color
			local color = RAID_CLASS_COLORS[v.class] or RAID_CLASS_COLORS["PRIEST"]
			bF:SetStatusBarColor(color.r, color.g, color.b)
			bF.bg:SetVertexColor(color.r, color.g, color.b, 0.1)
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
		
		--now lets sort
		table.sort(display.bars, function(a,b) return a.vValue < b.vValue end)
		
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

function display:PLAYER_LOGIN()
	display:CreateDisplay()
	display:RestoreLayout(display:GetName())
	display:SetViewStyle("Player DPS", "total")
	
	--initiate the display timer
	display:SetScript("OnUpdate", OnUpdate)
	
	display:UnregisterEvent("PLAYER_LOGIN")
	display.PLAYER_LOGIN = nil
end

if IsLoggedIn() then display:PLAYER_LOGIN() else display:RegisterEvent("PLAYER_LOGIN") end