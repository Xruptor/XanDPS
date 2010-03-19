--[[----------------------------------------------------------------------------
Name: XanDPS_Damge
Description: A damage module for the XanDPS mod.
Author: Xruptor
Email: private message (PM) me at wowinterface.com
Credits: zarnivoop for his work on Skada
------------------------------------------------------------------------------]]

local module_name = "XanDPS_Damge"
local module, oldminor = LibStub:NewLibrary(module_name, 1)
if not module then return end

-------------------
--LOAD UP
-------------------
local fd = CreateFrame("Frame", (module_name.."_Frame"), UIParent)
fd:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

function fd:PLAYER_LOGIN()
	print('woooooot')
	fd:UnregisterEvent("PLAYER_LOGIN")
	fd = nil
end
if IsLoggedIn() then fd:PLAYER_LOGIN() else fd:RegisterEvent("PLAYER_LOGIN") end