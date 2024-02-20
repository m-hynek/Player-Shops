local generateOnTest = function(func)
    ---@param item InventoryItem
    return function(item, ...)
        if not __PlayerShopsOnTest.HasAccessToShop(item) then return false end
        return func(item, ...)
    end
end

local recipes = ScriptManager.instance:getAllRecipes()
for i = 0, recipes:size()-1 do
    ---@type Recipe
    local recipe = recipes:get(i)
    local onTest = recipe:getLuaTest()
    if onTest and onTest ~= "" then
        local funcLocation = luautils.split(onTest, "%.")
        local func = _G
        for j = 1, #funcLocation do
            func = func[funcLocation[j]]
        end
        local newName = string.gsub(onTest, "%.", "%$")
        __PlayerShopsOnTest[newName] = generateOnTest(func)
        recipe:setLuaTest("__PlayerShopsOnTest." .. newName)
    else
        recipe:setLuaTest("__PlayerShopsOnTest.HasAccessToShop")
    end
end