
local ISBuyModal = ISPanel:derive("ISBuyModal")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL/14

local function getMoneyCountIncludingWallets(container)
    local sum = 0
    local itemsList = container:getItems()
    for i = 0, itemsList:size()-1 do
        local item = itemsList:get(i)
        if item:getCategory() == "Container" then
            sum = sum + getMoneyCountIncludingWallets(item:getItemContainer())
        end
        if BMSATM.Money.Wallets[item:getFullType()] then
            sum = sum + item:getModData().moneyCount
        elseif BMSATM.Money.Values[item:getFullType()] ~= nil then
            sum = sum + BMSATM.Money.Values[item:getFullType()].v
        end
    end
    return sum
end

local function createMoney(container, num)
  while num > 0 do
      local max = 0
      local maxType = ""
      for itemType, data in pairs(BMSATM.Money.Values) do
          if num >= data.v then
              max = data.v
              maxType = itemType
          end
      end
      if max == 0 then return end
      local item = container:AddItem(maxType)
      container:addItemOnServer(item)
      num = num - max
  end
end

function ISBuyModal:createChildren()
  local z = 10 * FONT_SCALE + FONT_HGT_LARGE + 7 * FONT_SCALE + FONT_HGT_LARGE + 7 * FONT_SCALE
  self.quantityEntry = ISTextEntryBox:new("1", (self.width - 30)/2, z, 30, FONT_HGT_SMALL + 4)
  self.quantityEntry:initialise()
  self.quantityEntry:instantiate()
  self.quantityEntry:setOnlyNumbers(true)
  self.quantityEntry:setMaxTextLength(3)
  self:addChild(self.quantityEntry)

  local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
  local buttonY = self.height - 10 * FONT_SCALE - btnHgt
  self.buyButton = ISButton:new(self.width/2 - 50 - 10, buttonY, 50, btnHgt, "BUY", self, ISBuyModal.onOptionMouseDown)
  self.buyButton.internal = "BUY"
  self.buyButton:initialise()
  self.buyButton:instantiate()
  self:addChild(self.buyButton)

  self.cancelButton = ISButton:new(self.width/2 + 10, buttonY, 50, btnHgt, getText("UI_btn_close"), self, ISBuyModal.onOptionMouseDown)
  self.cancelButton.internal = "CANCEL"
  self.cancelButton:initialise()
  self.cancelButton:instantiate()
  self:addChild(self.cancelButton)
end

function ISBuyModal:onOptionMouseDown(button, x, y)
  if button.internal == "CANCEL" then
    self:close()
  elseif button.internal == "BUY" then
    if tonumber(self.quantityEntry:getText()) > self.container:getCountType(self.itemType) then
      self.noticeText = "Invalid quantity."
    elseif self:hasCurrency() then
      self:doPayment()
      self:doPurchase()
      self:close()
    else
      self.noticeText = "Not enough currency."
    end
  end
end

function ISBuyModal:hasCurrency()
  if getActivatedMods():contains('BetterMoneySystem') then
    return getMoneyCountIncludingWallets(getPlayer():getInventory()) >= tonumber(self.price) * tonumber(self.quantityEntry:getText())
  else
    return getPlayer():getInventory():getCountType(SandboxVars.PlayerShops.CurrencyItem) >= tonumber(self.price) * tonumber(self.quantityEntry:getText())
  end
end

function ISBuyModal:doPayment()
  local inventory = getPlayer():getInventory()
  local price = tonumber(self.price) * tonumber(self.quantityEntry:getText())
  if getActivatedMods():contains('BetterMoneySystem') then
    -- this algorithm is a fucking monster
    local sum = 0

    for walletType,_ in pairs(BMSATM.Money.Wallets) do
      local wallets = inventory:getAllTypeRecurse(walletType)
      for i = 0, wallets:size() -1 do
        wallet = wallets:get(i)
        if wallet:getModData() then
          if wallet:getModData().moneyCount >= price - sum then -- enough money in wallet to cover full remaining sum
            wallet:getModData().moneyCount = wallet:getModData().moneyCount - (price - sum)
            sum = price
          else -- empty the wallet
            sum = sum + wallet:getModData().moneyCount
            wallet:getModData().moneyCount = 0
          end
        end
      end
    end

    if sum < price then -- not enough money in wallets, use loose money
      for k,v in pairs(BMSATM.Money.Values) do
        if sum >= price then break end
        local items = inventory:getAllTypeRecurse(k)
        for i = 0, items:size() - 1 do
          if sum >= price then break end
          sum = sum + v.v
          local item = items:get(i)
          inventory:Remove(item)
          if sum > price then
            BMSATM.Money.ATM.withdrawalMoney(getPlayer(), sum - price)
          end
        end
      end
    end
    createMoney(self.container, price)
  else
    local items = inventory:FindAndReturn(SandboxVars.PlayerShops.CurrencyItem, price)
    for i = 0, items:size() - 1 do
      local item = items:get(i)
      inventory:Remove(item)
      self.container:addItemOnServer(item)
      self.container:AddItem(item)
    end
  end
end

function ISBuyModal:doPurchase()
  local inventory = getPlayer():getInventory()
  for i = 1, tonumber(self.quantityEntry:getText()) do
    local item = self.container:getFirstType(self.itemType)
    self.container:removeItemOnServer(item)
    inventory:AddItem(item)
  end
end

function ISBuyModal:render()
  local z = 10 * FONT_SCALE
  self:drawText(self.itemName, (self.width - getTextManager():MeasureStringX(UIFont.Large, self.itemName)) / 2, z, 1,1,1,1, UIFont.Large)

  z = z + FONT_HGT_LARGE + 7 * FONT_SCALE
  self:drawRectBorder((self.width - FONT_HGT_LARGE)/2 - 1, z - 1, FONT_HGT_LARGE + 3, FONT_HGT_LARGE + 3, 1, self.borderColor.r, self.borderColor.g, self.borderColor.b);
  self:drawTextureScaledAspect2(self.texture, (self.width - FONT_HGT_LARGE)/2, z, FONT_HGT_LARGE, FONT_HGT_LARGE, 1, 1, 1, 1)

  z = z + FONT_HGT_LARGE + 7 * FONT_SCALE
  local priceText = self.price .. " x "
  self:drawText(priceText, self.quantityEntry:getX() - getTextManager():MeasureStringX(UIFont.Medium, priceText) - 1, z, 1,1,1,1, UIFont.Medium)
  local quantity = tonumber(self.quantityEntry:getText())
  local total = "= 0"
  if quantity then
    total = "= " .. tostring(tonumber(self.price) * quantity)
  end
  self:drawText(total, self.quantityEntry:getX() + self.quantityEntry.width + 4, z, 1,1,1,1, UIFont.Medium)

  if self.noticeText then
    z = z + FONT_HGT_MEDIUM
    self:drawText(self.noticeText, (self.width - getTextManager():MeasureStringX(UIFont.Small, self.noticeText)) / 2, z, 1,0,0,1, UIFont.Small)
  end
end

function ISBuyModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function ISBuyModal:new(x, y, width, height, container, item, price)
    local o = {}
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.variableColor = {r=0.9, g=0.55, b=0.1, a=1}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
    o.moveWithMouse = true
    o.container = container
    o.itemName = item:getDisplayName()
    o.itemType = item:getType()
    o.texture = item:getTexture()
    o.price = price
    return o
end

return ISBuyModal
