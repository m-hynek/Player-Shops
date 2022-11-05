if isClient() then return end

local playerShopData

local function OnInitGlobalModData(isNewGame)
	playerShopData = ModData.getOrCreate("playerShopData")
end

local function OnClientCommand(module, command, player, args)
	if module == "PlayerShops" then
		if command == "load" then
			if not playerShopData[args[1]] then playerShopData[args[1]] = {} end
			if not playerShopData[args[2]] then playerShopData[args[2]] = {} end
			for k, v in pairs(args[3]) do
				args[3][k] = playerShopData[args[1]][k] or "0"
			end
	    	sendServerCommand(player, module, command, {args[3], playerShopData[args[2]].sellItems})
		elseif command == "save" then
			local owner = args[1]
			if not playerShopData[owner] then playerShopData[owner] = {} end
			local priceData = playerShopData[owner]
			local prices = args[3]
			for k, v in pairs(prices) do
				priceData[k] = v
			end
			local containerUUID = args[2]
			if not playerShopData[containerUUID] then playerShopData[containerUUID] = {} end
			playerShopData[containerUUID].sellItems = args[4]
		end
	end
end

Events.OnClientCommand.Add(OnClientCommand)
Events.OnInitGlobalModData.Add(OnInitGlobalModData)
