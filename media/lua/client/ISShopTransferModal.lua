-- ownership modal and related code is written by albion#0123, based on Browser8's code

local ISShopTransferModal = ISPanel:derive("ISShopTransferModal")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL/14

function ISShopTransferModal:createChildren()
  local z = 10 * FONT_SCALE + FONT_HGT_LARGE + 7 * FONT_SCALE + FONT_HGT_LARGE + 7 * FONT_SCALE
  self.usernameEntry = ISTextEntryBox:new('Username', (self.width - 100)/2, z, 100, FONT_HGT_SMALL + 4)
  self.usernameEntry:initialise()
  self.usernameEntry:instantiate()
  self.usernameEntry.onTextChange = self.onTextChange
  self:addChild(self.usernameEntry)

  local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
  local buttonY = self.height - 10 * FONT_SCALE - btnHgt
  self.transferButton = ISButton:new(self.width/2 - 50 - 10, buttonY, 50, btnHgt, "TRANSFER", self, ISShopTransferModal.onOptionMouseDown)
  self.transferButton.internal = "TRANSFER"
  self.transferButton:initialise()
  self.transferButton:instantiate()
  self.transferButton:setEnable(false)
  self:addChild(self.transferButton)

  self.cancelButton = ISButton:new(self.width/2 + 10, buttonY, 50, btnHgt, getText("UI_btn_close"), self, ISShopTransferModal.onOptionMouseDown)
  self.cancelButton.internal = "CANCEL"
  self.cancelButton:initialise()
  self.cancelButton:instantiate()
  self:addChild(self.cancelButton)
end

function ISShopTransferModal.onTextChange(textBox)
  ISShopTransferModal.instance.transferButton:setEnable(false)
  local potentialOwner = getPlayerFromUsername(textBox:getInternalText())
  if not potentialOwner then
    ISShopTransferModal.instance.noticeText = 'No online player with that username found.'
  elseif potentialOwner:getSteamID() == ISShopTransferModal.instance.shopData.owner then
    ISShopTransferModal.instance.noticeText = 'Player already owns this shop.'
  else
    ISShopTransferModal.instance.noticeText = 'Player ' .. potentialOwner:getFullName() .. ' found.'
    ISShopTransferModal.instance.transferButton:setEnable(true)
  end
end

function ISShopTransferModal:onOptionMouseDown(button, x, y)
    if button.internal == "CANCEL" then
        self:close()
    elseif button.internal == "TRANSFER" then
      local potentialOwner = getPlayerFromUsername(self.usernameEntry:getInternalText()) and getPlayerFromUsername(self.usernameEntry:getInternalText()):getSteamID()
      if potentialOwner then
        self.shopData.owner =  potentialOwner
        self.editUI:close()
      else
        self.noticeText = 'Unknown error'
      end
    end
end

function ISShopTransferModal:render()
  local z = 10 * FONT_SCALE
  self:drawText('TRANFER OWNERSHIP', (self.width - getTextManager():MeasureStringX(UIFont.Large, 'TRANFER OWNERSHIP')) / 2, z, 1,1,1,1, UIFont.Large)

  if self.noticeText then
    z = z + FONT_HGT_MEDIUM
    self:drawText(self.noticeText, (self.width - getTextManager():MeasureStringX(UIFont.Small, self.noticeText)) / 2, z, 1,0,0,1, UIFont.Small)
  end
end

function ISShopTransferModal:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ISShopTransferModal.instance = nil
end

function ISShopTransferModal:new(x, y, width, height, shopData, editUI)
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
    o.editUI = editUI
    ISShopTransferModal.instance = o
    return o
end

return ISShopTransferModal
