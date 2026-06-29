-- eonexis-phone — server

local function notify(src, msg, t)
    TriggerClientEvent('eonexis-phone:notify', src, msg, t or 'info')
end

RegisterNetEvent('eonexis-phone:deposit')
AddEventHandler('eonexis-phone:deposit', function(amount)
    local src = source
    if not amount or amount <= 0 then notify(src, 'Invalid amount.', 'error'); return end
    if not exports['eonexis-economy']:hasMoney(src, amount) then
        notify(src, 'Not enough cash.', 'error'); return
    end
    exports['eonexis-economy']:removeMoney(src, amount, 'phone deposit')
    exports['eonexis-economy']:addBank(src, amount)
    notify(src, string.format('Deposited $%d', amount), 'success')
end)

RegisterNetEvent('eonexis-phone:withdraw')
AddEventHandler('eonexis-phone:withdraw', function(amount)
    local src = source
    if not amount or amount <= 0 then notify(src, 'Invalid amount.', 'error'); return end
    local bank = exports['eonexis-economy']:getBank(src)
    if bank < amount then notify(src, 'Not enough in bank.', 'error'); return end
    exports['eonexis-economy']:removeBank(src, amount)
    exports['eonexis-economy']:addMoney(src, amount, 'phone withdrawal')
    notify(src, string.format('Withdrew $%d', amount), 'success')
end)

RegisterNetEvent('eonexis-phone:getPlayers')
AddEventHandler('eonexis-phone:getPlayers', function()
    local src = source
    local list = {}
    for _, p in ipairs(GetPlayers()) do
        table.insert(list, { id=p, name=GetPlayerName(tonumber(p)) })
    end
    TriggerClientEvent('eonexis-phone:receivePlayerList', src, list)
end)

RegisterNetEvent('eonexis-phone:buildingSpawn')
AddEventHandler('eonexis-phone:buildingSpawn', function(locId)
    local src = source
    local loc = nil
    for _, l in ipairs(Config.SpawnLocations) do
        if l.id == locId then loc = l; break end
    end
    if not loc then return end

    local cost = Config.BuildingSpawnCost
    if cost > 0 then
        if not exports['eonexis-economy']:hasMoney(src, cost) then
            notify(src, string.format('Need $%d for taxi service.', cost), 'error')
            return
        end
        exports['eonexis-economy']:removeMoney(src, cost, 'phone building spawn')
    end
    TriggerClientEvent('eonexis-phone:doSpawn', src, loc)
end)
