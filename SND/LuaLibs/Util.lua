---@diagnostic disable: lowercase-global

--[[
table.insert(snd.require.paths, string.format("%s\\XIVLauncher\\pluginConfigs\\LuaLibs", os.getenv("APPDATA")))
require "Util"
]]

local f = string.format

local _require = require
_G.require = function(moduleName)
	local value = _require(moduleName)
	if type(value) == "table" then
		local metatable = getmetatable(value)
		if not metatable then
			setmetatable(value, {
				__index = function(self, i)
					error(f("\nAttempt to index %s[\"%s\"], a nil value.", tostring(moduleName), tostring(i)))
				end
			})
		end
	end
	return value
end

local Condition = require "Condition"

local function wait(seconds)
	seconds = seconds or 0
	ArgCheck({seconds, "number"})
	yield("/wait " .. seconds)
end

local function echo(...)
	local args = {...}
	for i = 1, select("#", ...) do
		args[i] = tostring(select(i, ...))
	end
	yield("/e " .. table.concat(args, " "))
end

function echoError(...)
	local args = {...}
	table.insert(args, "<se.11>")
	echo(table.unpack(args))
end

local function ArgCheck(...)
	local bad = false
	for i = 1, select("#", ...) do
		local argData = select(i, ...)
		local arg, expectedType = table.unpack(argData)
		local argType = type(arg)
		if argType ~= expectedType then
			bad = true
			break
		end
	end

	if bad then
		local argTypes = {}
		local expectedTypes = {}
		for i = 1, select("#", ...) do
			local argData = select(i, ...)
			local arg, expectedType = table.unpack(argData)
			local argType = type(arg)
			table.insert(argTypes, argType)
			table.insert(expectedTypes, expectedType)
		end

		local callerInfo = debug.getinfo(2)
		local callerName = callerInfo and callerInfo.name or "[none]"
		local traceback = debug.traceback(nil, 2):gsub("\n[^\n]*$", ""):gsub("^[^\n]*\n", "")
		error(f("\nWrong arg type when calling \"%s(%s)\"\n%sexpected \"%s(%s)\"\n%s", callerName, table.concat(argTypes, ", "), string.rep(" ", 36), callerName, table.concat(expectedTypes, ", "), traceback), 2)
	end
end

local calls = 0
function retry(timeout, func, ...)
	calls = calls + 1
	ArgCheck({timeout, "number"}, {func, "function"})
	local start = os.clock()
	local success = false
	repeat
		success = func(...)
		wait(0.1)
	until success or os.clock() - start >= timeout

	if not success then
		echo("retry for function " .. (debug.getinfo(func).name or tostring(calls)) .. " timed out")
	end

	return success
end

function Call(paramString)
	ArgCheck({paramString, "string"})
	yield("/pcallback " .. paramString)
end

function Target(name)
	ArgCheck({name, "string"})
	if GetTargetName():lower()  == name:lower() then
		return true
	else
		yield("/target " .. name)
		if GetTargetName():lower()  == name:lower() then
			return true
		end
	end
end

function Interact()
	yield("/pinteract")
end

function IsMounted()
	return GetCharacterCondition(Condition.Mounted)
end

function Mount(name)
	if not IsPlayerAvailable() or GetCharacterCondition(Condition.Casting) then return end
	if IsMounted() then return true end
	name = name or "Megaloambystoma"
	yield("/mount " .. name)
end

function Dismount()
	if not IsMounted() then return true end
	ExecuteActionByName("Dismount")
end

function CopyTargetCoordinates()
	local x, y, z = GetTargetRawXPos(), GetTargetRawYPos(), GetTargetRawZPos()
	SetClipboard(string.format("%s, %s, %s", tostring(x), tostring(y), tostring(z)))
end

function IsDialogueMenuVisible()
	return IsAddonVisible("SelectIconString")
end
function IsDialogueMenuReady()
	return IsAddonReady("SelectIconString")
end
function IsDialogueSubMenuVisible()
	return IsAddonVisible("SelectString")
end
function IsShopExchangeVisible()
	return IsAddonVisible("ShopExchangeItem")
end
function IsRequestVisible()
	return IsAddonVisible("Request")
end
function IsGathering()
	return IsAddonVisible("Gathering")
end
function IsGuildLeveMenuVisible()
	return IsAddonVisible("GuildLeve")
end
function IsGuildLeveMenuReady()
	return IsAddonReady("GuildLeve")
end

function IsGuildLeveInToDoList(name)
	ArgCheck({name, "string"})
	for i = 8, 12 do
		if GetNodeText("_ToDoList", {i, 11}) == name then
			return true
		end
	end
end

function IsGuildLeveListVisible()
	return IsGuildLeveMenuVisible() and IsNodeVisible("GuildLeve", 11)
end

function IsGuildLeveInNodeList(name)
	if not IsGuildLeveListVisible() then return end
	for i = 40, 60 do
		if GetNodeText("GuildLeve", {11, i, 4}) == name then
			return true
		end
	end
end

function GetGuildLeveAllowances()
	if not IsGuildLeveMenuVisible() then return end
	if not IsNodeVisible("GuildLeve", 5) then return end
	return tonumber(GetNodeText("GuildLeve", 5, 2))
end

function GatherItemAtIndex(index)
	ArgCheck({index, "number"})
	if IsGathering() then
		Call("Gathering true " .. (index - 1))
		return true
	end
end

function IsInteracting()
	return IsDialogueMenuVisible() or IsDialogueSubMenuVisible() or IsShopExchangeVisible()
end

function IsInteractingWith(name)
	return GetTargetName():lower() == name:lower() and IsInteracting()
end

function SelectDialogueMenuOption(index)
	ArgCheck({index, "number"})
	if not IsDialogueMenuVisible() then return end
	Call("SelectIconString true " .. (index - 1))
	return true
end

function SelectDialogueSubMenuOption(index)
	ArgCheck({index, "number"})
	if not IsDialogueSubMenuVisible() then return end
	Call("SelectString true " .. (index - 1))
	return true
end

function ShopExchangeItem(itemShopIndex, amount)
	ArgCheck({itemShopIndex, "number"}, {amount, "number"})
	if not IsShopExchangeVisible() then return end
	Call("ShopExchangeItem true 0 " .. (itemShopIndex - 1) .. " " .. amount)
	return IsRequestVisible()
end

function CloseDialogueMenu()
	if not IsDialogueMenuVisible() then return true end
	Call("SelectIconString true -1")
	return true
end

function CloseDialogueSubMenu()
	if not IsDialogueSubMenuVisible() then return true end
	Call("SelectString true -1")
	return true
end

function CloseShopExchange()
	if not IsShopExchangeVisible() then return true end
	Call("ShopExchangeItem true -1")
	return true
end

function CloseRequest()
	if not IsRequestVisible() then return true end
	Call("Request true -1")
	return true
end

function CloseGuildLeveMenu()
	if IsGuildLeveMenuVisible() then
		Call("GuildLeve true -1")
	end
	return true
end

function MoveTo(position, usePathfinding, useVolume)
	ArgCheck({position, "table"})
	local x, y, z = table.unpack(position)
	assert(x ~= nil and y ~= nil and z ~= nil, f("MoveTo position vector is invalid. (%s, %s, %s)", tostring(x), tostring(y), tostring(z)))
	useVolume = not not useVolume -- Retarded plogon
	if usePathfinding then
		PathfindAndMoveTo(x, y, z, useVolume)
	else
		-- What is the point of the 4th param if PathMoveTo just moves in a straight line?
		PathMoveTo(x, y, z, useVolume)
	end
end

function ExecuteActionByName(name)
	ArgCheck({name, "string"})
	yield("/ac \"" .. name .. "\"")
end

_G.echo = echo
_G.ArgCheck = ArgCheck
_G.wait = wait