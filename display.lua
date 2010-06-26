--[[----------------------------------------------------------------------------
Name: XanDPS_Display
Description: The display module for XanDPS
Author: Xruptor
Email: private message (PM) me at wowinterface.com
------------------------------------------------------------------------------]]

local display = CreateFrame("Frame", "XanDPS_Display", UIParent)
display:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

function display:Register_Mode(func, event, flags)
	if not CL_events[event] then
		CL_events[event] = {}
	end
	tinsert(CL_events[event], {["func"] = func, ["flags"] = flags})
end

-------------------
--LOAD UP
-------------------

function display:PLAYER_LOGIN()

	display:UnregisterEvent("PLAYER_LOGIN")
	display = nil
end

if IsLoggedIn() then display:PLAYER_LOGIN() else display:RegisterEvent("PLAYER_LOGIN") end