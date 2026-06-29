local wantedPoints  = {}  -- [src] = number (0-50)
local licenseCache  = {}  -- [src] = license string

local function getLicense(src)
    if licenseCache[src] then return licenseCache[src] end
    local lic = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
    licenseCache[src] = lic
    return lic
end

local function saveWantedFile()
    local out = {}
    for src, pts in pairs(wantedPoints) do
        local lic = getLicense(src)
        if lic then out[lic] = math.floor(pts / 10 * 10) / 10 / 10 end  -- stars
    end
    SaveResourceFile(GetCurrentResourceName(), 'data/wanted.json', json.encode(out), -1)
end

-- Exports
exports('getWantedPoints', function(src) return wantedPoints[src] or 0 end)
exports('getWantedStars', function(src)
    local pts = wantedPoints[src] or 0
    return math.floor(pts / 5) / 2  -- half-star resolution: 50pts/5=10, /2=5.0 max
end)

local function wantedStars(src)
    local pts = wantedPoints[src] or 0
    return math.floor(pts / 5) / 2
end

local function rollLoot()
    local roll = math.random(100)
    local rarity
    if roll <= Config.RarityWeights.common then
        rarity = 'common'
    elseif roll <= Config.RarityWeights.common + Config.RarityWeights.uncommon then
        rarity = 'uncommon'
    elseif roll <= Config.RarityWeights.common + Config.RarityWeights.uncommon + Config.RarityWeights.rare then
        rarity = 'rare'
    else
        rarity = 'epic'
    end
    local pool = Config.LootTable[rarity]
    local drop = pool[math.random(#pool)]
    return rarity, drop
end

-- Crime reporting from other mods / client
RegisterNetEvent('eonexis-wanted:addCrime')
AddEventHandler('eonexis-wanted:addCrime', function(crimeType)
    local src = source
    local pts = Config.CrimePoints[crimeType] or 5
    wantedPoints[src] = math.min(50, (wantedPoints[src] or 0) + pts)
    TriggerClientEvent('eonexis-wanted:updateStars', src, wantedPoints[src])
    saveWantedFile()
    -- notify police players
    local stars = wantedStars(src)
    local name  = GetPlayerName(src)
    for _, pid in ipairs(GetPlayers()) do
        if exports['eonexis-police']:isPoliceOnDuty(tonumber(pid)) then
            TriggerClientEvent('eonexis-notify:show', tonumber(pid),
                '🚨 Crime Alert',
                string.format('%s has %.1f stars (%s)', name, stars, crimeType),
                'warning', 5000)
        end
    end
end)

-- Server-authoritative addWanted (star amount, from other mods)
RegisterNetEvent('eonexis-wanted:addStars')
AddEventHandler('eonexis-wanted:addStars', function(stars)
    local src = source
    local pts = math.floor(stars * 10)
    wantedPoints[src] = math.min(50, (wantedPoints[src] or 0) + pts)
    TriggerClientEvent('eonexis-wanted:updateStars', src, wantedPoints[src])
end)

-- Clear wanted (police uncuff/jail or admin)
RegisterNetEvent('eonexis-wanted:clear')
AddEventHandler('eonexis-wanted:clear', function(target)
    local src = source
    -- allow self-clear (from police after jailing) or admin
    local tgt = (target and tonumber(target) ~= 0) and tonumber(target) or src
    wantedPoints[tgt] = 0
    TriggerClientEvent('eonexis-wanted:updateStars', tgt, 0)
end)

-- Cop/military NPC killed — give loot to killer
RegisterNetEvent('eonexis-wanted:copKilled')
AddEventHandler('eonexis-wanted:copKilled', function()
    local src = source
    local rarity, drop = rollLoot()
    if drop.cash > 0 then
        exports['eonexis-economy']:addCash(src, drop.cash)
        TriggerClientEvent('eonexis-notify:show', src, '💰 Loot Drop',
            string.format('[%s] +$%d cash', string.upper(rarity), drop.cash), 'success', 4000)
    else
        exports['eonexis-economy']:addItem(src, drop.item, drop.amount[math.random(2)] or drop.amount[1])
        TriggerClientEvent('eonexis-notify:show', src, '🎁 Loot Drop',
            string.format('[%s] Got: %s', string.upper(rarity), drop.item), 'success', 4000)
    end
end)

-- Decay thread — runs every second
CreateThread(function()
    while true do
        Wait(1000)
        for _, src in ipairs(GetPlayers()) do
            local s = tonumber(src)
            if wantedPoints[s] and wantedPoints[s] > 0 then
                -- decay handled client-side; server trusts client decay report
            end
        end
    end
end)

-- Client reports decay tick
RegisterNetEvent('eonexis-wanted:decay')
AddEventHandler('eonexis-wanted:decay', function(newPts)
    local src = source
    -- only allow decay, not increase via this event
    if (wantedPoints[src] or 0) > newPts then
        wantedPoints[src] = math.max(0, newPts)
        if wantedPoints[src] == 0 then
            TriggerClientEvent('eonexis-wanted:updateStars', src, 0)
        end
    end
end)

AddEventHandler('playerDropped', function()
    wantedPoints[source] = nil
end)
