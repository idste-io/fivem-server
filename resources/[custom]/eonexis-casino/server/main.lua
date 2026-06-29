-- eonexis-casino — server

local cooldowns = {}  -- src → last spin timestamp (os.time())

local function getIdentifier(src)
    local lic = GetPlayerIdentifierByType(src, 'license')
    if lic and lic ~= '' then return lic end
    local steam = GetPlayerIdentifierByType(src, 'steam')
    if steam and steam ~= '' then return steam end
    return GetPlayerIdentifier(src, 0) or tostring(src)
end

local function weightedRandom()
    local total = 0
    for _, p in ipairs(Config.Prizes) do total = total + p.weight end
    local roll = math.random(1, total)
    local acc  = 0
    for i, p in ipairs(Config.Prizes) do
        acc = acc + p.weight
        if roll <= acc then return i, p end
    end
    return 1, Config.Prizes[1]
end

RegisterNetEvent('eonexis-casino:spin')
AddEventHandler('eonexis-casino:spin', function()
    local src = source
    local id  = getIdentifier(src)
    local now = os.time()

    -- Cooldown check
    if cooldowns[id] and (now - cooldowns[id]) < Config.SpinCooldown then
        local remaining = Config.SpinCooldown - (now - cooldowns[id])
        local mins = math.floor(remaining / 60)
        TriggerClientEvent('eonexis-casino:error', src,
            string.format('Cooldown: %d min %ds remaining.', mins, remaining % 60))
        return
    end

    -- Cost check
    if not exports['eonexis-economy']:hasMoney(src, Config.SpinCost) then
        TriggerClientEvent('eonexis-casino:error', src,
            string.format('Need $%d to spin.', Config.SpinCost))
        return
    end

    exports['eonexis-economy']:removeMoney(src, Config.SpinCost, 'casino spin')
    cooldowns[id] = now

    local prizeIndex, prize = weightedRandom()

    if prize.type == 'cash' and prize.value > 0 then
        exports['eonexis-economy']:addMoney(src, prize.value, 'casino win')
    elseif prize.type == 'vehicle' then
        -- Give a random owned vehicle or fallback cash
        local owned = exports['eonexis-economy']:getOwnedVehicles(src)
        if owned and #owned > 0 then
            -- Spawn a bonus vehicle (Elegy as prize car)
            TriggerClientEvent('eonexis-casino:spawnPrizeCar', src, 'elegy2')
        else
            -- No cars owned — give cash equivalent
            exports['eonexis-economy']:addMoney(src, 10000, 'casino vehicle prize (cash)')
            prize = { label='$10,000 (vehicle alt)', type='cash', value=10000 }
        end
    end

    TriggerClientEvent('eonexis-casino:spinResult', src, prizeIndex, prize)
    TriggerEvent('eonexis-quests:objectiveDone', src, 'casino_spun')
end)
