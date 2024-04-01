table.insert(snd.require.paths, string.format("%s\\XIVLauncher\\pluginConfigs\\LuaLibs", os.getenv("APPDATA")))
require "Util"

local Config = {
	maxItemsPerExchange = 15,
	checkSealBuff = true
}

local Condition = require "Condition"
local Zone = require "Zone"
local Status = require "Status"

local Materials = {
	GordianLens = 12674,
	GordianShaft = 12675,
	GordianCrank = 12676,
	GordianSpring = 12677,
	GordianPedal = 12678,
	GordianBolt = 12680
}

local AetheryteTickets = {
	Ligma = 21069
}

local Items = {
	Shop1 = {
		{
			Material = Materials.GordianShaft,
			Cost = 4,
			[4] = 11455,
			[5] = 11456,
			[6] = 11457
		},
		{
			Material = Materials.GordianCrank,
			Cost = 2,
			[7] = 11462,
			[8] = 11463,
			[9] = 11464
		},
		{
			Material = Materials.GordianSpring,
			Cost = 4,
			[10] = 11476,
			[11] = 11477,
			[12] = 11478
		},
		{
			Material = Materials.GordianPedal,
			Cost = 2,
			[13] = 11483,
			[14] = 11484,
			[15] = 11485
		},
		{
			Material = Materials.GordianBolt,
			Cost = 1,
			[16] = 11490,
			[17] = 11491,
			[18] = 11495,
			[19] = 11496,
			[20] = 11500,
			[21] = 11501,
			[22] = 11505,
			[23] = 11506
		}
	},

	Shop2 = {
		{
			Material = Materials.GordianShaft,
			Cost = 4,
			[3] = 11459,
			[4] = 11458
		},
		{
			Material = Materials.GordianCrank,
			Cost = 2,
			[5] = 11466,
			[6] = 11465
		},
		{
			Material = Materials.GordianSpring,
			Cost = 4,
			[7] = 11480,
			[8] = 11479
		},
		{
			Material = Materials.GordianPedal,
			Cost = 2,
			[9] = 11487,
			[10] = 11486
		},
		{
			Material = Materials.GordianBolt,
			Cost = 1,
			[11] = 11492,
			[12] = 11497,
			[13] = 11502,
			[14] = 11507
		}
	},

	Shop3 = {
		{
			Material = Materials.GordianShaft,
			Cost = 4,
			[3] = 11461,
			[4] = 11460
		},
		{
			Material = Materials.GordianCrank,
			Cost = 2,
			[5] = 11468,
			[6] = 11467
		},
		{
			Material = Materials.GordianSpring,
			Cost = 4,
			[7] = 11482,
			[8] = 11481
		},
		{
			Material = Materials.GordianPedal,
			Cost = 2,
			[9] = 11489,
			[10] = 11488
		},
		{
			Material = Materials.GordianBolt,
			Cost = 1,
			[11] = 11494,
			[12] = 11493,
			[13] = 11499,
			[14] = 11498,
			[15] = 11504,
			[16] = 11503,
			[17] = 11509,
			[18] = 11508
		}
	}
}

local Positions = {	
	Sabina = {-19.438650131226, 211.0, -36.142475128174},
	LigmaGrandCompany = {92.119247436523, 40.275371551514, 75.515075683594}
}

local function OpenGordianSubMenu()
	if GetTargetName() ~= "Sabina" then return end

	if IsDialogueMenuVisible() then
		SelectDialogueMenuOption(1)
	elseif not (IsDialogueSubMenuVisible() or IsShopExchangeVisible()) then
		return
	end
	return true
end

local function OpenGordianShopExchange(index)
	if GetTargetName() ~= "Sabina" then return end

	if IsDialogueMenuVisible() then
		OpenGordianSubMenu()
	end

	if IsShopExchangeVisible() then
		CloseShopExchange() -- Prevent script from breaking if it's started inside exchange window
		return
	end

	if IsDialogueSubMenuVisible() then
		SelectDialogueSubMenuOption(index)
		return true
	end
end

local function GetAvailableItemsForShop(shopIndex, skipInventoryCheck)
	ArgCheck({shopIndex, "number"})
	local shopData = Items["Shop" .. shopIndex]
	local availableItems = {}
	for i, categoryData in ipairs(shopData) do
		local material = categoryData.Material
		local cost = categoryData.Cost
		for itemShopIndex, itemId in pairs(categoryData) do
			if itemShopIndex == "Material" or itemShopIndex == "Cost" then goto NextItem end
			local inventoryCount = GetItemCount(itemId)
			if not skipInventoryCheck and inventoryCount > 0 then goto NextItem end
			local availableMaterials = GetItemCount(material)
			if availableMaterials < cost then goto NextItem end
			local purchaseAmount = math.floor(availableMaterials / cost)
			if purchaseAmount <= 0 then goto NextItem end
			table.insert(availableItems, {
				shopIndex = itemShopIndex,
				id = itemId,
				amount = purchaseAmount
			})
			::NextItem::
		end
	end

	table.sort(availableItems, function(a, b)
		return a.amount > b.amount
	end)

	return availableItems
end

local function GetItemsInInventoryForShop(shopIndex)
	ArgCheck({shopIndex, "number"})
	local shopData = Items["Shop" .. shopIndex]
	local inventoryItems = { count = 0 }
	for i, categoryData in ipairs(shopData) do
		for itemShopIndex, itemId in pairs(categoryData) do
			if itemShopIndex == "Material" or itemShopIndex == "Cost" then goto NextItem end
			local inventoryCount = GetItemCount(itemId)
			if inventoryCount <= 0 then goto NextItem end
			inventoryItems[itemId] = true
			inventoryItems.count = inventoryItems.count + inventoryCount
			::NextItem::
		end
	end

	return inventoryItems
end

local shopCount = 3

local function GetAvailableItemsTotalCount(skipInventoryCheck)
	local count = 0
	for shopIndex = 1, shopCount do
		local availableShop = GetAvailableItemsForShop(shopIndex, skipInventoryCheck)
		count = count + #availableShop
	end

	return count
end

local function GetItemsInInventoryTotalCount()
	local count = 0
	for shopIndex = 1, shopCount do
		local inventoryShop = GetItemsInInventoryForShop(shopIndex)
		count = count + inventoryShop.count
	end

	return count
end

local _GetInventoryFreeSlotCount = GetInventoryFreeSlotCount
local function GetInventoryFreeSlotCount()
	return math.max(_GetInventoryFreeSlotCount() - 1, 0)
end

while true do
	local availableShopTotalCount = GetAvailableItemsTotalCount()
	local availableShopIgnoreInventoryTotalCount = GetAvailableItemsTotalCount(true)
	local inventoryShopTotalCount = GetItemsInInventoryTotalCount()
	local inventorySpace = GetInventoryFreeSlotCount()

	if availableShopIgnoreInventoryTotalCount <= 0 and inventoryShopTotalCount <= 0 then
		echoError("You have no materials nor any items to turn in.")
		return
	end

	if Config.checkSealBuff and not HasStatusId({Status.SealSweetener, Status.PrioritySealAllowance}) then
		echoError("No Seal Sweetener!")
		return
	end

	-- // Debug no touch
	-- inventorySpace = 0
	-- availableShopTotalCount = 0
	-- availableShopIgnoreInventoryTotalCount = 0
	-- inventoryShopTotalCount = 0

	if IsInZone(Zone.LimsaLominsaUpperDecks) and inventoryShopTotalCount > 0 then
		echo("Turning in items you already have since you're in Ligma Lominsa Upper Decks.")
		goto TurnIn
	elseif availableShopTotalCount > 0 and inventorySpace > 0 then
		echo("Can buy some items.")
	elseif inventoryShopTotalCount > 0 then
		echo("Can turn in some items.")
		goto TurnIn
	elseif inventorySpace <= 0 and inventoryShopTotalCount <= 0 then
		echoError("[Warning] Inventory is full with no items to turn in.")
		return
	else
		echoError("[!] Unhandled pre-buy condition.",
		availableShopTotalCount, availableShopIgnoreInventoryTotalCount,
		inventoryShopTotalCount, inventorySpace)
	end

	do -- Weird goto variable scoping error if no `do end` block o_O
		local teleportSuccess = retry(15, function()
			if not (
				GetCharacterCondition(Condition.Casting) or
				GetCharacterCondition(Condition.BetweenAreas) or
				GetCharacterCondition(Condition.BetweenAreas51) or
				not IsPlayerAvailable()
			) and not IsInZone(Zone.Idyllshire) then
				yield("/tp Idyllshire")
				wait(2)
			end

			if IsInZone(Zone.Idyllshire) then
				return true
			end
		end)

		if not teleportSuccess then
			echoError("Teleport to Idyllshire failed.")
			return
		end

		echo("Arrived in Idyllshire.")
		retry(5, function() return IsPlayerAvailable() end)

		if GetDistanceToPoint(table.unpack(Positions.Sabina)) > 10 then
			echo("Mounting")
			retry(5, Mount)
		end

		MoveTo(Positions.Sabina, true)
		if not retry(40, function() return GetDistanceToPoint(table.unpack(Positions.Sabina)) <= 3 end) then
			echoError("Failed to walk to Idyllshire vendor.")
			return
		end
		PathStop()
		-- Dismount()
		wait(1.5)

		for shopIndex = 1, shopCount do
			::BuyShop::
			local availableShop = GetAvailableItemsForShop(shopIndex)
			local inventoryShop = GetItemsInInventoryForShop(shopIndex)
			inventorySpace = GetInventoryFreeSlotCount()

			echo("Shop", shopIndex, "items in inventory:", inventoryShop.count)

			if inventorySpace > 0 and #availableShop > 0 then
				echo("Can buy", #availableShop, "items in Shop", shopIndex .. ".")
				if not retry(6, function()
					if IsInteractingWith("Sabina") then return true end
					Target("Sabina")
					wait(0.1)
					Interact()
					wait(0.4)
				end) then
					echoError("Failed to interact.")
					return
				end
				if not retry(2, OpenGordianSubMenu) then echo("Retry timed out in a critical spot. Connection issue or developer skill issue?") return end
				if not retry(2, OpenGordianShopExchange, shopIndex) then echo("Retry timed out in a critical spot. Connection issue or developer skill issue?") return end

				for i, itemData in ipairs(availableShop) do
					if GetInventoryFreeSlotCount() <= 0 then goto continue end
					local itemId = itemData.id
					if inventoryShop[itemId] then echo("Skipping item", itemId, "because it was already purchased.") goto continue end
					local itemShopIndex = itemData.shopIndex
					local purchaseAmount = itemData.amount
					inventorySpace = math.min(GetInventoryFreeSlotCount(), Config.maxItemsPerExchange)
					retry(1, ShopExchangeItem, itemShopIndex, math.min(inventorySpace, purchaseAmount))
					retry(3, function()
						return not IsRequestVisible()
					end)
					-- echo("Bought?")

					CloseRequest()
					::continue::
				end

				if #GetAvailableItemsForShop(shopIndex) > 0 and GetInventoryFreeSlotCount() > 0 then
					echo("Retrying buy from Shop", shopIndex, "because not all items were bought.")
					goto BuyShop
				end
			elseif inventorySpace <= 0 then
				echo("Inventory is full, time to sell.")
				goto TurnIn
			elseif #availableShop <= 0 then
				echo("Shop", shopIndex, "is bought out.")
			else
				echoError("[!] Unhandled BuyShop condition.", inventorySpace, inventoryShop.count, #availableShop)
			end
		end
	end

	::TurnIn::
	local shouldTurnIn = false
	for shopIndex = 1, 3 do
		if GetItemsInInventoryForShop(shopIndex).count > 0 then
			shouldTurnIn = true
			break
		end
	end

	if shouldTurnIn then
		echo("Starting turn-in.")
		for i = 1, 3 do
			retry(2, function()
				return CloseShopExchange() and CloseDialogueSubMenu() and CloseDialogueMenu()
			end)
			wait(0.5)
		end

		if GetItemCount(AetheryteTickets.Ligma) <= 0 then
			echoError("NO LIGMA GC AETHERYTE TICKETS IDIOT.")
			return
		end

		local teleportSuccess = retry(15, function()
			if not (
				GetCharacterCondition(Condition.Casting) or
				GetCharacterCondition(Condition.BetweenAreas) or
				GetCharacterCondition(Condition.BetweenAreas51) or
				not IsPlayerAvailable()
			) and not IsInZone(Zone.LimsaLominsaUpperDecks) then
				yield("/item Maelstrom Aetheryte Ticket")
				wait(2)
			end

			if IsInZone(Zone.LimsaLominsaUpperDecks) then
				return true
			end
		end)
		if not teleportSuccess then
			echoError("Teleport to Ligma failed.")
			return
		end

		echo("Arrived in Ligma Lominsa Upper Decks.")
		retry(5, function() return IsPlayerAvailable() end)

		MoveTo(Positions.LigmaGrandCompany)
		local success = retry(20, function()
			if GetDistanceToPoint(table.unpack(Positions.LigmaGrandCompany)) <= 1 then
				return true
			end
		end)
		if not success then
			echoError("Failed to walk to Ligma grand company.")
			return
		end
		PathStop()
		echo("Starting turn-in of", GetItemsInInventoryTotalCount(), "items.")
		yield("/deliveroo enable")
		wait(1)
		if not retry(600, function() return not DeliverooIsTurnInRunning() end) then
			echoError("Deliveroo timed out.")
			return
		end
		echo("Loop finished")
	else
		echoError("[!] Don't have anything to turn in?")
	end
end