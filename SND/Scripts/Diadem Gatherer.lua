table.insert(snd.require.paths, string.format("%s\\XIVLauncher\\pluginConfigs\\LuaLibs", os.getenv("APPDATA")))
require "Util"

local Zone = require "Zone"
local Action = require "Action"
local Status = require "Status"

while true do
	if not (IsInZone(Zone.Diadem) and IsGathering()) then wait(1) goto continue end

	local gp = GetGp()
	if gp >= 50 and not HasStatusId({Status.GiftOfTheLand, Status.GiftOfTheLand2}) then
		ExecuteAction(gp >= 100 and Action.PioneersGift2 or Action.PioneersGift)
		wait(0.2)
		goto continue
	end
	GatherItemAtIndex(4)
	wait(0.25)
	::continue::
end
