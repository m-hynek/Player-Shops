
local playerShopData

local function OnInitGlobalModData(isNewGame)
	playerShopData = ModData.getOrCreate("playerShopData")
end

local function OnClientCommand(module, command, player, args)
	if module == "PlayerShops" then
		if command == "load" then
			if not playerShopData[args[1]] then playerShopData[args[1]] = {} end
	    for k, v in pairs(args[2]) do
	      args[2][k] = playerShopData[args[1]][k] or "0"
	    end
	    sendServerCommand(player, module, command, args[2])
		elseif command == "save" then
			if not playerShopData[player:getUsername()] then playerShopData[player:getUsername()] = {} end
			local priceData = playerShopData[player:getUsername()]
			for k, v in pairs(args) do
				priceData[k] = v
			end
		end
	end
end

Events.OnClientCommand.Add(OnClientCommand)
Events.OnInitGlobalModData.Add(OnInitGlobalModData)
