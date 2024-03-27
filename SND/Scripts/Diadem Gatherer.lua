table.insert(snd.require.paths, string.format("%s\\XIVLauncher\\pluginConfigs\\LuaLibs", os.getenv("APPDATA")))
require "Util"

local Zone = require "Zone"
local Action = require "Action"
local Status = require "Status"
local Job = require "Job"

while true do
	if not (IsInZone(Zone.Diadem) and IsGathering()) then wait(1) goto continue end

	local jobId = GetClassJobId()
	local isMIN, isBTN = jobId == Job.MIN, jobId == Job.BTN
	if not (isMIN or isBTN) then wait(1) goto continue end

	local gp = GetGp()
	if not HasStatusId({Status.GiftOfTheLand, Status.GiftOfTheLand2}) and gp >= 50 then
		local hasEnough = gp >= 100
		if isMIN then
			ExecuteAction(hasEnough and Action.MountaineersGift2 or Action.MountaineersGift)
		else
			ExecuteAction(hasEnough and Action.PioneersGift2 or Action.PioneersGift)
		end
		wait(0.2)
		goto continue
	end
	GatherItemAtIndex(4)
	wait(0.25)
	::continue::
end