-- Tsai leve turn-in 

table.insert(snd.require.paths, string.format("%s\\XIVLauncher\\pluginConfigs\\LuaLibs", os.getenv("APPDATA")))
require "Util"

local Zone = require "Zone"

local Positions = {
	TsaiLeve = {49.20, -15.65, 111.77}
}

local function SelectGuildLeve()
	if IsGuildLeveMenuVisible() then
		Call("GuildLeve true 13 10 1647")
		return true
	end
end

local function AcceptGuildLeve()
	if IsGuildLeveMenuVisible() then
		Call("JournalDetail true 3 1647")
		return true
	end
end

local function CloseAllMenus()
	CloseGuildLeveMenu()
	CloseDialogueSubMenu()
	return not (IsGuildLeveMenuVisible() or IsDialogueSubMenuVisible())
end

-- logic

while true do
	if not IsInZone(Zone.OldSharlayan) then
		echoError("Not in Old Sharlayan.")
		return
	end

	if GetDistanceToPoint(table.unpack(Positions.TsaiLeve)) > 1 then
		yield("/vnavmesh moveto " .. table.concat(Positions.TsaiLeve, " "))
		echo("Moving to leve.")
		if not retry(30, function()
			return GetDistanceToPoint(table.unpack(Positions.TsaiLeve)) <= 1 and not PathIsRunning()
		end) then
			echoError("Failed to reach Tsai Leve.")
			return
		end
		yield("/vnavmesh stop")
	end

	if IsGuildLeveInToDoList("The Mountain Steeped") then
		retry(2, CloseAllMenus)
		echo("Leve accepted, trying to turn in.")
		retry(1, Target, "Ahldiyrn")
		Interact()
		retry(1, IsDialogueMenuVisible)
		wait(0.1)
		for i = 0, 5 do
			local dialogueText = GetSelectIconStringText(i)
			if dialogueText == "The Mountain Steeped" then
				SelectDialogueMenuOption(i + 1)
				retry(3, function() return not IsDialogueMenuVisible() end)
				wait(0.25)
				break
			end
		end
		wait(1)
	else
		retry(2, CloseAllMenus)
		echo("Trying to accept leve.")
		retry(1, Target, "Grigge")
		Interact()
		retry(1, SelectDialogueSubMenuOption, 2)
		retry(1, IsGuildLeveMenuReady)
		wait(0.4)

		local allowances = GetGuildLeveAllowances()

		if not allowances then
			echoError("Failed to get guild leve allowance count.")
			goto continue
		elseif allowances <= 0 then
			echoError("Out of allowances, bye bye.")
			retry(2, CloseAllMenus)
			return
		end

		-- Check to prevent accidental game crash :skull:
		if IsGuildLeveListVisible() then
			if not IsGuildLeveInNodeList("The Mountain Steeped") then
				echoError("Leve not found in leve menu. Make sure it is visible in the to-do List if you already have it accepted.")
				retry(2, CloseAllMenus)
				wait(0.5)
				goto continue
			end
		else
			echoError("Leve menu not visible (likely a timing issue).")
			retry(2, CloseAllMenus)
			wait(0.5)
			goto continue
		end

		retry(1, SelectGuildLeve)
		wait(0.1)
		AcceptGuildLeve()
		wait(0.5)
	end
	::continue::
end