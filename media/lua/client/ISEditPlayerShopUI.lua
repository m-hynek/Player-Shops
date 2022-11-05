
local ISEditPlayerShopUI = ISPanel:derive("ISEditPlayerShopUI")
local ISBuyOrderPanel = require 'ISBuyOrderPanel'
local ISShopTransferModal = require 'ISShopTransferModal'
local ISShopAccessPanel = require 'ISShopAccessPanel'

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL/14
local inset = 2

local function GetType(item)
  if instanceof(item, 'Item') then
    return item:getName()
  elseif instanceof(item, 'InventoryItem') then
    return item:getType()
  end
  return false
end

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
    return ISEditPlayerShopUI.instance.itemList.itemPrices[item:getFullType()]
  elseif instanceof(item, 'Item') then
    return ISEditPlayerShopUI.instance.itemList.sellItems[item:getFullName()]
  end
  return false
end

function ISEditPlayerShopUI:initialise()
    ISPanel.initialise(self)
    self:create()
end


function ISEditPlayerShopUI:setVisible(visible)
    self.javaObject:setVisible(visible)
end

function ISEditPlayerShopUI:render()
    local z = 15 * FONT_SCALE
    self:drawText("Shop Name", self:getWidth()*0.025, z, 1,1,1,1, UIFont.Small)

    z = z + FONT_HGT_SMALL + 2 * FONT_SCALE + self.nameEntry:getHeight() + 10 * FONT_SCALE
    self:drawText("Description", self:getWidth()*0.025, z, 1,1,1,1, UIFont.Small)

    z = z + FONT_HGT_SMALL + 2 * FONT_SCALE + self.descriptionEntry:getHeight() + 10 * FONT_SCALE
    self:drawText("Items", self:getWidth()*0.025, z, 1,1,1,1, UIFont.Small)

end

local function OnServerCommand(module, command, arguments)
	if module ~= "PlayerShops" then return end
  if command == "load" then
    local rows = ISEditPlayerShopUI.instance.itemList.items
    for i, v in ipairs(rows) do
      v.priceEntry:setText(arguments[1][GetFullType(v.item)])
    end
    for item,price in pairs(arguments[2]) do
      local instance = getScriptManager():getItem(item)
      if instance then
        ISEditPlayerShopUI.instance:addShopItem(instance)
        ISEditPlayerShopUI.instance.itemList.items[#ISEditPlayerShopUI.instance.itemList.items].priceEntry:setText(price)
      end
    end
  end
  Events.OnServerCommand.Remove(OnServerCommand)
end

function ISEditPlayerShopUI:create()
    local btnWid = 125 * FONT_SCALE
    local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
    local padBottom = 10 * FONT_SCALE

    local z = 15 * FONT_SCALE + FONT_HGT_SMALL + 2 * FONT_SCALE
    local height = inset + FONT_HGT_SMALL + inset
    self.nameEntry = ISTextEntryBox:new(self.shopData.name, padBottom, z, self:getWidth() - padBottom * 2, height)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self.nameEntry:setMaxTextLength(40)
    self:addChild(self.nameEntry)

    z = z + height + 10 * FONT_SCALE + FONT_HGT_SMALL + 2 * FONT_SCALE
    height = inset + 6 * FONT_HGT_SMALL + inset
    self.descriptionEntry = ISTextEntryBox:new(self.shopData.description or "No description set.", padBottom, z, self:getWidth() - padBottom * 2, height)
    self.descriptionEntry:initialise()
    self.descriptionEntry:instantiate()
    self.descriptionEntry:setMultipleLine(true)
    self.descriptionEntry:setMaxLines(6)
    self:addChild(self.descriptionEntry)

    z = z + height + 10 * FONT_SCALE + FONT_HGT_SMALL + 2 * FONT_SCALE
    height = self:getHeight() - z - padBottom - btnHgt * 2 - 10 * FONT_SCALE
    self.itemList = ISScrollingListBox:new(padBottom, z, self:getWidth() - padBottom * 2, height)
    self.itemList:initialise()
    self.itemList:instantiate()
    self.itemList.font = UIFont.Medium;
    self.itemList.itemPadY = 5 * FONT_SCALE
    self.itemList.itemheight = FONT_HGT_MEDIUM + 5 * FONT_SCALE * 2
    self.itemList.texturePadY = (self.itemList.itemheight - FONT_HGT_MEDIUM) / 2
    self.itemList.doDrawItem = self.doDrawItem
    self.itemList.onMouseWheel = function(self, del)
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
    self.itemList.setYScroll = function(self, y)
      ISUIElement.setYScroll(self, y)
      y = self.smoothScrollY or y
      local topRow = self:rowAt(0, -y + self.itemheight - (self.itemheight - FONT_HGT_SMALL - 4) / 2)
      local bottomRow = self:rowAt(0, self:getHeight() - y - self.itemheight + (self.itemheight - FONT_HGT_SMALL - 4) / 2)
      if bottomRow == -1 then bottomRow = #self.items end
      for i, v in ipairs(self.items) do
        if (i < topRow) or (i > bottomRow) then
          v.priceEntry:setVisible(false)
          y = y + self.itemheight
        else
          v.priceEntry:setY(y + (self.itemheight - FONT_HGT_SMALL - 4) / 2)
          v.priceEntry:setVisible(true)
          y = y + self.itemheight
        end
      end
    end
    self.itemList.drawBorder = true
    self:addChild(self.itemList)
    self.itemList.itemPrices = {}
    self.itemList.sellItems = {}
    local items = self.container:getItems()
    for i = 0, items:size() - 1 do
      local item = items:get(i)
      self:addShopItem(item)
    end
    Events.OnServerCommand.Add(OnServerCommand)
    sendClientCommand("PlayerShops", "load", {self.shopData.UUID, self.itemList.itemPrices})

    z = z + height + 5 * FONT_SCALE
    self.save = ISButton:new(padBottom, z, btnWid, btnHgt, getText("UI_btn_save"), self, ISEditPlayerShopUI.onOptionMouseDown)
    self.save.internal = "SAVE"
    self.save:initialise()
    self.save:instantiate()
    self.save.borderColor = self.buttonBorderColor
    self:addChild(self.save)

    self.cancel = ISButton:new(self:getWidth() - btnWid - padBottom, z, btnWid, btnHgt, getText("UI_btn_close"), self, ISEditPlayerShopUI.onOptionMouseDown)
    self.cancel.internal = "CANCEL"
    self.cancel:initialise()
    self.cancel:instantiate()
    self.cancel.borderColor = self.buttonBorderColor
    self:addChild(self.cancel)

    self.buyOrder = ISButton:new((self:getWidth() - btnWid) / 2, z, btnWid, btnHgt, 'BUY ORDER', self, ISEditPlayerShopUI.onOptionMouseDown)
    self.buyOrder.internal = "BUYORDER"
    self.buyOrder:initialise()
    self.buyOrder:instantiate()
    self.buyOrder.borderColor = self.buttonBorderColor
    self:addChild(self.buyOrder)

    z = z + btnHgt + 5 * FONT_SCALE
    self.transfer = ISButton:new(padBottom, z, btnWid * 1.5, btnHgt, 'TRANSFER OWNERSHIP', self, ISEditPlayerShopUI.onOptionMouseDown)
    self.transfer.internal = "TRANSFER"
    self.transfer:initialise()
    self.transfer:instantiate()
    self.transfer.borderColor = self.buttonBorderColor
    self:addChild(self.transfer)

    self.access = ISButton:new(self:getWidth() - (btnWid * 1.5) - padBottom, z, btnWid * 1.5, btnHgt, 'MANAGE ACCESS', self, ISEditPlayerShopUI.onOptionMouseDown)
    self.access.internal = "ACCESS"
    self.access:initialise()
    self.access:instantiate()
    self.access.borderColor = self.buttonBorderColor
    self:addChild(self.access)
end

function ISEditPlayerShopUI:doDrawItem(y, item, alt)
	self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)
  local icon
  local count
  if instanceof(item.item, 'InventoryItem') then
    icon = item.item:getTexture()
    count = self.parent.container:getCountType(item.item:getType())
  else
    icon = item.item:getNormalTexture()
    count = 'Buying'
  end
  self:drawTextureScaledAspect2(icon, 5, y + self.texturePadY, FONT_HGT_MEDIUM, FONT_HGT_MEDIUM, 1, 1, 1, 1)
	self:drawText(item.text .. " (" .. count .. ")", 10 + FONT_HGT_MEDIUM, y + self.itemPadY, 0.7, 0.7, 0.7, 1.0, self.font)
  --self:drawText(self.itemPrices[item.item:getType()], self:getWidth() - 75, y + self.itemPadY, 0.7, 0.7, 0.7, 1.0, self.font)

	y = y + item.height
	return y
end

function ISEditPlayerShopUI:addShopItem(item)
  if not hasPrice(item) and GetFullType(item) ~= SandboxVars.PlayerShops.CurrencyItem then
    if getActivatedMods():contains('ZZZProjectRP') and ProjectRP.Client.Money.Values[GetType(item)] then return end
    if instanceof(item, 'InventoryItem') then
      self.itemList.itemPrices[item:getFullType()] = "Loading..."
    else
      self.itemList.sellItems[item:getFullName()] = true
    end
    local row = self.itemList:addItem(item:getDisplayName(), item)
    row.priceEntry = ISTextEntryBox:new("Loading...", self.itemList:getWidth() - 75 - self.itemList.vscroll.width, 0, 70, inset + FONT_HGT_SMALL + inset)
    row.priceEntry:initialise()
    row.priceEntry:instantiate()
    row.priceEntry:setMaxTextLength(10)
    row.priceEntry:setOnlyNumbers(true)
    self.itemList:addChild(row.priceEntry)
  end
  self.itemList:setYScroll(0)
end

function ISEditPlayerShopUI:onOptionMouseDown(button, x, y)
  if button.internal == "CANCEL" then
    self:close()
  elseif button.internal == "SAVE" then
    self.shopData.name = self.nameEntry:getText()
    self.shopData.description = self.descriptionEntry:getText()
    self.shop:transmitModData()
    local itemPrices = {}
    local sellItems = {}
    for i, v in ipairs(self.itemList.items) do
      local price = v.priceEntry:getText()
      if not tonumber(price) then price = '0' end
      if instanceof(v.item, 'InventoryItem') then
        if tonumber(price) > 0 then
          itemPrices[GetFullType(v.item)] = price
        else
          itemPrices[GetFullType(v.item)] = '0'
        end
      else
        if tonumber(price) < 0 then
          print('added to sellItems')
          sellItems[GetFullType(v.item)] = price
        end
      end
    end
    sendClientCommand("PlayerShops", "save", {self.shopData.UUID, itemPrices, sellItems})
    self:close()
  elseif button.internal == "BUYORDER" then
    if self.buyOrderPanel then
      self.buyOrderPanel:close()
    end
    self.buyOrderPanel = ISBuyOrderPanel:new(50, 200, 850, 650, ISEditPlayerShopUI.instance)
    self.buyOrderPanel:initialise()
    self.buyOrderPanel:addToUIManager()
  elseif button.internal == 'TRANSFER' then
    if self.transferPanel then
      self.transferPanel:close()
    end
    self.transferPanel = ISShopTransferModal:new(self:getAbsoluteX() + (self.width - 300 * FONT_SCALE)/2, self:getAbsoluteY() + (self.height - 150 * FONT_SCALE)/2, 300 * FONT_SCALE, 150 * FONT_SCALE, self.shopData, ISEditPlayerShopUI.instance)
    self.transferPanel:initialise()
    self.transferPanel:addToUIManager()
  elseif button.internal == 'ACCESS' then
    if self.accessPanel then
      self.accessPanel:close()
    end
    self.accessPanel = ISShopAccessPanel:new(self:getAbsoluteX() + (self.width - 300 * FONT_SCALE)/2, self:getAbsoluteY() + (self.height - 150 * FONT_SCALE)/2, 300 * FONT_SCALE, 300 * FONT_SCALE, self.shopData)
    self.accessPanel:initialise()
    self.accessPanel:addToUIManager()
  end
end

function ISEditPlayerShopUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if self.buyOrderPanel then
      self.buyOrderPanel:close()
    end
    if self.transferPanel then
      self.transferPanel:close()
    end
    if self.accessPanel then
      self.accessPanel:close()
    end
    ISEditPlayerShopUI.instance = nil
end

function ISEditPlayerShopUI:new(x, y, width, height, shop, shopData)
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
    ISEditPlayerShopUI.instance = o
    return o
end

return ISEditPlayerShopUI
