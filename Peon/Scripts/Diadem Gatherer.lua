local Config = {
	GatherSlot = 4,
	ShootMobs = true,
	MobSearchRadius = 20
}

local Zone = require "Enums\\Zone"
local Status = require "Enums\\Status"
local Job = require "Enums\\Job"
local ObjectKind = require "Enums\\ObjectKind"
local Util = require "Libs\\Util"
local UI = require "Libs\\UI"

local function hasIntegrityBonus()
	local integrity = tonumber(GetNodeText("_TargetInfoMainTarget", 3):match("Max GP ≥ %d+ → Gathering Attempts/Integrity %+(%d+)"))
	return integrity and integrity >= 5
end

local function isFullHealth()
	local nodeHealth = GetNodeText("_TargetInfoMainTarget", 7)
	return nodeHealth == " ??"
end

local lastMobFail = -math.huge
while true do
	if not IsInZone(Zone.Diadem) then
		if IsVislandRouteRunning() then
			yield("/visland stop")
		end
		wait(1)
		goto continue
	end

	local jobId = GetClassJobId()
	local isMIN, isBTN = jobId == Job.MIN, jobId == Job.BTN
	if not (isMIN or isBTN) then wait(1) goto continue end

	if not IsAddonVisible("Gathering") then
		if not Config.ShootMobs or GetDiademAetherGaugeBarCount() <= 0 or os.clock() - lastMobFail < 20 then wait(1) goto continue end

		local radius = isBTN and 10 or Config.MobSearchRadius
		local mobs = GetNearbyObjectNames(radius * radius, ObjectKind.BattleNpc)
		for i = 0, mobs.Count - 1 do
			local mobName = mobs[i]
			if mobName and mobName ~= "Corrupted Sprite" and GetObjectHP(mobName) > 0 then
				local isRouteRunning = IsVislandRouteRunning()

				if isRouteRunning then
					yield("/visland pause")
				end
				local hasDismounted = retry(5, function()
					return Util.Dismount()
				end)
				if hasDismounted then
					Util.Target(mobName)
					if not retry(6, function()
						Util.ExecuteActionByName("Duty Action I")
						return GetObjectHP(mobName) <= 0
					end) then
						lastMobFail = os.clock()
						echo("Failed to kill", mobName)
					end
				end
				if isRouteRunning then
					yield("/visland resume")
				end
				break
			end
		end
		wait(0.5)
		goto continue
	end
	if not IsAddonReady("_TargetInfoMainTarget") then wait(0.5) goto continue end
	if not isFullHealth() then goto GatherItem end
	do
		local gp = GetGp()
		if hasIntegrityBonus() and gp >= 500 then
			if HasStatusId({Status.GatheringYieldUp}) then goto GatherItem end

			Util.ExecuteActionByName(isMIN and "King's Yield II" or "Blessed Harvest II")
			wait(0.1)
			goto continue
		elseif gp >= 50 then
			if HasStatusId({Status.GiftOfTheLand, Status.GiftOfTheLand2}) then goto GatherItem end

			local hasEnough = gp >= 100
			if isMIN then
				Util.ExecuteActionByName(hasEnough and "Mountaineer's Gift II" or "Mountaineer's Gift I")
			else
				Util.ExecuteActionByName(hasEnough and "Pioneer's Gift II" or "Pioneer's Gift I")
			end
			wait(0.1)
			goto continue
		end
	end
	::GatherItem::
	UI.GatherItemAtIndex(Config.GatherSlot)
	wait(0.2)
	::continue::
end