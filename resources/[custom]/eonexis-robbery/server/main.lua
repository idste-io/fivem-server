-- eonexis-robbery — server

local cooldowns = {}  -- { [storeId] = os.time() when expires }

local function getStore(id)
    for _, s in ipairs(Config.Stores) do
        if s.id == id then return s end
    end
end

RegisterNetEvent('eonexis-robbery:attempt')
AddEventHandler('eonexis-robbery:attempt', function(storeId)
    local src = source
    local store = getStore(storeId)
    if not store then
        TriggerClientEvent('eonexis-robbery:cancelled', src, 'Invalid store.')
        return
    end

    -- Check cooldown
    local now = os.time()
    if cooldowns[storeId] and now < cooldowns[storeId] then
        local remaining = cooldowns[storeId] - now
        TriggerClientEvent('eonexis-robbery:cancelled', src,
            string.format('Police are still patrolling that area. Wait %ds.', remaining))
        return
    end

    -- Roll success
    local success = math.random() < Config.SuccessRate
    cooldowns[storeId] = now + Config.StoreCooldown

    if success then
        local cash = math.random(Config.MinCash, Config.MaxCash)
        exports['eonexis-economy']:addMoney(src, cash, 'robbery: ' .. store.name)
        TriggerClientEvent('eonexis-robbery:result', src, true, storeId, cash, Config.StoreCooldown)
        -- Police alert to all players
        TriggerClientEvent('eonexis-robbery:alert', -1, store.area, GetPlayerName(src))
        -- Quest hook
        TriggerEvent('eonexis-quests:objectiveDone', src, 'robbery_success')
        print(string.format('[robbery] %s robbed %s for $%d', GetPlayerName(src), store.name, cash))
    else
        TriggerClientEvent('eonexis-robbery:result', src, false, storeId, 0, math.floor(Config.StoreCooldown * 0.3))
    end
end)

-- Broadcast police alert to all clients
RegisterNetEvent('eonexis-robbery:alertReceived')
AddEventHandler('eonexis-robbery:alertReceived', function(area, perp)
    -- handled client-side via TriggerClientEvent
end)
