-- eonexis-crafting — server

local function getRecipe(id)
    for _, r in ipairs(Config.Recipes) do
        if r.id == id then return r end
    end
end

local function notify(src, msg, t)
    exports['eonexis-notify']:Notify(GetPlayerName(src), msg, t or 'info', 5000)
end

-- Client sends crafting request
RegisterNetEvent('eonexis-crafting:craft')
AddEventHandler('eonexis-crafting:craft', function(recipeId)
    local src    = source
    local recipe = getRecipe(recipeId)
    if not recipe then
        notify(src, 'Unknown recipe.', 'error'); return
    end

    -- Check all ingredients
    local inv = exports['eonexis-economy']:getInventory(src)
    for _, ing in ipairs(recipe.ingredients) do
        local have = inv[ing.item] or 0
        if have < ing.qty then
            notify(src, ('Missing %dx %s.'):format(ing.qty - have, ing.item), 'error')
            return
        end
    end

    -- Remove ingredients
    for _, ing in ipairs(recipe.ingredients) do
        exports['eonexis-economy']:removeItem(src, ing.item, ing.qty)
    end

    -- Add result
    exports['eonexis-economy']:addItem(src, recipe.result.item, recipe.result.qty)
    notify(src, ('✅ Crafted %dx %s.'):format(recipe.result.qty, recipe.label), 'success')

    TriggerEvent('eonexis-quests:objectiveDone', src, 'item_crafted')
    TriggerEvent('eonexis-skilltree:taskDone', src)
    print(('[crafting] %s crafted %s'):format(GetPlayerName(src), recipe.label))
end)

-- Send recipe list to client on request
RegisterNetEvent('eonexis-crafting:requestRecipes')
AddEventHandler('eonexis-crafting:requestRecipes', function()
    local src = source
    local inv  = exports['eonexis-economy']:getInventory(src)
    -- Include inventory counts so NUI can grey out unaffordable recipes
    TriggerClientEvent('eonexis-crafting:receiveRecipes', src, Config.Recipes, inv)
end)

print('[eonexis-crafting] loaded — ' .. #Config.Recipes .. ' recipes, ' .. #Config.Workbenches .. ' workbenches')
