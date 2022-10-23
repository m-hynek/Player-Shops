-- written by albion

ISBuyOrderPanel = ISPanel:derive("ISBuyOrderPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

function ISBuyOrderPanel:initialise()
    ISPanel.initialise(self);
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2
    local entryHgt = FONT_HGT_MEDIUM + 2 * 2
    local bottomHgt = 5 + FONT_HGT_SMALL * 2 + 5 + btnHgt + 20 + FONT_HGT_LARGE + HEADER_HGT + entryHgt

    self.closeButton = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, getText("IGUI_CraftUI_Close"), self, ISBuyOrderPanel.onClick)
    self.closeButton.internal = "CLOSE"
    self.closeButton.anchorTop = false
    self.closeButton.anchorBottom = true
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.closeButton)

    self.selectButton = ISButton:new(self:getWidth() - btnWid - 10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, 'SELECT', self, ISBuyOrderPanel.onClick)
    self.selectButton.internal = "SELECT"
    self.selectButton.anchorTop = false
    self.selectButton.anchorBottom = true
    self.selectButton:initialise()
    self.selectButton:instantiate()
    self.selectButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.selectButton)

    self.datas = ISScrollingListBox:new(0, HEADER_HGT, self.width, self.height - bottomHgt - HEADER_HGT)
    self.datas:initialise()
    self.datas:instantiate()
    self.datas.itemheight = FONT_HGT_SMALL + 4 * 2
    self.datas.selected = 0
    self.datas.joypadParent = self
    self.datas.font = UIFont.NewSmall
    self.datas.doDrawItem = self.drawDatas
    self.datas.drawBorder = true
    self.datas:addColumn("Name", 0)
    self.datas:addColumn("Category", 450)
    self:addChild(self.datas)
    
    self:initList()
end

function ISBuyOrderPanel:initList()
    self.items = getAllItems()

    --local allItems = {}
    for i=0,self.items:size()-1 do
        local item = self.items:get(i);
        if not (item:getObsolete() or item:isHidden()) then
            self.datas:addItem(item:getDisplayName(), item)
            --table.insert(allItems, item)
        end
    end
end

function ISBuyOrderPanel:prerender()
    local z = 20
    local splitPoint = 100
    local x = 10
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function ISBuyOrderPanel:onClick(button)
    if button.internal == "CLOSE" then
        self:close()
    elseif button.internal == "SELECT" then
        local item = button.parent.datas.items[button.parent.datas.selected].item
        ISEditPlayerShopUI.instance:addShopItem(item:InstanceItem(item:getTypeString()))
        self:close()
    end
end

function ISBuyOrderPanel:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function ISBuyOrderPanel:new(x, y, width, height)
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
    return o
end