local Util = {}

local Condition = require "Enums\\Condition"
local Math = require "Libs\\Math"
local UI = require "Libs\\UI"

function Util.Target(name, index)
	ArgCheck({name, "string"})
	if index then
		yield(string.format("/target %s <list.%d>", name, index - 1))
	else
		yield("/target " .. name)
	end

	if HasTarget() and GetTargetName():lower() == name:lower() then
		return true
	end
end

function Util.Interact()
	yield("/pinteract")
end

function Util.IsMounted()
	return GetCharacterCondition(Condition.Mounted)
end

function Util.Mount(name)
	if not IsPlayerAvailable() or GetCharacterCondition(Condition.Casting) or GetCharacterCondition(Condition.Unknown57) then return end
	if Util.IsMounted() then return true end
	name = name or "Megaloambystoma"
	yield("/mount " .. name)
end

function Util.Dismount()
	if not Util.IsMounted() then return true end
	Util.ExecuteActionByName("Dismount")
end

function Util.GetPlayerPosition()
	return Vector3(GetPlayerRawXPos(), GetPlayerRawYPos(), GetPlayerRawZPos())
end

function Util.GetTargetPosition()
	return HasTarget() and Vector3(GetTargetRawXPos(), GetTargetRawYPos(), GetTargetRawZPos()) or nil
end

function Util.GetObjectPosition(name)
	return DoesObjectExist(name) and Vector3(GetObjectRawXPos(name), GetObjectRawYPos(name), GetObjectRawZPos(name)) or nil
end

function Util.CopyTargetCoordinates()
	local x, y, z = GetTargetRawXPos(), GetTargetRawYPos(), GetTargetRawZPos()
	SetClipboard(string.format("%s, %s, %s", tostring(x), tostring(y), tostring(z)))
end

function Util.IsInteracting()
	return IsAddonVisible("SelectIconString") or GetCharacterCondition(Condition.OccupiedInEvent)
end

function Util.IsInteractingWith(name)
	return GetTargetName():lower() == name:lower() and Util.IsInteracting()
end

function Util.MoveTo(position, usePathfinding, useVolume)
	ArgCheck({position, "Vector3"})
	local x, y, z = position:Unpack()
	assert(x ~= nil and y ~= nil and z ~= nil, string.format("MoveTo position vector is invalid. (%s, %s, %s)", tostring(x), tostring(y), tostring(z)))
	useVolume = not not useVolume
	if usePathfinding then
		PathfindAndMoveTo(x, y, z, useVolume)
	else
		-- What is the point of the 4th param if PathMoveTo just moves in a straight line?
		PathMoveTo(x, y, z, useVolume)
	end
end

function Util.ExecuteActionByName(name)
	ArgCheck({name, "string"})
	yield("/action \"" .. name .. "\"")
end

function Util.ExecuteGeneralActionByName(name)
	ArgCheck({name, "string"})
	yield("/generalaction \"" .. name .. "\"")
end

function Util.UseItemByName(name)
	ArgCheck({name, "string"})
	yield("/item \"" .. name .. "\"")
end

function Util.GetTargetForwardVector()
	local rotation = Math.ToSimpleAngle(GetTargetRotation())
	-- +X = right, -Z = forward
	return Vector3(math.sin(rotation), 0, -math.cos(rotation))
end

function Util.GetObjectForwardVector(name)
	local rotation = Math.ToSimpleAngle(GetObjectRotation(name))
	return Vector3(math.sin(rotation), 0, -math.cos(rotation))
end

local darkMatter = {5594, 5595, 5596, 5597, 5598, 10386, 17837, 33916}
function Util.Repair(threshold)
	threshold = threshold or 99
	ArgCheck({threshold, "number"})
	if not NeedsRepair(threshold) then return true end

	local repairOpened = retryWait(3, 0.1, function()
		if IsAddonVisible("Repair") then return true end
		Util.ExecuteGeneralActionByName("Repair")
	end)
	if not repairOpened then return false end

	-- Crude way of waiting for node text to load (which takes around 1 frame)
	local startRepairOpened = os.clock()
	local nodeTextLoaded = retry(1, function()
		return GetNodeText("Repair", 15, 2, 3):match("Grade (%d+)")
	end)
	if nodeTextLoaded then
		echoDebug("Node text loaded in %.3f seconds.", os.clock() - startRepairOpened)
	else
		echoDebug("Node text failed to load.")
		UI.CloseAddon("Repair")
		return false
	end

	local darkMatterNeeded = {}
	for i = 1, 15 do
		local grade = tonumber(GetNodeText("Repair", 15, i + 1, 3):match("Grade (%d+)"))
		if not grade then break end

		if not darkMatter[grade] then
			echoError("Grade %d Dark Matter isn't supported.", grade)
			UI.CloseAddon("Repair")
			return false
		end

		local need = darkMatterNeeded[grade]
		need = need and need + 1 or 1
		darkMatterNeeded[grade] = need
	end

	if not next(darkMatterNeeded) then
		echoDebug("No Dark Matter found in repair nodes.")
		return false
	end

	for grade, need in pairs(darkMatterNeeded) do
		local have = GetItemCount(darkMatter[grade])
		if need > have then
			echoDebug("Need %d Grade %d Dark Matter, but only have %d.", need, grade, have)
			UI.CloseAddon("Repair")
			return false
		end
	end

	echoDebug("Invoking repair callback.")
	UI.Callback("Repair", 0)

	local yesno = UI.WaitForAddon("SelectYesno", 1)
	if yesno then
		UI.Callback("SelectYesno", 0)
	end

	UI.CloseAddon("Repair")

	local startedRepair = retry(1, function()
		return GetCharacterCondition(Condition.Occupied39)
	end)

	if startedRepair then
		local repairConditionStartTime = os.clock()
		retry(3.5, function()
			return not GetCharacterCondition(Condition.Occupied39)
		end)
		echoDebug("Finished repairing in %.3f seconds.", os.clock() - repairConditionStartTime)
	else
		echoDebug("Failed to start repair.")
	end
end

return Util