-- eonexis-vehicles — server

local function vehicleByModel(model)
    for _, v in ipairs(Config.Vehicles) do
        if v.model == model then return v end
    end
    return nil
end

local function notify(src, msg, t)
    TriggerClientEvent('eonexis-economy:notify', src, msg, t or 'info')
end

RegisterNetEvent('eonexis-vehicles:requestOwned')
AddEventHandler('eonexis-vehicles:requestOwned', function()
    local src  = source
    local vehs = exports['eonexis-economy']:getOwnedVehicles(src)
    TriggerClientEvent('eonexis-vehicles:receiveOwned', src, vehs)
end)

RegisterNetEvent('eonexis-vehicles:buy')
AddEventHandler('eonexis-vehicles:buy', function(model)
    local src = source
    local veh = vehicleByModel(model)
    if not veh then return end

    local owned = exports['eonexis-economy']:getOwnedVehicles(src)
    for _, v in ipairs(owned) do
        if v == model then notify(src, 'You already own this vehicle.', 'error'); return end
    end

    if not exports['eonexis-economy']:hasMoney(src, veh.price) then
        notify(src, string.format('Need $%d to buy this.', veh.price), 'error')
        return
    end

    exports['eonexis-economy']:removeMoney(src, veh.price, 'vehicle purchase: ' .. model)
    exports['eonexis-economy']:addVehicle(src, model)
    TriggerClientEvent('eonexis-vehicles:bought', src, model)
    TriggerClientEvent('eonexis-vehicles:spawnVehicle', src, model, true)
    notify(src, string.format('Purchased %s!', veh.label), 'success')
    print(('[vehicles] %s bought %s for $%d'):format(GetPlayerName(src), model, veh.price))
    TriggerEvent('eonexis-quests:objectiveDone', src, 'vehicle_purchased')
end)

RegisterNetEvent('eonexis-vehicles:retrieve')
AddEventHandler('eonexis-vehicles:retrieve', function(model)
    local src = source
    local owned = exports['eonexis-economy']:getOwnedVehicles(src)
    local found = false
    for _, v in ipairs(owned) do if v == model then found = true; break end end
    if not found then notify(src, "You don't own that vehicle.", 'error'); return end
    TriggerClientEvent('eonexis-vehicles:spawnVehicle', src, model, false)
end)

RegisterNetEvent('eonexis-vehicles:sell')
AddEventHandler('eonexis-vehicles:sell', function(model)
    local src = source
    local veh = vehicleByModel(model)
    if not veh then return end

    local owned = exports['eonexis-economy']:getOwnedVehicles(src)
    local found = false
    for _, v in ipairs(owned) do if v == model then found = true; break end end
    if not found then notify(src, "You don't own that vehicle.", 'error'); return end

    local sellPrice = math.floor(veh.price * Config.SellValue)
    exports['eonexis-economy']:addMoney(src, sellPrice, 'vehicle sale: ' .. model)
    exports['eonexis-economy']:removeVehicle(src, model)
    TriggerClientEvent('eonexis-vehicles:sold', src, model)
    notify(src, string.format('Sold %s for $%d.', veh.label, sellPrice), 'success')
end)
