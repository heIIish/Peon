local Zone = require "Enums\\Zone"
local Util = require "Libs\\Util"
local UI = require "Libs\\UI"

local Positions = {
	TsaiLeve = Vector3(49.20, -15.65, 111.77)
}

local function SelectGuildLeve()
	return UI.Callback("GuildLeve", 13, 10, 1647)
end

local function AcceptGuildLeve()
	return UI.Callback("JournalDetail", 3, 1647)
end

local function CloseGuildLeveAddons()
	return not UI.CloseAddons("GuildLeve", "SelectString")
end

-- logic

while true do
	if not IsInZone(Zone.OldSharlayan) then
		echoError("Not in Old Sharlayan.")
		return
	end

	if GetDistanceToPoint(Positions.TsaiLeve:Unpack()) > 1 then
		Util.MoveTo(Positions.TsaiLeve, true)
		echo("Moving to leve.")
		if not retry(30, function()
			return GetDistanceToPoint(table.unpack(Positions.TsaiLeve)) <= 1 and not PathIsRunning()
		end) then
			echoError("Failed to reach Tsai Leve.")
			return
		end
		PathStop()
	end

	if UI.IsGuildLeveInToDoList("The Mountain Steeped") then
		retry(2, CloseGuildLeveAddons)
		echo("Leve accepted, trying to turn in.")
		retry(1, Util.Target, "Ahldiyrn")
		Util.Interact()
		UI.WaitForAddon("SelectIconString", 1)
		wait(0.1)
		for i = 1, 6 do
			local dialogueText = GetSelectIconStringText(i - 1)
			if dialogueText == "The Mountain Steeped" then
				UI.CallbackList("SelectIconString", i + 1) -- Err... check this sometime
				UI.WaitForAddonClosed("SelectIconString", 3)
				wait(0.25)
				break
			end
		end
		wait(1)
	else
		retry(2, CloseGuildLeveAddons)
		echoDebug("Trying to accept leve.")
		retry(1, Util.Target, "Grigge")
		Util.Interact()
		retry(1, UI.CallbackList, "SelectString", 2)
		retry(1, function() return IsAddonReady("GuildLeve") end)
		wait(0.4)

		local allowances = UI.GetGuildLeveAllowances()

		if not allowances then
			echoError("Failed to get guild leve allowance count.")
			goto continue
		elseif allowances <= 0 then
			echoError("Out of allowances, bye bye.")
			retry(2, CloseGuildLeveAddons)
			return
		end

		-- Check to prevent accidental game crash :skull:
		if UI.IsGuildLeveListVisible() then
			if not UI.IsGuildLeveInGuildLeveList("The Mountain Steeped") then
				echoError("Leve not found in leve menu. Make sure it is visible in the to-do List if you already have it accepted.")
				retry(2, CloseGuildLeveAddons)
				wait(0.5)
				goto continue
			end
		else
			echoError("Leve menu not visible (likely a timing issue).")
			retry(2, CloseGuildLeveAddons)
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