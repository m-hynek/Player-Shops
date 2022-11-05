if isClient() then return end

local playerShopData

local function OnInitGlobalModData(isNewGame)
	playerShopData = ModData.getOrCreate("playerShopData")
end

local function OnClientCommand(module, command, player, args)
	if module == "PlayerShops" then
		if command == "load" then
			if not playerShopData[args[1]] then playerShopData[args[1]] = {} end
			if not playerShopData[args[1]].virtualItems then playerShopData[args[1]].virtualItems = {} end
			for k, v in pairs(args[2]) do
				args[2][k] = playerShopData[args[1]][k] or "0"
			end
			for _,v in ipairs(playerShopData[args[1]].virtualItems) do
				args[2][v] = playerShopData[args[1]][v] or "0"
			end
	    	sendServerCommand(player, module, command, {args[2], playerShopData[args[1]].virtualItems})
		elseif command == "save" then
			local owner = args[1]
			if not playerShopData[owner] then playerShopData[owner] = {} end
			local priceData = playerShopData[owner]
			local prices = args[2]
			for k, v in pairs(prices) do
				priceData[k] = v
			end
			priceData.virtualItems = args[3]
		end
	end
end

Events.OnClientCommand.Add(OnClientCommand)
Events.OnInitGlobalModData.Add(OnInitGlobalModData)
