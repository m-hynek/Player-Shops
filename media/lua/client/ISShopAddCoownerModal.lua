-- transferal modal and related code is written by albion#0123, based on Browser8's code

local ISShopAddCoownerModal = ISPanel:derive("ISShopAddCoownerModal")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL/14

function ISShopAddCoownerModal:createChildren()
  local z = 10 * FONT_SCALE + FONT_HGT_LARGE + 7 * FONT_SCALE + FONT_HGT_LARGE + 7 * FONT_SCALE
  self.usernameEntry = ISTextEntryBox:new('Username', (self.width - 100)/2, z, 100, FONT_HGT_SMALL + 4)
  self.usernameEntry:initialise()
  self.usernameEntry:instantiate()
  self.usernameEntry.onTextChange = self.onTextChange
  self:addChild(self.usernameEntry)

  local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
  local buttonY = self.height - 10 * FONT_SCALE - btnHgt
  self.addButton = ISButton:new(self.width/2 - 50 - 10, buttonY, 50, btnHgt, "ADD", self, ISShopAddCoownerModal.onOptionMouseDown)
  self.addButton.internal = "ADD"
  self.addButton:initialise()
  self.addButton:instantiate()
  self.addButton:setEnable(false)
  self:addChild(self.addButton)

  self.cancelButton = ISButton:new(self.width/2 + 10, buttonY, 50, btnHgt, getText("UI_btn_close"), self, ISShopAddCoownerModal.onOptionMouseDown)
  self.cancelButton.internal = "CANCEL"
  self.cancelButton:initialise()
  self.cancelButton:instantiate()
  self:addChild(self.cancelButton)
end

function ISShopAddCoownerModal.onTextChange(textBox)
  ISShopAddCoownerModal.instance.addButton:setEnable(false)
  if textBox:getInternalText() == ISShopAddCoownerModal.instance.shopData.owner or ISShopAddCoownerModal.instance.shopData.coowners[textBox:getInternalText()] then
    ISShopAddCoownerModal.instance.noticeText = 'Player already has access to this shop.'
  else
    local name = getPlayerFromUsername(textBox:getInternalText()) and getPlayerFromUsername(textBox:getInternalText()):getFullName() or '(offline)'
    ISShopAddCoownerModal.instance.noticeText = 'Player character: ' .. name
    ISShopAddCoownerModal.instance.addButton:setEnable(true)
  end
end

function ISShopAddCoownerModal:onOptionMouseDown(button, x, y)
    if button.internal == "CANCEL" then
        self:close()
    elseif button.internal == "ADD" then
      local potentialCoowner = getPlayerFromUsername(self.usernameEntry:getInternalText())
      if potentialCoowner then
        self.shopData.coowners[self.usernameEntry:getInternalText()] = potentialCoowner:getFullName()
      else
        self.shopData.coowners[self.usernameEntry:getInternalText()] = self.usernameEntry:getInternalText() .. ' (offline)'
      end
      self.shop:transmitModData()
      self.accessPanel.datas:addItem(self.shopData.coowners[self.usernameEntry:getInternalText()], self.usernameEntry:getInternalText())
      self:close()
    end
end

function ISShopAddCoownerModal:render()
  local z = 10 * FONT_SCALE
  self:drawText('GRANT ACCESS', (self.width - getTextManager():MeasureStringX(UIFont.Large, 'GRANT ACCESS')) / 2, z, 1,1,1,1, UIFont.Large)

  if self.noticeText then
    z = z + FONT_HGT_MEDIUM
    self:drawText(self.noticeText, (self.width - getTextManager():MeasureStringX(UIFont.Small, self.noticeText)) / 2, z, 1,0,0,1, UIFont.Small)
  end
end

function ISShopAddCoownerModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ISShopAddCoownerModal.instance = nil
end

function ISShopAddCoownerModal:new(x, y, width, height, shopData, shop, accessPanel)
    local o = {}
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.variableColor = {r=0.9, g=0.55, b=0.1, a=1}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
    o.moveWithMouse = true
    o.shopData = shopData
    o.accessPanel = accessPanel
    o.shop = shop
    ISShopAddCoownerModal.instance = o
    return o
end

return ISShopAddCoownerModal
