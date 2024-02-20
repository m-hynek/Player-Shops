---@param func function
local generateOnTest = function(func)
    ---@param item InventoryItem
    return function(item, ...)
        if not __PlayerShopsOnTest.HasAccessToShop(item) then return false end
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

local recipes = ScriptManager.instance:getAllRecipes()
for i = 0, recipes:size()-1 do
    ---@type Recipe
    local recipe = recipes:get(i)
    local onTest = recipe:getLuaTest()
    if onTest and onTest ~= "" then
        local func = getFunctionByName(onTest)
        if func then
            local newName = string.gsub(onTest, "%.", "%$")
            __PlayerShopsOnTest[newName] = generateOnTest(func)
            recipe:setLuaTest("__PlayerShopsOnTest." .. newName)
        else
            recipe:setLuaTest("__PlayerShopsOnTest.HasAccessToShop")
        end
    else
        recipe:setLuaTest("__PlayerShopsOnTest.HasAccessToShop")
    end
end