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
  newObject:setCanBeLockByPadlock(getActivatedMods():contains('ZZZZAlbionPlayerShops_ModCompat'))
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
          if not getActivatedMods():contains('ZZZZAlbionPlayerShops_ModCompat') and __PlayerShopsRestrictions.hasAccessToShop(v, playerObj) then
            if v:isLockedByPadlock() then
              local unlockOption = context:addOption("Unlock", v, __PlayerShopsRestrictions.lockUnlockPlayerShop, v, false);
            else
              local lockOption = context:addOption("Lock", v, __PlayerShopsRestrictions.lockUnlockPlayerShop, v, true);
            end
          end
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

-- shouldn't activate this until we decide to reimplement private vehicles, otherwise anyone can make a store in anyone's vehicle
-- and you can't stop people from removing items from the container

--[[local old_showRadialMenu = ISVehicleMenu.showRadialMenuOutside

function ISVehicleMenu.showRadialMenuOutside(playerObj)
  if playerObj:getVehicle() then return end
  old_showRadialMenu(playerObj)

  local vehicle = ISVehicleMenu.getVehicleToInteractWith(playerObj)
  local menu = getPlayerRadialMenu(playerIndex)
  local hasLedger = playerObj:getInventory():containsType("ShopLedger")

  local boot = vehicle:getPartById('TruckBed')
  if boot then
    local shopData = boot:getModData()["shopData"]
    if shopData then
      if shopData.owner == playerObj:getUsername() then
        --edit store
        menu:addSlice('Edit Store', getTexture("media/ui/ZoomIn.png"), onEditShop, boot, shopData, 'owner')
      elseif shopData.coowners[playerObj:getUsername()] then
        --edit store
        menu:addSlice('Edit Store', getTexture("media/ui/ZoomIn.png"), onEditShop, boot, shopData, 'coowner')
      elseif not playerObj:isAccessLevel('None') then
        --edit store
        menu:addSlice('(ADMIN) Edit Store', getTexture("media/ui/ZoomIn.png"), onEditShop, boot, shopData, 'admin')
      end
      --view store
      menu:addSlice('View Store', getTexture("media/ui/ZoomIn.png"), onViewShop, boot, shopData)
    elseif hasLedger then
      --convert to shop
      menu:addSlice('Convert To Store', getTexture("media/ui/ZoomIn.png"), onCreateShop, boot, playerObj)
    end
  end
end]]

local function OnGameStart()
  if not SandboxVars.PlayerShops.AllowLedgerCrafting then
    getScriptManager():getRecipe("Create Shop Ledger"):setNeedToBeLearn(true)
  end

  if not getActivatedMods():contains('ZZZZAlbionPlayerShops_ModCompat') then
    __PlayerShopsRestrictions.restrictDestroy()
    __PlayerShopsRestrictions.restrictDismantle()
    __PlayerShopsRestrictions.restrictPickup()
  end
end

__PlayerShopsRestrictions = {}

__PlayerShopsRestrictions.restrictDestroy = function()
    local _canDestroy = ISDestroyCursor.canDestroy;
    function ISDestroyCursor.canDestroy(self, _object)
        local _return = _canDestroy(self, _object)
        if _return then
            if not __PlayerShopsRestrictions.hasAccessToShop(_object, getPlayer()) then
                return false
            end
        end

        return _return
    end
end

__PlayerShopsRestrictions.restrictDismantle = function()
    local _canScrapObjectInternal = ISMoveableSpriteProps.canScrapObjectInternal;
    function ISMoveableSpriteProps.canScrapObjectInternal(self, _result, _object)
        local _return = _canScrapObjectInternal(self, _result, _object)
        if _return then
            if not __PlayerShopsRestrictions.hasAccessToShop(_object, getPlayer()) then
                return false
            end
        end

        return _return
    end
end

__PlayerShopsRestrictions.restrictPickup = function()
    local _canPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable;
    function ISMoveableSpriteProps.canPickUpMoveable(self, _character, _square, _object)
        local _return = _canPickUpMoveable(self, _character, _square, _object)
        if _return then
            if not __PlayerShopsRestrictions.hasAccessToShop(_object, _character) then
                return false
            end
        end

        return _return
    end
end

---@param obj IsoObject
---@param player IsoPlayer
__PlayerShopsRestrictions.hasAccessToShop = function(obj, player)
    shopData = obj:getModData().shopData
    if not shopData then return true end
    if isAdmin() then return true end
    local username = player:getUsername()
    return shopData.owner == username or shopData.coowners[username]
end

---@param worldobjects
---@param object IsoObject
---@param locked bool
__PlayerShopsRestrictions.lockUnlockPlayerShop = function(worldobjects, object, locked)
    object:setLockedByPadlock(locked);
end

---@deprecated
---@param obj IsoObject
---@param player IsoPlayer
local function hasAccessToShop(obj, player)
    shopData = obj:getModData().shopData
    if not shopData then return true end
    if isAdmin() then return true end
    local username = player:getUsername()
    return shopData.owner == username or shopData.coowners[username]
end

local old_isValid = ISInventoryTransferAction.isValid
function ISInventoryTransferAction:isValid()
    local source, dest = self.srcContainer:getParent(), self.destContainer:getParent()
    if (source and not hasAccessToShop(source, self.character)) or (dest and not hasAccessToShop(dest, self.character)) then
        return false
    end

    return old_isValid(self)
end

_PlayerShopsOnTest = {}

---@param item InventoryItem
_PlayerShopsOnTest.HasAccessToShop = function(item)
    local parent = item:getContainer():getParent()
    if parent and not hasAccessToShop(parent, getPlayer()) then
        return false
    end
    return true
end

Events.OnGameStart.Add(OnGameStart)
