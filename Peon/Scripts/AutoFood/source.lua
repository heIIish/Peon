local Condition = require "Enums\\Condition"
local Status = require "Enums\\Status"
local Util = require "Libs\\Util"

local foodId = Configuration.Food

while true do
	if GetCharacterCondition(Condition.BoundByDuty)
	and not GetCharacterCondition(Condition.InCombat)
	and GetStatusTimeRemaining(Status.WellFed) < 1200
	and GetItemCount(foodId) > 0 then
		Util.UseItemByName("Boiled Egg")
	end
	wait(5)
end