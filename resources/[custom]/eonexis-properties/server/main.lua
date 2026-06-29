-- eonexis-properties — server

local function propById(id)
    for _, p in ipairs(Config.Properties) do
        if p.id == id then return p end
    end
    return nil
end

local function notify(src, msg, t)
    if exports['eonexis-notify'] then
        TriggerClientEvent('eonexis-economy:notify', src, msg, t or 'info')
    end
end

RegisterNetEvent('eonexis-properties:requestOwned')
AddEventHandler('eonexis-properties:requestOwned', function()
    local src  = source
    local data = exports['eonexis-economy']:getPlayerData(src)
    TriggerClientEvent('eonexis-properties:receiveOwned', src, data and data.ownedProperties or {})
end)

RegisterNetEvent('eonexis-properties:buy')
AddEventHandler('eonexis-properties:buy', function(propId)
    local src  = source
    local prop = propById(propId)
    if not prop then return end

    if exports['eonexis-economy']:ownsProperty(src, propId) then
        notify(src, 'You already own this property.', 'error')
        return
    end

    if not exports['eonexis-economy']:hasMoney(src, prop.price) then
        notify(src, string.format('You need $%d to buy this.', prop.price), 'error')
        return
    end

    exports['eonexis-economy']:removeMoney(src, prop.price, 'property purchase: ' .. propId)
    exports['eonexis-economy']:addProperty(src, propId)

    -- Auto-set first house as home
    local data = exports['eonexis-economy']:getPlayerData(src)
    if prop.type == 'house' and (not data.homeProperty) then
        exports['eonexis-economy']:setHome(src, propId)
    end

    TriggerClientEvent('eonexis-properties:bought', src, propId)
    notify(src, string.format('You purchased %s!', prop.label), 'success')
    print(('[properties] %s bought %s for $%d'):format(GetPlayerName(src), propId, prop.price))
    TriggerEvent('eonexis-quests:objectiveDone', src, 'property_purchased')
end)

RegisterNetEvent('eonexis-properties:sell')
AddEventHandler('eonexis-properties:sell', function(propId)
    local src  = source
    local prop = propById(propId)
    if not prop then return end

    if not exports['eonexis-economy']:ownsProperty(src, propId) then
        notify(src, "You don't own this property.", 'error')
        return
    end

    local sellPrice = math.floor(prop.price * 0.6)  -- 60% resale value
    exports['eonexis-economy']:addMoney(src, sellPrice, 'property sale: ' .. propId)
    exports['eonexis-economy']:removeProperty(src, propId)

    TriggerClientEvent('eonexis-properties:sold', src, propId)
    notify(src, string.format('Sold %s for $%d.', prop.label, sellPrice), 'success')
end)

RegisterNetEvent('eonexis-properties:setHome')
AddEventHandler('eonexis-properties:setHome', function(propId)
    local src = source
    if not exports['eonexis-economy']:ownsProperty(src, propId) then return end
    exports['eonexis-economy']:setHome(src, propId)
    notify(src, 'Home spawn set to this property.', 'success')
end)

-- Business passive income tick
CreateThread(function()
    while true do
        Wait(Config.IncomeInterval)
        for _, player in ipairs(GetPlayers()) do
            local src  = tonumber(player)
            local data = exports['eonexis-economy']:getPlayerData(src)
            if data then
                for _, propId in ipairs(data.ownedProperties) do
                    local prop = propById(propId)
                    if prop and prop.type == 'business' and prop.businessIncome then
                        exports['eonexis-economy']:addMoney(src, prop.businessIncome, 'business income: ' .. propId)
                        TriggerClientEvent('eonexis-economy:notify', src,
                            string.format('%s earned $%d', prop.label, prop.businessIncome), 'success')
                    end
                end
            end
        end
    end
end)

-- Export: get home spawn for a player (used by eonexis-spawn)
exports('getHomeSpawn', function(src)
    local data = exports['eonexis-economy']:getPlayerData(src)
    if not data or not data.homeProperty then return nil end
    local prop = propById(data.homeProperty)
    if not prop or not prop.spawn then return nil end
    return prop.spawn, prop.label
end)
