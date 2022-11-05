if isClient() then return end

local playerShopData

local function OnInitGlobalModData(isNewGame)
	playerShopData = ModData.getOrCreate("playerShopData")
end

local function OnClientCommand(module, command, player, args)
	if module == "PlayerShops" then
		if command == "load" then
			local UUID = args[1]
			if not playerShopData[UUID] then playerShopData[UUID] = {} end
			if not playerShopData[UUID].buyItems then playerShopData[UUID].buyItems = {} end
			local priceData = playerShopData[UUID]
			local items = args[2]
			for item, _ in pairs(items) do
				items[item] = priceData.buyItems[item] or "0"
			end
	    	sendServerCommand(player, module, command, {items, priceData.sellItems})
		elseif command == "save" then
			local UUID = args[1]
			if not playerShopData[UUID] then playerShopData[UUID] = {} end
			if not playerShopData[UUID].buyItems then playerShopData[UUID].buyItems = {} end
			local priceData = playerShopData[UUID]
			local prices = args[2]
			for item, price in pairs(prices) do
				priceData.buyItems[item] = price
			end
			priceData.sellItems = args[3]
		end
	end
end

Events.OnClientCommand.Add(OnClientCommand)
Events.OnInitGlobalModData.Add(OnInitGlobalModData)
