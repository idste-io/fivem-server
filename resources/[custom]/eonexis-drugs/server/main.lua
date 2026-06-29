-- eonexis-drugs — server

local activeLabs = {}  -- { [labId] = { src, endTime } }

local function getLab(id)
    for _, l in ipairs(Config.Labs) do
        if l.id == id then return l end
    end
end

local function notify(src, msg, t)
    exports['eonexis-notify']:Notify(GetPlayerName(src), msg, t or 'info', 5000)
end

-- Start production at a lab
RegisterNetEvent('eonexis-drugs:startProd')
AddEventHandler('eonexis-drugs:startProd', function(labId)
    local src = source
    local lab = getLab(labId)
    if not lab then return end

    if activeLabs[labId] then
        notify(src, 'Someone is already using this lab.', 'error'); return
    end

    activeLabs[labId] = { src=src, endTime=os.time() + lab.time }
    TriggerClientEvent('eonexis-drugs:prodBegin', src, labId, lab.time)

    -- Police alert chance
    local alertChance = lab.alertChance or Config.AlertChance
    if math.random() < alertChance then
        Wait(math.random(10, 30) * 1000)
        TriggerClientEvent('eonexis-drugs:policeAlert', -1, lab.name)
        TriggerEvent('eonexis-police:addWanted', src, 2)
    end

    print(('[drugs] %s started production at %s (%s)'):format(GetPlayerName(src), lab.name, lab.product))
end)

-- Production complete (client confirms)
RegisterNetEvent('eonexis-drugs:prodDone')
AddEventHandler('eonexis-drugs:prodDone', function(labId)
    local src = source
    local lab = getLab(labId)
    if not lab then return end

    if not activeLabs[labId] or activeLabs[labId].src ~= src then return end
    activeLabs[labId] = nil

    local qty = math.random(1, 3)
    exports['eonexis-economy']:addItem(src, lab.product, qty)
    notify(src, ('Produced %dx %s. Sell to a dealer.'):format(qty, lab.product), 'success')
    TriggerEvent('eonexis-quests:objectiveDone', src, 'drug_produced')
    print(('[drugs] %s produced %dx %s'):format(GetPlayerName(src), qty, lab.product))
end)

-- Sell drugs to a dealer
RegisterNetEvent('eonexis-drugs:sell')
AddEventHandler('eonexis-drugs:sell', function(drugId)
    local src = source
    local prices = Config.DrugPrices[drugId]
    if not prices then
        notify(src, 'Unknown drug.', 'error'); return
    end

    local inv = exports['eonexis-economy']:getInventory(src)
    local qty = inv[drugId] or 0
    if qty <= 0 then
        notify(src, ('You have no %s to sell.'):format(drugId), 'error'); return
    end

    local priceEach = math.random(prices.min, prices.max)
    local total = qty * priceEach
    exports['eonexis-economy']:removeItem(src, drugId, qty)
    exports['eonexis-economy']:addMoney(src, total, 'drug sale: ' .. drugId)
    notify(src, ('Sold %dx %s for $%d.'):format(qty, drugId, total), 'success')

    -- Alert chance on sale
    if math.random() < 0.20 then
        TriggerClientEvent('eonexis-drugs:policeAlert', -1, 'a street corner')
        TriggerEvent('eonexis-police:addWanted', src, 2)
    end

    TriggerEvent('eonexis-quests:objectiveDone', src, 'drug_sold')
    TriggerEvent('eonexis-skilltree:taskDone', src)
    print(('[drugs] %s sold %dx %s for $%d'):format(GetPlayerName(src), qty, drugId, total))
end)

-- Abort production (player left area)
RegisterNetEvent('eonexis-drugs:abort')
AddEventHandler('eonexis-drugs:abort', function(labId)
    local src = source
    if activeLabs[labId] and activeLabs[labId].src == src then
        activeLabs[labId] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for labId, data in pairs(activeLabs) do
        if data.src == src then activeLabs[labId] = nil end
    end
end)

-- Send inventory to client so sell menu can show available drugs
RegisterNetEvent('eonexis-drugs:requestInventory')
AddEventHandler('eonexis-drugs:requestInventory', function()
    local src = source
    local inv = exports['eonexis-economy']:getInventory(src)
    TriggerClientEvent('eonexis-drugs:receiveInventory', src, inv)
end)

print('[eonexis-drugs] loaded — ' .. #Config.Labs .. ' labs, ' .. #Config.Dealers .. ' dealers')
