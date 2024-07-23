local UI = {}

function UI.Callback(name, ...)
	if IsAddonVisible(name) then
		Call(name, true, ...)
		return true
	end
	return false
end

function UI.CallbackShop(name, index, amount)
	ArgCheck({name, "string"}, {index, "number"}, {amount, "number"})
	return UI.Callback(name, 0, index - 1, amount)
end

function UI.CallbackList(name, index)
	ArgCheck({name, "string"}, {index, "number"})
	return UI.Callback(name, index - 1)
end

function UI.WaitForAddon(name, seconds)
	seconds = seconds or 5
	ArgCheck({seconds, "number"})
	return retry(seconds, function()
		return IsAddonVisible(name)
	end)
end

function UI.WaitForAddonReady(name, seconds)
	seconds = seconds or 5
	ArgCheck({seconds, "number"})
	return retry(seconds, function()
		return IsAddonReady(name)
	end)
end

function UI.WaitForAddonClosed(name, seconds)
	seconds = seconds or 5
	ArgCheck({seconds, "number"})
	return retry(seconds, function()
		return not IsAddonVisible(name)
	end)
end

function UI.CloseAddon(name)
	ArgCheck({name, "string"})
	return UI.Callback(name, -1)
end

function UI.CloseAddons(...)
	local wereAnyOpen = false
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		local wasOpen = UI.CloseAddon(name)
		if wasOpen then
			wereAnyOpen = true
		end
	end
	return wereAnyOpen
end

function UI.CloseAllAddons()
	return UI.CloseAddons(
		"SelectIconString",
		"SelectString",
		"ShopExchangeItem"
	)
end

function UI.IsGuildLeveInToDoList(name)
	ArgCheck({name, "string"})
	for i = 8, 12 do
		if GetNodeText("_ToDoList", i, 11) == name then
			return true
		end
	end
end

function UI.IsGuildLeveListVisible()
	return IsAddonVisible("GuildLeve") and IsNodeVisible("GuildLeve", 1, 23)
end

function UI.IsGuildLeveInGuildLeveList(name)
	if not UI.IsGuildLeveListVisible() then return end
	for i = 40, 60 do
		if GetNodeText("GuildLeve", 11, i, 4) == name then
			return true
		end
	end
end

function UI.GetGuildLeveAllowances()
	if not UI.IsGuildLeveListVisible() then return end
	if not IsNodeVisible("GuildLeve", 1, 28, 30) then return end
	return tonumber(GetNodeText("GuildLeve", 5, 2))
end

function UI.GatherItemAtIndex(index)
	ArgCheck({index, "number"})
	return UI.Callback("Gathering", index - 1)
end

return UI