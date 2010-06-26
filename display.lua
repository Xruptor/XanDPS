--[[----------------------------------------------------------------------------
Name: XanDPS_Display
Description: The display module for XanDPS
Author: Xruptor
Email: private message (PM) me at wowinterface.com
------------------------------------------------------------------------------]]
local L = XanDPS_L

local display = CreateFrame("Frame", "XanDPS_Display", UIParent)
display:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local d_modes = {}

function display:Register_Mode(name, func, bgcolor)
	if not d_modes[name] then
		d_modes[name] = {}
	end
	tinsert(d_modes[name], {["func"] = func, ["name"] = name, ["bgcolor"] = bgcolor})
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
	header:SetFont(STANDARD_TEXT_FONT, 16)
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
end

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
	
	if not x or not y then
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

function display:PLAYER_LOGIN()
	--print(L["test"])
	
	display:CreateDisplay()
	display:RestoreLayout(display:GetName())
	
	display:UnregisterEvent("PLAYER_LOGIN")
	display.PLAYER_LOGIN = nil
end

if IsLoggedIn() then display:PLAYER_LOGIN() else display:RegisterEvent("PLAYER_LOGIN") end