table.insert(snd.require.paths, string.format("%s\\XIVLauncher\\pluginConfigs\\LuaLibs", os.getenv("APPDATA")))
require "Util"

local Condition = require "Condition"
local Status = require "Status"

local BoiledEgg = 4650

while true do
	if GetCharacterCondition(Condition.BoundByDuty) and GetStatusTimeRemaining(Status.WellFed) < 60 and GetItemCount(BoiledEgg) > 0 then
		yield("/item \"Boiled Egg\"")
	end
	wait(10)
end