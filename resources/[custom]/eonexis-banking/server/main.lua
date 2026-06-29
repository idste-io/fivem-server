-- eonexis-banking — server

local cooldowns = {}  -- { [bankId] = os.time() when cooldown expires }
local activeHeists = {}  -- { [bankId] = src }

local function getBank(id)
    for _, b in ipairs(Config.Banks) do
        if b.id == id then return b end
    end
end

local function notify(src, msg, t)
    exports['eonexis-notify']:Notify(GetPlayerName(src), msg, t or 'info', 5000)
end

-- Client requests to start a heist
RegisterNetEvent('eonexis-banking:startHeist')
AddEventHandler('eonexis-banking:startHeist', function(bankId)
    local src  = source
    local bank = getBank(bankId)
    if not bank then return end

    -- Cooldown check
    local now = os.time()
    if cooldowns[bankId] and now < cooldowns[bankId] then
        local remaining = cooldowns[bankId] - now
        notify(src, ('Police still patrolling. Wait %ds.'):format(remaining), 'error')
        return
    end

    -- Only one heist per bank at a time
    if activeHeists[bankId] then
        notify(src, 'Someone is already robbing that bank.', 'error')
        return
    end

    activeHeists[bankId] = src
    cooldowns[bankId] = now + Config.Cooldown

    -- Alert all players
    TriggerClientEvent('eonexis-banking:heistAlert', -1, bank.name, GetPlayerName(src))

    -- Tell client to begin the countdown
    TriggerClientEvent('eonexis-banking:begin', src, bankId, Config.HeistDuration)

    -- Raise wanted level via police mod if loaded
    TriggerEvent('eonexis-police:addWanted', src, 3)

    print(('[banking] %s started heist at %s'):format(GetPlayerName(src), bank.name))
end)

-- Client reports heist complete
RegisterNetEvent('eonexis-banking:heistDone')
AddEventHandler('eonexis-banking:heistDone', function(bankId)
    local src  = source
    local bank = getBank(bankId)
    if not bank then return end

    if activeHeists[bankId] ~= src then
        return  -- not their heist
    end

    activeHeists[bankId] = nil

    local cash = math.random(bank.pay.min, bank.pay.max)
    exports['eonexis-economy']:addMoney(src, cash, 'bank heist: ' .. bank.name)
    notify(src, ('💰 Vault cleared! +$%d'):format(cash), 'success')

    TriggerEvent('eonexis-quests:objectiveDone', src, 'bank_heist')
    TriggerEvent('eonexis-skilltree:taskDone', src)
    print(('[banking] %s completed %s for $%d'):format(GetPlayerName(src), bank.name, cash))
end)

-- Client aborted (caught, died, left zone)
RegisterNetEvent('eonexis-banking:heistAbort')
AddEventHandler('eonexis-banking:heistAbort', function(bankId)
    local src = source
    if activeHeists[bankId] == src then
        activeHeists[bankId] = nil
    end
end)

-- Expose cooldowns to clients on request
RegisterNetEvent('eonexis-banking:requestCooldowns')
AddEventHandler('eonexis-banking:requestCooldowns', function()
    TriggerClientEvent('eonexis-banking:setCooldowns', source, cooldowns)
end)

AddEventHandler('playerDropped', function()
    local src = source
    for bankId, robber in pairs(activeHeists) do
        if robber == src then activeHeists[bankId] = nil end
    end
end)

TriggerEvent('chat:addSuggestion', '/rob', 'Rob nearby bank (stand at vault marker)', {})
