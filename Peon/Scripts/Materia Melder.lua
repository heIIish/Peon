local UI = require "Libs\\UI"
local Condition = require "Enums\\Condition"
local Debug = require "Libs\\Debug"

local itemIndex = 1
local function OpenContextMenu()
	if not UI.Callback("MateriaAttach", 4, itemIndex - 1, 1, 0) then
		echoError("Failed to open context menu (materia melding window isn't open).")
		return
	end
	local contextMenuOpened = retry(1, function()
		return IsAddonVisible("ContextMenu")
	end)
	if not contextMenuOpened then
		echoError("Failed to open context menu.")
	end

	return contextMenuOpened
end

local function ClickRetrieveMateria()
	local success = UI.Callback("ContextMenu", 0, 1, 0, nil, nil)
	if success then
		echoDebug("Clicked context menu.")
	else
		echoDebug("Failed to click Retrieve Materia (context menu isn't open).")
	end

	return success
end

local function WaitForExtract()
	local startedExtracting = retry(1, function()
		return GetCharacterCondition(Condition.Occupied39)
	end)
	if not startedExtracting then
		echoError("Failed to start extracting.")
		return
	end
	echoDebug("Started extracting.")
	local extractStartTime = os.clock()
	local success = retry(5, function()
		return not GetCharacterCondition(Condition.Occupied39)
	end)
	echoDebug("Finished extracting in %.3f seconds.", os.clock() - extractStartTime)

	return success
end

local function SelectGearItem()
	if not UI.Callback("MateriaAttach", 1, itemIndex - 1, 1, 0) then
		echoError("Failed to select meld item (materia melding window isn't open).")
		return
	end

	return true
end

local function WaitForMeldStart()
	local startedMelding = retry(1, function()
		return GetCharacterCondition(Condition.MeldingMateria)
	end)
	if startedMelding then
		echoDebug("Started melding.")
	else
		echoError("Failed to start melding.")
	end

	return startedMelding
end

local function SelectMateria()
	local success = retryWait(1, 0.1, function()
		UI.Callback("MateriaAttach", 2, 0, 1, 0)
		return IsAddonVisible("MateriaAttachDialog")
	end)
	if success then
		echoDebug("Selected materia.")
	else
		echoDebug("Failed to select materia.")
	end

	return success and WaitForMeldStart() 
end

local function AcceptMeld()
	if not IsAddonVisible("MateriaAttachDialog") then
		echoError("Failed to accept meld (materia melding accept window isn't open).")
		return
	end
	local success = retry(1, function()
		UI.Callback("MateriaAttachDialog", 0, 0, 0)
		return IsAddonVisible("MateriaAttachDialog")
	end)
	if success then
		echoDebug("Accepted meld dialog.")
	else
		echoDebug("Failed to accept meld dialog.")
	end

	return success
end

local function WaitForMeldFinish()
	local meldStartTime = os.clock()
	local success = retry(5, function()
		return not GetCharacterCondition(Condition.MeldingMateria)
	end)
	echoDebug("Finished melding in %.3f seconds.", os.clock() - meldStartTime)

	return success
end

local function TryExtractMateria()
	if not OpenContextMenu() then return end
	if not ClickRetrieveMateria() then return end
	return WaitForExtract()
end

local function TryMeldMateria()
	if not SelectGearItem() then return end
	if not SelectMateria() then return end
	if not AcceptMeld() then return end
	return WaitForMeldFinish()
end

Debug.Enable()

::Start::
if not IsAddonVisible("MateriaAttach") then
	echoError("Materia melding window not open, aborting.")
	return
end

local extracted = TryExtractMateria()
if extracted then
	echoDebug("Trying to extract again in case there's more.")
	goto Start
end

local fails = 0
local maxFails = 3
while true do
	if not (TryMeldMateria() or TryExtractMateria()) then
		fails = fails + 1
		echoError(string.format("Something went wrong... %d/%d fail(s).", fails, maxFails))
		if fails >= maxFails then
			echoError("Too many failed melding attempts, aborting.")
			return
		end
	end
end