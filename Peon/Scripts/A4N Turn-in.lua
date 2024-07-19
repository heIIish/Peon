local Config = {
	maxItemsPerExchange = 15,
	checkSealBuff = true
}

local Condition = require "Enums\\Condition"
local Zone = require "Enums\\Zone"
local Status = require "Enums\\Status"
local Util = require "Libs\\Util"
local UI = require "Libs\\UI"
local Debug = require "Libs\\Debug"

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
			Items = {
				[4] = 11455,
				[5] = 11456,
				[6] = 11457
			}
		},
		{
			Material = Materials.GordianCrank,
			Cost = 2,
			Items = {
				[7] = 11462,
				[8] = 11463,
				[9] = 11464
			}
		},
		{
			Material = Materials.GordianSpring,
			Cost = 4,
			Items = {
				[10] = 11476,
				[11] = 11477,
				[12] = 11478
			}
		},
		{
			Material = Materials.GordianPedal,
			Cost = 2,
			Items = {
				[13] = 11483,
				[14] = 11484,
				[15] = 11485
			}
		},
		{
			Material = Materials.GordianBolt,
			Cost = 1,
			Items = {
				[16] = 11490,
				[17] = 11491,
				[18] = 11495,
				[19] = 11496,
				[20] = 11500,
				[21] = 11501,
				[22] = 11505,
				[23] = 11506
			}
		}
	},

	Shop2 = {
		{
			Material = Materials.GordianShaft,
			Cost = 4,
			Items = {
				[3] = 11459,
				[4] = 11458
			}
		},
		{
			Material = Materials.GordianCrank,
			Cost = 2,
			Items = {
				[5] = 11466,
				[6] = 11465
			}
		},
		{
			Material = Materials.GordianSpring,
			Cost = 4,
			Items = {
				[7] = 11480,
				[8] = 11479
			}
		},
		{
			Material = Materials.GordianPedal,
			Cost = 2,
			Items = {
				[9] = 11487,
				[10] = 11486
			}
		},
		{
			Material = Materials.GordianBolt,
			Cost = 1,
			Items = {
				[11] = 11492,
				[12] = 11497,
				[13] = 11502,
				[14] = 11507
			}
		}
	},

	Shop3 = {
		{
			Material = Materials.GordianShaft,
			Cost = 4,
			Items = {
				[3] = 11461,
				[4] = 11460
			}
		},
		{
			Material = Materials.GordianCrank,
			Cost = 2,
			Items = {
				[5] = 11468,
				[6] = 11467
			}
		},
		{
			Material = Materials.GordianSpring,
			Cost = 4,
			Items = {
				[7] = 11482,
				[8] = 11481
			}
		},
		{
			Material = Materials.GordianPedal,
			Cost = 2,
			Items = {
				[9] = 11489,
				[10] = 11488
			}
		},
		{
			Material = Materials.GordianBolt,
			Cost = 1,
			Items = {
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
}

local Positions = {	
	Sabina = Vector3(-19.438650131226, 211.0, -36.142475128174),
	LigmaGrandCompany = Vector3(92.119247436523, 40.275371551514, 75.515075683594)
}

local function OpenGordianShopExchange(index)
	if GetTargetName() ~= "Sabina" then
		Util.Target("Sabina")
		echoDebug("Targetting.")
		return
	end

	if not Util.IsInteractingWith("Sabina") then
		echoDebug("Interacting.")
		Util.Interact()
	end

	if UI.WaitForAddon("SelectIconString", 0) then
		UI.CallbackList("SelectIconString", 1)
		return
	elseif UI.WaitForAddon("SelectString", 0) then
		UI.CallbackList("SelectString", index)
		return UI.WaitForAddon("ShopExchangeItem", 3)
	elseif UI.WaitForAddon("ShopExchangeItem", 0) then
		UI.CloseAddon("ShopExchangeItem")
		return
	end
end

local function TryCloseShopAddons()
	local lastAddonCheck = 0
	repeat
		local wereAnyOpen = UI.CloseAddons("ShopExchangeItem", "SelectString", "SelectIconString")
		if wereAnyOpen then
			echoDebug("Something was open, trying to close everything.")
			lastAddonCheck = os.clock()
		end
		wait(0.05)
	until os.clock() - lastAddonCheck >= 1
end

local function GetAvailableItemsForShop(shopIndex, skipInventoryCheck)
	ArgCheck({shopIndex, "number"})
	local shopData = Items["Shop" .. shopIndex]
	local availableItems = {}
	local availableMaterials = {}

	for i, categoryData in ipairs(shopData) do
		local material = categoryData.Material
		local cost = categoryData.Cost
		for itemShopIndex, itemId in pairs(categoryData.Items) do
			local inventoryCount = GetItemCount(itemId)
			if not skipInventoryCheck and inventoryCount > 0 then goto NextItem end

			local materialCount = availableMaterials[material]
			if not materialCount then
				materialCount = GetItemCount(material)
				availableMaterials[material] = materialCount
			end

			if cost > materialCount then goto NextItem end

			local purchaseAmount = math.min(math.floor(materialCount / cost), Config.maxItemsPerExchange)
			materialCount = materialCount - purchaseAmount * cost
			availableMaterials[material] = materialCount

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
		for itemShopIndex, itemId in pairs(categoryData.Items) do
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

-- Silly (UGLY) solution fix later xD
local function teleportIfNotRecentlyOccupied(zoneId, func)
	local lastOccupied = 0
	return retryWait(15, 0.1, function()
		local inZone = IsInZone(zoneId)
		if GetCharacterCondition(Condition.Casting) or
		GetCharacterCondition(Condition.BetweenAreas) or
		GetCharacterCondition(Condition.BetweenAreas51) or
		not IsPlayerAvailable() then
			lastOccupied = os.clock()
		elseif not inZone then
			if os.clock() - lastOccupied > 2 then
				func()
				wait(1)
			else
				echoDebug("Last occupied %.2f seconds ago, don't teleport yet.", os.clock() - lastOccupied)
			end
		end

		return inZone
	end)
end

Debug.Enable()

while true do
	local availableShopTotalCount = GetAvailableItemsTotalCount()
	local availableShopIgnoreInventoryTotalCount = GetAvailableItemsTotalCount(true)
	local inventoryShopTotalCount = GetItemsInInventoryTotalCount()
	local inventorySpace = GetInventoryFreeSlotCount()

	-- // Debug no touch
	-- inventorySpace = 0
	-- availableShopTotalCount = 0
	-- availableShopIgnoreInventoryTotalCount = 1
	-- inventoryShopTotalCount = 0
	-- Config.maxItemsPerExchange = 1
	-- Config.checkSealBuff = false

	if availableShopIgnoreInventoryTotalCount <= 0 and inventoryShopTotalCount <= 0 then
		echoError("You have no materials nor any items to turn in.")
		return
	end

	if IsInZone(Zone.LimsaLominsaUpperDecks) and inventoryShopTotalCount > 0 then
		echoDebug("Turning in items you already have since you're in Ligma Lominsa Upper Decks.")
		goto TurnIn
	elseif availableShopTotalCount > 0 and inventorySpace > 0 then
		echoDebug("Can buy some items.")
	elseif inventoryShopTotalCount > 0 then
		echoDebug("Can turn in some items.")
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
		local teleportSuccess = teleportIfNotRecentlyOccupied(Zone.Idyllshire, function()
			yield("/tp Idyllshire")
		end)

		if not teleportSuccess then
			echoError("Teleport to Idyllshire failed.")
			return
		end

		echoDebug("Arrived in Idyllshire.")
		retry(1, function() return IsPlayerAvailable() end)

		if GetDistanceToPoint(Positions.Sabina:Unpack()) > 10 then
			echoDebug("Mounting.")
			retry(5, Util.Mount)
		end

		Util.MoveTo(Positions.Sabina, true)
		if not retry(40, function() return GetDistanceToPoint(Positions.Sabina:Unpack()) <= 2 end) then
			echoError("Failed to walk to Idyllshire vendor.")
			return
		end

		PathStop()
		wait(0.2)

		TryCloseShopAddons()

		for shopIndex = 1, shopCount do
			::BuyShop::
			local availableShop = GetAvailableItemsForShop(shopIndex)
			local inventoryShop = GetItemsInInventoryForShop(shopIndex)
			inventorySpace = GetInventoryFreeSlotCount()

			echoDebug("Shop %d items in inventory: %d", shopIndex, inventoryShop.count)

			if inventorySpace > 0 and #availableShop > 0 then
				echoDebug("Can buy %d items in Shop %d.", #availableShop, shopIndex)

				if not retryWait(4, 0.1, OpenGordianShopExchange, shopIndex) then
					echoError("Failed to open shop.")
					return
				end

				echoDebug("Opened shop.")
				wait(0.5)

				for i, itemData in ipairs(availableShop) do
					if GetInventoryFreeSlotCount() <= 0 then goto continue end
					local itemId = itemData.id
					if inventoryShop[itemId] then echoDebug("Skipping item %d because it was already purchased.", itemId) goto continue end
					echoDebug("Attempting to buy item %d.", itemId)
					local itemShopIndex = itemData.shopIndex
					local purchaseAmount = itemData.amount
					inventorySpace = math.min(GetInventoryFreeSlotCount(), Config.maxItemsPerExchange)
					local attempts = 0
					retry(1, function()
						attempts = attempts + 1
						if attempts % 20 == 0 then
							UI.CallbackShop("ShopExchangeItem", itemShopIndex, math.min(inventorySpace, purchaseAmount))
						end
						return IsAddonVisible("Request")
					end)
					echoDebug("Request visible.")
					retry(3, function()
						return not IsAddonVisible("Request")
					end)
					echoDebug("Request accepted.")
					wait(0.35)
					echoDebug("Bought?")

					UI.CloseAddon("Request")
					::continue::
				end

				if #GetAvailableItemsForShop(shopIndex) > 0 and GetInventoryFreeSlotCount() > 0 then
					echoDebug("Retrying buy from Shop %d because not all items were bought.", shopIndex)
					wait(1) -- Server slow sometimes
					goto BuyShop
				end
			elseif inventorySpace <= 0 then
				echoDebug("Inventory is full, time to sell.")
				goto TurnIn
			elseif #availableShop <= 0 then
				echoDebug("Shop %d is bought out.", shopIndex)
			else
				echoError("[!] Unhandled BuyShop condition.", inventorySpace, inventoryShop.count, #availableShop)
			end
		end
	end

	echoDebug("Finished shopping.")

	::TurnIn::
	local shouldTurnIn = false
	for shopIndex = 1, 3 do
		if GetItemsInInventoryForShop(shopIndex).count > 0 then
			shouldTurnIn = true
			break
		end
	end

	if shouldTurnIn then
		echoDebug("Starting turn-in.")
		TryCloseShopAddons()

		if not IsInZone(Zone.LimsaLominsaUpperDecks) and GetItemCount(AetheryteTickets.Ligma) <= 0 then
			echoError("NO LIGMA GC AETHERYTE TICKETS IDIOT.")
			return
		end

		local teleportSuccess = teleportIfNotRecentlyOccupied(Zone.LimsaLominsaUpperDecks, function()
			Util.UseItemByName("Maelstrom Aetheryte Ticket")
		end)

		if not teleportSuccess then
			echoError("Teleport to Ligma failed.")
			return
		end

		echoDebug("Arrived in Ligma Lominsa Upper Decks.")
		retry(5, function() return IsPlayerAvailable() end)

		Util.MoveTo(Positions.LigmaGrandCompany)
		local success = retry(20, function()
			if GetDistanceToPoint(Positions.LigmaGrandCompany:Unpack()) <= 1 then
				return true
			end
		end)
		if not success then
			echoError("Failed to walk to Ligma grand company.")
			return
		end
		PathStop()

		if Config.checkSealBuff and not HasStatusId({Status.SealSweetener, Status.PrioritySealAllowance}) then
			echoError("No Seal Sweetener!")
			while not HasStatusId({Status.SealSweetener, Status.PrioritySealAllowance}) do
				wait(1)
			end
			goto TurnIn
		end

		echoDebug("Starting turn-in of %d items.", GetItemsInInventoryTotalCount())
		wait(0.5)
		yield("/deliveroo enable")
		wait(1)
		if not retryWait(600, 1, function() return not DeliverooIsTurnInRunning() end) then
			echoError("Deliveroo timed out.")
			return
		end
		echoDebug("Loop finished.")
	else
		echoError("[!] Don't have anything to turn in?")
		return
	end
end