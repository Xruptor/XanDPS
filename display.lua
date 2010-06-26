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

function display:Register_Mode(name, func)
	if not d_modes[name] then
		d_modes[name] = {}
	end
	tinsert(d_modes[name], {["func"] = func, ["name"] = name})
end

-------------------
--LOAD UP
-------------------

function display:PLAYER_LOGIN()
	--print(L["poop test"])
	display:UnregisterEvent("PLAYER_LOGIN")
	display = nil
end

if IsLoggedIn() then display:PLAYER_LOGIN() else display:RegisterEvent("PLAYER_LOGIN") end