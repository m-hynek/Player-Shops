local ISEditPlayerShopUI = require "ISEditPlayerShopUI"
local ISShowPlayerShopUI = require "ISShowPlayerShopUI"
local UI_SCALE = getTextManager():getFontHeight(UIFont.Small)/14

local function onEditShop(shop, shopData, access)
  local storeMenu = ISEditPlayerShopUI:new((getCore():getScreenWidth() - 400 * UI_SCALE)/2, (getCore():getScreenHeight() - 600 * UI_SCALE)/2, 400 * UI_SCALE, 600 * UI_SCALE, shop, shopData, access)
  storeMenu:initialise()
  storeMenu:addToUIManager()
end

local function onViewShop(shop, shopData)
  local storeMenu = ISShowPlayerShopUI:new((getCore():getScreenWidth() - 400 * UI_SCALE)/2, (getCore():getScreenHeight() - 600 * UI_SCALE)/2, 400 * UI_SCALE, 600 * UI_SCALE, shop, shopData)
  storeMenu:initialise()
  storeMenu:addToUIManager()
end

local function onCreateShop(object, player)
  local square = object:getSquare()
  --triggerEvent("OnObjectAboutToBeRemoved", object)
  square:transmitRemoveItemFromSquare(object)
  local properties = object:getProperties()
  local newObject = IsoThumpable.new(object:getCell(), square, object:getSprite():getName(), properties:Is("collideN"), nil)
  newObject:setCanBeLockByPadlock(true)
  newObject:setBlockAllTheSquare(properties:Is("collideN") and properties:Is("collideW"))
  newObject:setIsThumpable(properties:Is("collideN") or properties:Is("collideW"))
  newObject:setThumpDmg(0)
  newObject:setContainer(object:getContainer())
  for i = 1, object:getContainerCount() - 1 do
    newObject:addSecondaryContainer(object:getContainerByIndex(i))
  end
  --newObject:createContainersFromSpriteProperties()
  local shopData = {}
  shopData.owner = player:getUsername()
  shopData.coowners = {}
  shopData.name = player:getUsername() .. "'s Shop"
  shopData.UUID = getRandomUUID()
  newObject:getModData()["shopData"] = shopData
  square:AddSpecialObject(newObject)
  newObject:transmitCompleteItemToServer()
  newObject:transmitModData()
  player:getInventory():Remove("ShopLedger")
end

local function OnPreFillWorldObjectContextMenu(player, context, worldObjects, test)
  local playerObj = getSpecificPlayer(player)
  local hasLedger = playerObj:getInventory():containsType("ShopLedger")
  for i, v in ipairs(worldObjects) do
    if v:getContainerCount() > 0 and not (instanceof(v, 'IsoObject') and playerObj:DistToProper(v) > 2) then
      local shopData = v:getModData()["shopData"]
      if shopData then
        if tonumber(shopData.owner) then -- convert stores back to usernames... lol
          if shopData.owner == playerObj:getSteamID() then
            shopData.owner = playerObj:getUsername()
          end
        end
        if not shopData.UUID then 
          shopData.UUID = getRandomUUID()
          v:transmitModData()
        end
        if not shopData.coowners then
          shopData.coowners = {}
          v:transmitModData()
        end
        if shopData.owner == playerObj:getUsername() then
          --edit store
          local shopOption = context:addOption("Edit Store", v, onEditShop, shopData, 'owner')
        elseif shopData.coowners[playerObj:getUsername()] then
          --edit store
          local shopOption = context:addOption("Edit Store", v, onEditShop, shopData, 'coowner')
        elseif not playerObj:isAccessLevel('None') then
          --edit store
          local shopOption = context:addOption("(ADMIN) Edit Store", v, onEditShop, shopData, 'admin')
        end
        --view store
        local shopOption = context:addOption("View Store", v, onViewShop, shopData)
        break
      elseif hasLedger then
        --convert to shop
        local shopOption = context:addOption("Convert To Store", v, onCreateShop, playerObj)
        break
      end
    end
  end
end

Events.OnPreFillWorldObjectContextMenu.Add(OnPreFillWorldObjectContextMenu)

local function OnGameStart()
	if not SandboxVars.PlayerShops.AllowLedgerCrafting then
    getScriptManager():getRecipe("Create Shop Ledger"):setNeedToBeLearn(true)
  end
end

Events.OnGameStart.Add(OnGameStart)
