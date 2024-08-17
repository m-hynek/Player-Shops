local PlayerShops = require "PlayerShops"

---@param func function
local generateOnTest = function(func)
    ---@param item InventoryItem
    return function(item, ...)
        if not _PlayerShopsOnTest.HasAccessToShop(item) then return false end
        return func(item, ...)
    end
end

---@param funcName string
---@return function?
local function getFunctionByName(funcName)
    local funcLocation = luautils.split(funcName, "%.")
    local func = _G
    for j = 1, #funcLocation do
        func = func[funcLocation[j]]
        if not func then return end
    end
    if not type(func) == "function" then return end
    return func
end

_PlayerShopsOnTest = {}

---@param item InventoryItem
_PlayerShopsOnTest.HasAccessToShop = function(item)
    local parent = item:getContainer():getParent()
    if parent and not PlayerShops.hasAccessToShop(parent, getPlayer()) then
        return false
    end
    return true
end

local recipes = ScriptManager.instance:getAllRecipes()
for i = 0, recipes:size()-1 do
    ---@type Recipe
    local recipe = recipes:get(i)
    local onTest = recipe:getLuaTest()
    if onTest and onTest ~= "" then
        local func = getFunctionByName(onTest)
        if func then
            local newName = string.gsub(onTest, "%.", "%$")
            _PlayerShopsOnTest[newName] = generateOnTest(func)
            recipe:setLuaTest("_PlayerShopsOnTest." .. newName)
        else
            recipe:setLuaTest("_PlayerShopsOnTest.HasAccessToShop")
        end
    else
        recipe:setLuaTest("_PlayerShopsOnTest.HasAccessToShop")
    end
end