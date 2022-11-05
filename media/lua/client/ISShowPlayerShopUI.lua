
local ISShowPlayerShopUI = ISPanel:derive("ISShowPlayerShopUI")
local ISBuyModal = require "ISBuyModal"
local ISSellModal = require "ISSellModal"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL/14

--[[local function GetType(item)
  if instanceof(item, 'Item') then
    return item:getName()
  elseif instanceof(item, 'InventoryItem') then
    return item:getType()
  end
  return false
end]]

local function GetFullType(item)
  if instanceof(item, 'Item') then
    return item:getFullName()
  elseif instanceof(item, 'InventoryItem') then
    return item:getFullType()
  end
  return false
end

local function hasPrice(item)
  if instanceof(item, 'InventoryItem') then
    return ISShowPlayerShopUI.instance.itemList.itemPrices[item:getFullType()]
  elseif instanceof(item, 'Item') then
    return ISShowPlayerShopUI.instance.itemList.sellPrices[item:getFullName()]
  end
  return false
end

function ISShowPlayerShopUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function ISShowPlayerShopUI:setVisible(visible)
    self.javaObject:setVisible(visible)
end

function ISShowPlayerShopUI:render()
    local z = 15 * FONT_SCALE
    self:drawText(self.shopData.name, (self.width - getTextManager():MeasureStringX(UIFont.Large, self.shopData.name)) / 2, z, 1,1,1,1, UIFont.Large)

    z = z + FONT_HGT_LARGE + 15 * FONT_SCALE + self.descriptionEntry:getHeight() + 10 * FONT_SCALE
    self:drawText("Items", self:getWidth()*0.025, z, 1,1,1,1, UIFont.Small)

    if self.itemList.mouseoverselected == -1 then
      self.buyButton:setVisible(false)
    else
      self.buyButton:setY((self.itemList.mouseoverselected - 1) * self.itemList.itemheight + self.itemList:getYScroll() + (self.itemList.itemheight - self.buyButton.height) / 2)
      self.buyButton:setVisible(true)
      local item = self.itemList.items[self.itemList.mouseoverselected].item
      local price
      if instanceof(item, 'InventoryItem') then
        price = self.itemList.itemPrices[GetFullType(item)]
      else
        price = self.itemList.sellPrices[GetFullType(item)]
      end
      if tonumber(price) then
        if tonumber(price) > 0 then
          self.buyButton:setTitle('BUY')
        else
          self.buyButton:setTitle('SELL')
        end
      elseif price ~= 'Loading...' and isDebugEnabled() then
        if not GetFullType(item.item) then
          print('PlayerShops: invalid item ' .. type(item.item) .. ' ' .. tostring(item.item))
        else
          print('PlayerShops: invalid price for item ' .. GetFullType(item.item) .. ' : ' .. (tostring(price) or type(price)))
        end
      end
    end
end

local function ShowPlayerOnServerCommand(module, command, arguments)
	if module ~= "PlayerShops" then return end
  if command == "load" then
    local rows = ISShowPlayerShopUI.instance.itemList.items
    for i=#rows,1,-1 do
      local v = rows[i]
      local price = arguments[1][GetFullType(v.item)] or '0'
      ISShowPlayerShopUI.instance.itemList.itemPrices[GetFullType(v.item)] = price
      if price == '0' then
        ISShowPlayerShopUI.instance.itemList:removeItemByIndex(i)
      end
    end
    for item,price in pairs(arguments[2]) do
      local instance = getScriptManager():getItem(item)
      if instance then
        ISShowPlayerShopUI.instance:addShopItem(instance)
        ISShowPlayerShopUI.instance.itemList.sellPrices[item] = price
      end
    end
  end
  Events.OnServerCommand.Remove(ShowPlayerOnServerCommand)
end

function ISShowPlayerShopUI:create()
    local btnWid = 125 * FONT_SCALE
    local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
    local padBottom = 10 * FONT_SCALE

    local z = 15 * FONT_SCALE + FONT_HGT_LARGE + 15 * FONT_SCALE
    local inset = 2
    local height = inset + 6 * FONT_HGT_SMALL + inset
    self.descriptionEntry = ISTextEntryBox:new(self.shopData.description or "No description set.", padBottom, z, self:getWidth() - padBottom * 2, height)
    self.descriptionEntry:initialise()
    self.descriptionEntry:instantiate()
    self.descriptionEntry:setMultipleLine(true)
    self.descriptionEntry:setMaxLines(6)
    self.descriptionEntry:setEditable(false)
    self:addChild(self.descriptionEntry)

    z = z + height + 10 * FONT_SCALE + FONT_HGT_SMALL + 2 * FONT_SCALE
    height = self:getHeight() - z - padBottom - btnHgt - 10 * FONT_SCALE
    self.itemList = ISScrollingListBox:new(padBottom, z, self:getWidth() - padBottom * 2, height)
    self.itemList:initialise()
    self.itemList:instantiate()
    self.itemList.font = UIFont.Medium;
    self.itemList.itemPadY = 5 * FONT_SCALE
    self.itemList.itemheight = FONT_HGT_MEDIUM + 5 * FONT_SCALE * 2
    self.itemList.texturePadY = (self.itemList.itemheight - FONT_HGT_MEDIUM) / 2
    self.itemList.doDrawItem = self.doDrawItem
    self.itemList.onMouseWheel = ISShowPlayerShopUI.onMouseWheel
    self.itemList.drawBorder = true
    self:addChild(self.itemList)
    self.itemList.itemPrices = {} --TODO refactor this
    self.itemList.sellPrices = {}
    local items = self.container:getItems()
    for i = 0, items:size() - 1 do
      local item = items:get(i)
      self:addShopItem(item)
    end
    self.itemList:setYScroll(0)
    self.itemList.mouseoverselected = -1
    Events.OnServerCommand.Add(ShowPlayerOnServerCommand)
    sendClientCommand("PlayerShops", "load", {self.shopData.UUID, self.itemList.itemPrices})

    self.buyButton = ISButton:new(self.itemList:getWidth() - 75 - self.itemList.vscroll.width, 0, 70, FONT_HGT_SMALL + 8 * FONT_SCALE, "BUY", self, ISShowPlayerShopUI.onOptionMouseDown)
    self.buyButton.internal = "BUY"
    self.buyButton:initialise()
    self.buyButton:instantiate()
    self.buyButton.borderColor = self.buttonBorderColor
    self.buyButton:setVisible(false)
    self.itemList:addChild(self.buyButton)

    z = z + height + 10 * FONT_SCALE
    self.cancel = ISButton:new(self:getWidth() - btnWid - padBottom, z, btnWid, btnHgt, getText("UI_btn_close"), self, ISShowPlayerShopUI.onOptionMouseDown)
    self.cancel.internal = "CANCEL"
    self.cancel:initialise()
    self.cancel:instantiate()
    self.cancel.borderColor = self.buttonBorderColor
    self:addChild(self.cancel)
end

function ISShowPlayerShopUI.onMouseWheel(self, del)
  if not self:isVScrollBarVisible() then return true end
  local yScroll = self.smoothScrollTargetY or self:getYScroll()
  local topRow = self:rowAt(0, -yScroll)
  if self.items[topRow] then
    if not self.smoothScrollTargetY then self.smoothScrollY = self:getYScroll() end
    local y = self:topOfItem(topRow)
    if del < 0 then
      if yScroll == -y and topRow > 1 then
        local prev = self:prevVisibleIndex(topRow)
        y = self:topOfItem(prev)
      end
      self.smoothScrollTargetY = -y
    else
      self.smoothScrollTargetY = -(y + self.items[topRow].height)
    end
  else
    self:setYScroll(self:getYScroll() - (del*18))
  end
  return true
end

function ISShowPlayerShopUI:doDrawItem(y, item, alt)
	self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)
  local icon
  local count
  local price
  if instanceof(item.item, 'InventoryItem') then
    icon = item.item:getTexture()
    count = self.parent.container:getCountType(item.item:getType())
    price = self.itemPrices[GetFullType(item.item)]
  else
    icon = item.item:getNormalTexture()
    count = 'Buying'
    price = self.sellPrices[GetFullType(item.item)]
  end
  self:drawTextureScaledAspect2(icon, 5, y + self.texturePadY, FONT_HGT_MEDIUM, FONT_HGT_MEDIUM, 1, 1, 1, 1)
	self:drawText(item.text .. " (" .. count .. ")", 10 + FONT_HGT_MEDIUM, y + self.itemPadY, 0.7, 0.7, 0.7, 1.0, self.font)

  if tonumber(price) then
    if tonumber(price) > 0 then
      self:drawText(price, self:getWidth() - 5 - getTextManager():MeasureStringX(self.font, price) - self.vscroll.width, y + self.itemPadY, 0.7, 0.7, 0.7, 1.0, self.font)
    else
      price = tostring(tonumber(price) * - 1)
      self:drawText(price, self:getWidth() - 5 - getTextManager():MeasureStringX(self.font, price) - self.vscroll.width, y + self.itemPadY, 0, 0.7, 0, 1.0, self.font)
    end
  elseif price ~= 'Loading...' then
    if not GetFullType(item.item) and isDebugEnabled() then
      print('PlayerShops: invalid item ' .. type(item.item) .. ' ' .. tostring(item.item))
    else
      print('PlayerShops: invalid price for item ' .. GetFullType(item.item) .. ' : ' .. (tostring(price) or type(price)))
    end
  end

	y = y + item.height
	return y
end

function ISShowPlayerShopUI:addShopItem(item)
  if not hasPrice(item) and GetFullType(item) ~= SandboxVars.PlayerShops.CurrencyItem then
    if instanceof(item, 'InventoryItem') then
      self.itemList.itemPrices[GetFullType(item)] = "Loading..."
    else
      self.itemList.sellPrices[GetFullType(item)] = 'Loading...'
    end
    self.itemList:addItem(item:getDisplayName(), item)
  end
end

function ISShowPlayerShopUI:onOptionMouseDown(button, x, y)
  if button.internal == "CANCEL" then
    if self.buyModal then
      self.buyModal:close()
    end
    self:close()
  elseif button.internal == "BUY" then
    if self.buyModal then
      self.buyModal:close()
    end
    local item = self.itemList.items[self.itemList.mouseoverselected].item
    local price
    local modalType
    if instanceof(item, 'InventoryItem') then
      price = tonumber(self.itemList.itemPrices[GetFullType(item)])
      modalType = ISBuyModal
    else
      price = tonumber(self.itemList.sellPrices[GetFullType(item)])
      modalType = ISSellModal
    end
    if price then
      self.buyModal = modalType:new(self:getAbsoluteX() + (self.width - 300 * FONT_SCALE)/2, self:getAbsoluteY() + (self.height - 150 * FONT_SCALE)/2, 300 * FONT_SCALE, 150 * FONT_SCALE, self.container, item, price)
      self.buyModal:initialise()
      self.buyModal:addToUIManager()
    else
      if isDebugEnabled() then print('PlayerShops: Attempted buy/sell action on invalid priced item') end
    end
  end
end

function ISShowPlayerShopUI:close()
    if self.buyModal then
      self.buyModal:close()
    end
    self:setVisible(false)
    self:removeFromUIManager()
    ISShowPlayerShopUI.instance = nil
end

function ISShowPlayerShopUI:new(x, y, width, height, shop, shopData)
    local o = {}
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.variableColor={r=0.9, g=0.55, b=0.1, a=1}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
    o.moveWithMouse = true
    o.shop = shop
    o.container = shop:getContainer()
    o.shopData = shopData
    ISShowPlayerShopUI.instance = o
    return o
end

return ISShowPlayerShopUI