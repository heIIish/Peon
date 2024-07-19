local Debug = {}

local enableDebugging = false
local functionNames = {}

local debugMode
local function setDebugMode(mode)
	debugMode = mode
	if not enableDebugging then return end

	-- Stupid hack since I can't figure out how to get func name at func pointer
	for i, v in pairs(_G) do
		if type(v) == "function" then
			functionNames[v] = i
		end
	end

	local i = 1
	while true do
		local n, v = debug.getlocal(3, i)
		if not n then break end
		if type(v) == "function" and not functionNames[v] then
			functionNames[v] = n
		end
		i = i + 1
	end
end

function Debug.Enable()
	setDebugMode("DEFAULT")
end

function Debug.EnableVerbose()
	setDebugMode("VERBOSE")
end

function Debug.Disable()
	setDebugMode()
end

function Debug.GetMode()
	return debugMode
end

function Debug.GetFunctionName(func)
	return functionNames[func]
end

return Debug