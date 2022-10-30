-- sell modal and related code is written by albion#0123, based on Browser8's code

local ISSellModal = ISPanel:derive("ISSellModal")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL/14

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

function ISSellModal:createChildren()
  local z = 10 * FONT_SCALE + FONT_HGT_LARGE + 7 * FONT_SCALE + FONT_HGT_LARGE + 7 * FONT_SCALE
  self.quantityEntry = ISTextEntryBox:new("1", (self.width - 30)/2, z, 30, FONT_HGT_SMALL + 4)
  self.quantityEntry:initialise()
  self.quantityEntry:instantiate()
  self.quantityEntry:setOnlyNumbers(true)
  self.quantityEntry:setMaxTextLength(3)
  self:addChild(self.quantityEntry)

  local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
  local buttonY = self.height - 10 * FONT_SCALE - btnHgt
  self.sellButton = ISButton:new(self.width/2 - 50 - 10, buttonY, 50, btnHgt, "SELL", self, ISSellModal.onOptionMouseDown)
  self.sellButton.internal = "SELL"
  self.sellButton:initialise()
  self.sellButton:instantiate()
  self:addChild(self.sellButton)

  self.cancelButton = ISButton:new(self.width/2 + 10, buttonY, 50, btnHgt, getText("UI_btn_close"), self, ISSellModal.onOptionMouseDown)
  self.cancelButton.internal = "CANCEL"
  self.cancelButton:initialise()
  self.cancelButton:instantiate()
  self:addChild(self.cancelButton)
end

function ISSellModal:onOptionMouseDown(button, x, y)
    if button.internal == "CANCEL" then
        self:close()
    elseif button.internal == "SELL" then
        if tonumber(self.quantityEntry:getText()) > getPlayer():getInventory():getCountType(self.itemType) then
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

function ISSellModal:hasCurrency()
  if getActivatedMods():contains('BetterMoneySystem') then
    return BMSATM.Money.getMoneyCountInContainer(self.container) >= tonumber(self.price) * tonumber(self.quantityEntry:getText())
  else
    return self.container:getCountType(SandboxVars.PlayerShops.CurrencyItem) >= tonumber(self.price) * tonumber(self.quantityEntry:getText())
  end
end

function ISSellModal:doPayment()
  local inventory = getPlayer():getInventory()
  local price = tonumber(self.price) * tonumber(self.quantityEntry:getText())
  if getActivatedMods():contains('BetterMoneySystem') then
    local sum = 0
    for k,v in pairs(BMSATM.Money.Values) do
      if sum >= price then break end
      local items = self.container:getAllTypeRecurse(k)
      for i = 0, items:size() - 1 do
        if sum >= price then break end
        sum = sum + v.v
        local item = items:get(i)
        self.container:Remove(item)
        self.container:removeItemOnServer(item)
        if sum > price then
          createMoney(self.container, sum - price)
        end
      end
    end
    BMSATM.Money.ATM.withdrawalMoney(getPlayer(), price)
  else
    local items = self.container:FindAndReturn(SandboxVars.PlayerShops.CurrencyItem, price)
    for i = 0, items:size() - 1 do
      local item = items:get(i)
      self.container:Remove(item)
      self.container:removeItemOnServer(item)
      inventory:AddItem(item)
    end
  end
end

function ISSellModal:doPurchase()
  local inventory = getPlayer():getInventory()
  for i = 1, tonumber(self.quantityEntry:getText()) do
    local item = inventory:getFirstType(self.itemType)
    inventory:Remove(item)
    self.container:addItemOnServer(item)
    self.container:AddItem(item)
  end
end

function ISSellModal:render()
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

function ISSellModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function ISSellModal:new(x, y, width, height, container, item, price)
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
    if instanceof(item, 'InventoryItem') then
      o.itemType = item:getType()
      o.texture = item:getTexture()
    else
      o.itemType = item:getName()
      o.texture = item:getNormalTexture()
    end
    o.price = price * -1
    return o
end

return ISSellModal
