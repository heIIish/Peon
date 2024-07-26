local PEON_DIR = os.getenv("APPDATA") .. "\\XIVLauncher\\pluginConfigs\\Peon\\"
local SCRIPTS_DIR = PEON_DIR .. "Scripts\\"
local REQUIRE_PATHS = snd.require.paths
table.insert(REQUIRE_PATHS, PEON_DIR .. "Core\\")

local Vector3 = require "Classes\\Vector3"
local Debug = require "Libs\\Debug"

local entrypointLineOffset = 0

local _require = require
function require(moduleName)
	local value = _require(moduleName)
	if type(value) == "table" then
		local metatable = getmetatable(value)
		if not metatable then
			setmetatable(value, {
				__index = function(self, i)
					error(string.format("\nAttempt to index %s[\"%s\"], a nil value.", tostring(moduleName), tostring(i)))
				end
			})
		end
	end
	return value
end

function typeof(value)
	local t = type(value)
	if t == "table" then
		local __type = rawget(value, "__type")
		if __type ~= nil then
			return __type
		end
	end
	return t
end

-- Lowest interval seems to be 0.001s which actually waits for 0.0015s (?)
local minWait = 0.001
function wait(seconds)
	if seconds == nil then
		seconds = minWait
	else
		ArgCheck({seconds, "number"})
		seconds = math.max(seconds, minWait)
	end
	yield("/wait " .. seconds)
end

function echo(...)
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

function echoDebug(formatString, ...)
	if Debug.GetMode() == nil then return end
	echo("[DEBUG]", string.format(formatString, ...))
end

function ArgCheck(...)
	local bad = false
	for i = 1, select("#", ...) do
		local argData = select(i, ...)
		local arg, expectedType = table.unpack(argData)
		local argType = typeof(arg)
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
			local argType = typeof(arg)
			table.insert(argTypes, argType)
			table.insert(expectedTypes, expectedType)
		end

		local callerName = debug.getinfo(2, "n").name or "[none]"
		local traceback = debug.traceback(nil, 2):gsub("\n[^\n]*$", ""):gsub("^[^\n]*\n", "")
		error(string.format("\nWrong arg type when calling \"%s(%s)\"\n%sexpected \"%s(%s)\"\n%s", callerName, table.concat(argTypes, ", "), string.rep(" ", 36), callerName, table.concat(expectedTypes, ", "), traceback), 2)
	end
end

function Call(...)
	local args = {...}
	for i = 1, select("#", ...) do
		args[i] = tostring(select(i, ...))
	end
	yield("/pcallback " .. table.concat(args, " "))
end

function retryWait(timeout, waitTime, func, ...)
	ArgCheck({timeout, "number"}, {func, "function"})
	local start = os.clock()
	local success = false
	repeat
		success = func(...)
		if not success then
			wait(waitTime)
		end
	until success or os.clock() - start >= timeout

	if not success and Debug.GetMode() == "VERBOSE" then
		local functionName = Debug.GetFunctionName(func)
		local lineNumber = debug.getinfo(2).currentline - entrypointLineOffset
		echoDebug("Retry for %s timed out. (Line %d)", (functionName and "function \"" .. functionName .. "\"" or "unnamed function"), lineNumber)
	end

	return success
end

local retryDelta = 1 / 200
function retry(timeout, func, ...)
	return retryWait(timeout, retryDelta, func, ...)
end

_G.Vector3 = Vector3
_G.Peon = true

local function getfenv(func)
	local level = 1
    repeat
      local name, value = debug.getupvalue(func, level)
      if name == '_ENV' then return value end
      level = level + 1
    until name == nil
end

return function(scriptName)
	local scriptFolderPath = SCRIPTS_DIR .. scriptName
	local scriptFunction = loadfile(scriptFolderPath .. "\\source.lua")
	if scriptFunction then
		local configFunction = loadfile(scriptFolderPath .. "\\config.lua")
		if configFunction then
			getfenv(scriptFunction).Configuration = configFunction()
		end
		table.insert(REQUIRE_PATHS, scriptFolderPath)
		scriptFunction()
	else
		error(string.format("Failed to find script file \"%s\" in Scripts directory.", scriptName), 2)
	end
end