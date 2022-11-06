-- written by albion#0123

local ISShopAccessPanel = ISPanel:derive("ISShopAccessPanel")
local ISShopAddCoownerModal = require 'ISShopAddCoownerModal'

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL/14

function ISShopAccessPanel:initialise()
    ISPanel.initialise(self);
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2
    local entryHgt = FONT_HGT_MEDIUM + 2 * 2
    local bottomHgt = 5 + FONT_HGT_SMALL * 2 + 5 + btnHgt + 20 + FONT_HGT_LARGE + HEADER_HGT + entryHgt

    self.closeButton = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, 'CLOSE', self, ISShopAccessPanel.onClick)
    self.closeButton.internal = "CLOSE"
    self.closeButton.anchorTop = false
    self.closeButton.anchorBottom = true
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.closeButton)

    self.addButton = ISButton:new((self:getWidth() - btnWid) / 2, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, 'ADD', self, ISShopAccessPanel.onClick)
    self.addButton.internal = 'ADD'
    self.addButton.anchorTop = false
    self.addButton.anchorBottom = true
    self.addButton:initialise()
    self.addButton:instantiate()
    self.addButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.addButton)

    self.revokeButton = ISButton:new(self:getWidth() - btnWid - 10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, 'REVOKE', self, ISShopAccessPanel.onClick)
    self.revokeButton.internal = 'REVOKE'
    self.revokeButton.anchorTop = false
    self.revokeButton.anchorBottom = true
    self.revokeButton:initialise()
    self.revokeButton:instantiate()
    self.revokeButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.revokeButton)

    self.datas = ISScrollingListBox:new(0, HEADER_HGT, self.width, self.height - btnHgt - padBottom * 2 - HEADER_HGT)
    self.datas:initialise()
    self.datas:instantiate()
    self.datas.itemheight = FONT_HGT_SMALL + 4 * 2
    self.datas.font = UIFont.NewSmall   
    self.datas.selected = 0
    self.datas.joypadParent = self
    self.datas.drawBorder = true
    self:addChild(self.datas)

    for k,v in pairs(self.shopData.coowners) do
        if v == k .. ' (offline)' then
            local playerObj = getPlayerFromUsername(k)
            if playerObj then
              v = playerObj:getFullName()
              self.shopData.coowners[k] = v
              self.shop:transmitModData()
            end
        end
        self.datas:addItem(v, k)
    end
end

function ISShopAccessPanel:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function ISShopAccessPanel:onClick(button)
    if button.internal == 'CLOSE' then
        self:close()
    elseif button.internal == 'ADD' then
        if self.addPanel then
            self.addPanel:close()
        end
        self.addPanel = ISShopAddCoownerModal:new(self:getAbsoluteX() + (self.width - 300 * FONT_SCALE)/2, self:getAbsoluteY() + (self.height - 150 * FONT_SCALE)/2, 300 * FONT_SCALE, 150 * FONT_SCALE, self.shopData, self.shop, ISShopAccessPanel.instance)
        self.addPanel:initialise()
        self.addPanel:addToUIManager()
    elseif button.internal == 'REVOKE' then
        self.shopData.coowners[self.datas.items[self.datas.selected].item] = nil
        self.shop:transmitModData()
        self.datas:removeItemByIndex(self.datas.selected)
    end
end

function ISShopAccessPanel:close()
    if self.addPanel then
        self.addPanel:close()
    end
    self:setVisible(false)
    self:removeFromUIManager()
    ISShopAccessPanel.instance = nil
end

function ISShopAccessPanel:new(x, y, width, height, shopData, shop)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2)
    y = getCore():getScreenHeight() / 2 - (height / 2)
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.width = width
    o.height = height
    o.moveWithMouse = true
    o.shopData = shopData
    o.shop = shop
    ISShopAccessPanel.instance = o
    return o
end

return ISShopAccessPanel