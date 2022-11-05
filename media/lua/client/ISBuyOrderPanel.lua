-- written by albion, based on ISItemsListTable and ISItemsListViewer

local ISBuyOrderPanel = ISPanel:derive("ISBuyOrderPanel")

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

    self.filters = ISLabel:new(0, self.datas:getBottom() + 20, FONT_HGT_LARGE, getText("IGUI_DbViewer_Filters"), 1, 1, 1, 1, UIFont.Large, true)
    self.filters:initialise()
    self.filters:instantiate()
    self:addChild(self.filters)
    
    local x = 0;
    local entryY = self.filters:getBottom() + self.datas.itemheight
    for i,column in ipairs(self.datas.columns) do
        local size;
        if i == #self.datas.columns then -- last column take all the remaining width
            size = self.datas:getWidth() - x;
        else
            size = self.datas.columns[i+1].size - self.datas.columns[i].size
        end
        if column.name == "Category" then
            local combo = ISComboBox:new(x, entryY, size, entryHgt)
            combo.font = UIFont.Medium
            combo:initialise()
            combo:instantiate()
            combo.columnName = column.name
            combo.target = combo
            combo.onChange = ISItemsListTable.onFilterChange
            combo.itemsListFilter = ISItemsListTable.filterDisplayCategory
            self:addChild(combo)
            table.insert(self.filterWidgets, combo)
            self.filterWidgetMap[column.name] = combo
        else
            local entry = ISTextEntryBox:new("", x, entryY, size, entryHgt);
            entry.font = UIFont.Medium
            entry:initialise();
            entry:instantiate();
            entry.columnName = column.name;
            entry.itemsListFilter = ISItemsListTable['filter'..column.name]
            entry.onTextChange = ISItemsListTable.onFilterChange;
            entry.onOtherKey = function(entry, key) ISItemsListTable.onOtherKey(entry, key) end
            entry.target = self;
            entry:setClearButton(true)
            self:addChild(entry);
            table.insert(self.filterWidgets, entry);
            self.filterWidgetMap[column.name] = entry
        end
        x = x + size;
    end
    
    self:initList()
end

function ISBuyOrderPanel:initList()
    self.items = getAllItems()

    local displayCategoryNames = {}
    local displayCategoryMap = {}
    for i=0,self.items:size()-1 do
        local item = self.items:get(i);
        if not (item:getObsolete() or item:isHidden() or item:getModuleName() == 'Moveables' or item:getTypeString() == 'Moveable') then
            self.datas:addItem(item:getDisplayName(), item)
            if not displayCategoryMap[item:getDisplayCategory()] then
                displayCategoryMap[item:getDisplayCategory()] = true
                table.insert(displayCategoryNames, item:getDisplayCategory())
            end
        end
    end
    table.sort(self.datas.items, function(a,b) return not string.sort(a.item:getDisplayName(), b.item:getDisplayName()); end);

    local combo = self.filterWidgetMap.Category
    table.sort(displayCategoryNames, function(a,b) return not string.sort(a, b) end)
    combo:addOption("<Any>")
    for _,displayCategoryName in ipairs(displayCategoryNames) do
        combo:addOption(displayCategoryName)
    end
end

function ISBuyOrderPanel:drawDatas(y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return y + self.itemheight
    end
    
    local a = 0.9;

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15);
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5);
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    local iconX = 4
    local iconSize = FONT_HGT_SMALL;
    local xoffset = 10;

    local clipX = self.columns[1].size
    local clipX2 = self.columns[2].size
    local clipY = math.max(0, y + self:getYScroll())
    local clipY2 = math.min(self.height, y + self:getYScroll() + self.itemheight)
    
    self:setStencilRect(clipX, clipY, clipX2 - clipX, clipY2 - clipY)
    self:drawText(item.item:getDisplayName(), iconX + iconSize + 4, y + 4, 1, 1, 1, a, self.font);
    self:clearStencilRect()

    if item.item:getDisplayCategory() ~= nil then
        self:drawText(getText("IGUI_ItemCat_" .. item.item:getDisplayCategory()), self.columns[2].size + xoffset, y + 4, 1, 1, 1, a, self.font);
        else
        self:drawText("None", self.columns[2].size + xoffset, y + 4, 1, 1, 1, a, self.font);
    end

    self:repaintStencilRect(0, clipY, self.width, clipY2 - clipY)

    local icon = item.item:getIcon()
    if item.item:getIconsForTexture() and not item.item:getIconsForTexture():isEmpty() then
        icon = item.item:getIconsForTexture():get(0)
    end
    if icon then
        local texture = getTexture("Item_" .. icon)
        if texture then
            self:drawTextureScaledAspect2(texture, self.columns[1].size + iconX, y + (self.itemheight - iconSize) / 2, iconSize, iconSize,  1, 1, 1, 1);
        end
    end
    
    return y + self.itemheight
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
        self.editUI:addShopItem(item)
        self:close()
    end
end

function ISItemsListTable:filterName(widget, scriptItem)
    local txtToCheck = string.lower(scriptItem:getDisplayName())
    local filterTxt = string.lower(widget:getInternalText())
    return checkStringPattern(filterTxt) and string.match(txtToCheck, filterTxt)
end

function ISBuyOrderPanel:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function ISBuyOrderPanel:new(x, y, width, height, editUI)
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
    o.filterWidgets = {}
    o.filterWidgetMap = {}
    o.editUI = editUI
    return o
end

return ISBuyOrderPanel