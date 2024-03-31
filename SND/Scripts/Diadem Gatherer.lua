table.insert(snd.require.paths, string.format("%s\\XIVLauncher\\pluginConfigs\\LuaLibs", os.getenv("APPDATA")))
require "Util"

local Config = {
	GatherSlot = 4,
	ShootMobs = true
}

local Zone = require "Zone"
local Status = require "Status"
local Job = require "Job"
local ObjectKind = require "ObjectKind"

local function hasIntegrityBonus()
	if IsNodeVisible("_TargetInfoMainTarget", 3) then
		local integrity = tonumber(GetNodeText("_TargetInfoMainTarget", 3):match("Max GP ≥ %d+ → Gathering Attempts/Integrity %+(%d+)"))
		return integrity and integrity >= 5
	end
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
	if not IsGathering() then
		if not Config.ShootMobs or GetDiademAetherGaugeBarCount() <= 0 or os.clock() - lastMobFail < 20 then wait(1) goto continue end
		local mobs = GetNearbyObjectNames(22 * 22, ObjectKind.BattleNpc)
		for i = 0, mobs.Count - 1 do
			local mobName = mobs[i]
			if mobName and mobName ~= "Corrupted Sprite" and GetObjectHP(mobName) > 0 then
				local isRouteRunning = IsVislandRouteRunning()

				if isRouteRunning then
					yield("/visland pause")
				end
				local hasDismounted = retry(5, function()
					return Dismount()
				end)
				if hasDismounted then
					Target(mobName)
					if not retry(6, function()
						ExecuteActionByName("Duty Action I")
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
		goto continue
	end
	if not IsAddonReady("_TargetInfoMainTarget") then wait(0.5) goto continue end

	local jobId = GetClassJobId()
	local isMIN, isBTN = jobId == Job.MIN, jobId == Job.BTN
	if not (isMIN or isBTN) then wait(1) goto continue end

	local gp = GetGp()
	if hasIntegrityBonus() and gp >= 500 then
		if HasStatusId({Status.GatheringYieldUp}) then goto GatherItem end

		ExecuteActionByName(isMIN and "King's Yield II" or "Blessed Harvest II")
		wait(0.1)
		goto continue
	elseif gp >= 50 then
		if HasStatusId({Status.GiftOfTheLand, Status.GiftOfTheLand2}) then goto GatherItem end

		local hasEnough = gp >= 100
		if isMIN then
			ExecuteActionByName(hasEnough and "Mountaineer's Gift II" or "Mountaineer's Gift I")
		else
			ExecuteActionByName(hasEnough and "Pioneer's Gift II" or "Pioneer's Gift I")
		end
		wait(0.1)
		goto continue
	end
	::GatherItem::
	GatherItemAtIndex(Config.GatherSlot)
	wait(0.2)
	::continue::
end