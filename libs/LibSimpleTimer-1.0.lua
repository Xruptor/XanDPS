--[[----------------------------------------------------------------------------
Name: LibSimpleTimer-1.0.lua
Description: A simple timer
Revision: $Revision: 32 $
Author: Whitetooth
Email: hotdogee [at] gmail [dot] com
Credits: Dongle Development Team
Encoding: UTF-8
Features:
* Schedule/Cancel one-time or repeating timer by id.
* Able to schedule a timer without any callback. Why? Used with :IsTimerScheduled(id) for checks
* Able to overwrite existing timer.
* Fast OnUpdate utilizing a heap.
* Embedable.
------------------------------------------------------------------------------]]

local MAJOR_VERSION = "LibSimpleTimer-1.0"
local MINOR_VERSION = 90000 + tonumber(("$Revision: 32 $"):match("%d+"))
local SimpleTimer, oldMinor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)

if not SimpleTimer then return end -- No upgrade needed

--------------------------------------------------------------------------------
-- Base code taken from Dongle, sightly modified
--------------------------------------------------------------------------------

SimpleTimer.timers = SimpleTimer.timers or {}
SimpleTimer.heap = SimpleTimer.heap or {}
SimpleTimer.frame = SimpleTimer.frame or CreateFrame("Frame", "SimpleTimer10Frame")

local timers = SimpleTimer.timers
local heap = SimpleTimer.heap
local frame = SimpleTimer.frame

local GetTime = GetTime
local pairs = pairs
local unpack = unpack
local floor = floor
local select = select
local type = type
local error = error
local strjoin = strjoin
local debugstack = debugstack
local strmatch = strmatch
local format = format
local pcall = pcall
local geterrorhandler = geterrorhandler

local function argcheck(value, num, ...)
	if type(num) ~= "number" then
		error(("bad argument #%d to '%s' (%s expected, got %s)"):format(2, "argcheck", "number", type(num)), 1)
	end

	for i=1,select("#", ...) do
		if type(value) == select(i, ...) then return end
	end

	local types = strjoin(", ", ...)
	local name = strmatch(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(("bad argument #%d to '%s' (%s expected, got %s)"):format(num, name, types, type(value)), 3)
end

local function safecall(func,...)
	local success,err = pcall(func,...)
	if not success then
		geterrorhandler()(err)
	end
end

local function HeapBubbleUp(index)
	while index > 1 do
		local parentIndex = floor(index / 2)
		if heap[index].timeToFire < heap[parentIndex].timeToFire then
			heap[index], heap[parentIndex] = heap[parentIndex], heap[index]
			index = parentIndex
		else
			break
		end
	end
end

local function HeapBubbleDown(index)
	while 2 * index <= heap.lastIndex do
		local leftIndex = 2 * index
		local rightIndex = leftIndex + 1
		local current = heap[index]
		local leftChild = heap[leftIndex]
		local rightChild = heap[rightIndex]

		if not rightChild then
			if leftChild.timeToFire < current.timeToFire then
				heap[index], heap[leftIndex] = heap[leftIndex], heap[index]
				index = leftIndex
			else
				break
			end
		else
			if leftChild.timeToFire < current.timeToFire or
			   rightChild.timeToFire < current.timeToFire then
				if leftChild.timeToFire < rightChild.timeToFire then
					heap[index], heap[leftIndex] = heap[leftIndex], heap[index]
					index = leftIndex
				else
					heap[index], heap[rightIndex] = heap[rightIndex], heap[index]
					index = rightIndex
				end
			else
				break
			end
		end
	end
end

local function OnUpdate()
	local schedule = heap[1]
	while schedule and schedule.timeToFire < GetTime() do
		if schedule.cancelled then
			local last = heap.lastIndex
			heap[1], heap[last] = heap[last], heap[1]
			heap[heap.lastIndex] = nil
			heap.lastIndex = heap.lastIndex - 1
			HeapBubbleDown(1)
		else
			if schedule.func then
				if schedule.args then
					safecall(schedule.func, unpack(schedule.args))
				else
					safecall(schedule.func)
				end
			end

			if schedule.repeating then
				schedule.timeToFire = schedule.timeToFire + schedule.repeating
				HeapBubbleDown(1)
			else
				local last = heap.lastIndex
				heap[1], heap[last] = heap[last], heap[1]
				heap[heap.lastIndex] = nil
				heap.lastIndex = heap.lastIndex - 1
				HeapBubbleDown(1)
				timers[schedule.name] = nil
			end
		end
		schedule = heap[1]
	end
	if not schedule then frame:Hide() end
end
frame:SetScript("OnUpdate", OnUpdate)

--------------------------------------------------------------------------------
-- :ScheduleTimer(name, func, delay, ...)
-- Notes:
-- * Schedule a timer to expire in delay seconds at which point it will call the callback func. name is an identifier for this timer.
-- * If you try to schedule a timer with the same name a second time, the old schedule will be overwritten.
-- Arguments:
--   name (variant) - The name of the timer to be scheduled. You can use this name to check if this timer's status and/or cancel it.
--   func (function or nil) - A function to be called when the timer expires, can be nil.
--   delay (number) - The number of seconds it takes for this timer to expire.
--   ... - Any additional arguments to pass to the callback.
-- Callback Signature:
--   func(...)
-- Example:
--   :ScheduleTimer("EncounterEnd", self.EncounterEnd, 10, self, 10)
--   :ScheduleTimer("EncounterEnd", nil, 10) -- why? used with :IsTimerScheduled("EncounterEnd")
--------------------------------------------------------------------------------
function SimpleTimer:ScheduleTimer(name, func, delay, ...)
	argcheck(self, 1, "table")
	argcheck(func, 3, "function", "nil")
	argcheck(delay, 4, "number")

	if SimpleTimer:IsTimerScheduled(name) then
		SimpleTimer:CancelTimer(name)
	end

	local schedule = {}
	timers[name] = schedule
	schedule.timeToFire = GetTime() + delay
	schedule.func = func
	schedule.name = name
	if select('#', ...) ~= 0 then
		schedule.args = { ... }
	end

	if heap.lastIndex then
		heap.lastIndex = heap.lastIndex + 1
	else
		heap.lastIndex = 1
	end
	heap[heap.lastIndex] = schedule
	HeapBubbleUp(heap.lastIndex)
	if not frame:IsShown() then
		frame:Show()
	end
end

--------------------------------------------------------------------------------
-- :ScheduleRepeatingTimer(name, func, delay, ...)
-- Notes:
-- * Schedule a repeating timer that expires every delay seconds.
-- * If you try to schedule a timer with the same name a second time, the old schedule will be overwritten.
-- Arguments:
--   name (variant) - The name of the timer to be scheduled. You can use this name to check if this timer's status and/or cancel it.
--   func (function) - A function to be called when the timer expires.
--   delay (number) - The number of seconds it takes for this timer to expire.
--   ... - Any additional arguments to pass to the callback.
-- Callback Signature:
--   func(...)
--------------------------------------------------------------------------------
function SimpleTimer:ScheduleRepeatingTimer(name, func, delay, ...)
	argcheck(func, 3, "function")
	SimpleTimer:ScheduleTimer(name, func, delay, ...)
	timers[name].repeating = delay
end

--------------------------------------------------------------------------------
-- :IsTimerScheduled(name)
-- Notes:
-- * Returns if the timer with the name specified is scheduled or not and also returns the time remaining for it to expire.
-- Arguments:
--   name (variant) - The name of the timer to query.
-- Returns:
--   nil - if the timer is not scheduled. 
--   true, seconds (number) - if the timer is scheduled. seconds is the number of seconds required for the timer to expire. 
--------------------------------------------------------------------------------
function SimpleTimer:IsTimerScheduled(name)
	argcheck(self, 1, "table")
	local schedule = timers[name]
	if schedule then
		return true, schedule.timeToFire - GetTime()
	end
end

--------------------------------------------------------------------------------
-- :CancelTimer(name)
-- Notes:
-- * Cancels the timer scheduled with name.
-- Arguments:
--   name (variant) - The name of the timer to cancel.
--------------------------------------------------------------------------------
function SimpleTimer:CancelTimer(name)
	argcheck(self, 1, "table")
	local schedule = timers[name]
	if not schedule then return end
	schedule.cancelled = true
	timers[name] = nil
end

--------------------------------------------------------------------------------
-- Embed handling
--------------------------------------------------------------------------------
SimpleTimer.embeds = SimpleTimer.embeds or {}

local mixins = {
	"ScheduleTimer", "ScheduleRepeatingTimer", "IsTimerScheduled", "CancelTimer",
}

--------------------------------------------------------------------------------
-- :Embed(target)
-- Notes:
-- * Embeds "ScheduleTimer", "ScheduleRepeatingTimer", "IsTimerScheduled", "CancelTimer"
-- Arguments:
--   target (table) - The table with which to export methods onto.
-- Returns:
-- 	The table provided, after embedding.
--------------------------------------------------------------------------------
function SimpleTimer:Embed(target)
	SimpleTimer.embeds[target] = true
	for _, v in pairs(mixins) do
		target[v] = SimpleTimer[v]
	end
	return target
end

for addon in pairs(SimpleTimer.embeds) do
	SimpleTimer:Embed(addon)
end
