local Job = require "Enums\\Job"
local Condition = require "Enums\\Condition"
local ObjectKind = require "Enums\\ObjectKind"
local Util = require "Libs\\Util"

local bossName = "Halicarnassus"

local gapclosers = {
	[Job.DRK] = "Shadowstride"
}

local function useGapcloser()
	local gapcloser = gapclosers[GetClassJobId()]
	if not gapcloser then return end
	Util.ExecuteActionByName(gapcloser)
end

while true do
	if GetCharacterCondition(Condition.BetweenAreas)
		or GetCharacterCondition(Condition.OccupiedInQuestEvent)
		or GetCharacterCondition(Condition.OccupiedInCutSceneEvent) then
		wait(1)
		goto continue
	end

	if not GetCharacterCondition(Condition.BoundByDuty) then
		yield("/send U")
		echoDebug("Toggled contents finder.")
		wait(2)
		goto continue
	end

	if Configuration.AutoRepair and not GetCharacterCondition(Condition.InCombat) then
		Util.Repair(99)
	end

	if DoesObjectExist(bossName) and GetObjectHP(bossName) > 0 then
		while not Util.Target(bossName) do
			wait(0.2)
		end

		local backVector = -Util.GetTargetForwardVector()
		local targetPosition = Util.GetTargetPosition()
		if not targetPosition then goto continue end

		Util.MoveTo(targetPosition + backVector * 0.8)
		yield("/rotation manual")

		if Util.Target(bossName) and GetDistanceToTarget() > 3 + GetTargetHitboxRadius() then
			useGapcloser()
		end
		wait(0.05)
	else
		yield("/rotation cancel")
		PathStop()
		if Configuration.CollectChests then
			local chestPosition = Vector3(1, 0, -7)
			Util.MoveTo(chestPosition)
			wait(1)
			local chestsOpened = 0
			local nearbyChests = GetNearbyObjectNames(1000, ObjectKind.Treasure)
			local chestCount = nearbyChests.Count
			while chestCount > 0 and chestsOpened < chestCount * 2 do
				for i = 1, chestCount do
					local chestName = nearbyChests[i - 1]
					if GetDistanceToPoint(chestPosition:Unpack()) < 1 then
						while not Util.Target(chestName, i) do
							wait(0.1)
						end
						Util.Interact()
						chestsOpened = chestsOpened + 1
						wait(0.2)
						ClearTarget()
					else
						wait(0.1)
					end
				end
			end
		end
		LeaveDuty()
		wait(3)
	end
	::continue::
end