table.insert(snd.require.paths, string.format("%s\\XIVLauncher\\pluginConfigs\\LuaLibs", os.getenv("APPDATA")))
require "Util"

local Condition = require "Condition"
local Status = require "Status"

local BoiledEgg = 4650

while true do
	if GetCharacterCondition(Condition.BoundByDuty)
	and not GetCharacterCondition(Condition.InCombat)
	and GetStatusTimeRemaining(Status.WellFed) < 1200
	and GetItemCount(BoiledEgg) > 0 then
		yield("/item \"Boiled Egg\"")
	end
	wait(5)
end