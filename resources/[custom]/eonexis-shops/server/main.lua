-- eonexis-shops — server

RegisterNetEvent('eonexis-shops:requestCash')
AddEventHandler('eonexis-shops:requestCash', function()
    local src  = source
    local cash = exports['eonexis-economy']:getMoney(src)
    TriggerClientEvent('eonexis-shops:updateCash', src, cash)
end)

RegisterNetEvent('eonexis-shops:buy')
AddEventHandler('eonexis-shops:buy', function(itemId)
    local src = source

    local itemDef = nil
    for _, v in ipairs(Config.Items) do
        if v.id == itemId then itemDef = v; break end
    end
    if not itemDef then
        TriggerClientEvent('eonexis-shops:buyResult', src, false, 'Unknown item.', 0)
        return
    end

    local cash = exports['eonexis-economy']:getMoney(src)
    if cash < itemDef.price then
        TriggerClientEvent('eonexis-shops:buyResult', src, false,
            ('Not enough cash! Need $%d.'):format(itemDef.price), cash)
        return
    end

    exports['eonexis-economy']:removeMoney(src, itemDef.price, 'shop purchase: ' .. itemId)
    exports['eonexis-economy']:addItem(src, itemId, 1)

    local newCash = exports['eonexis-economy']:getMoney(src)
    TriggerClientEvent('eonexis-shops:buyResult', src, true,
        ('Bought %s for $%d.'):format(itemDef.label, itemDef.price), newCash)

    print(('[shops] %s bought %s for $%d'):format(GetPlayerName(src), itemId, itemDef.price))
end)
