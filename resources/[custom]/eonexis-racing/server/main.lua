-- eonexis-racing — server

local DATA_FILE = 'data/racing.json'
local db = {}   -- { [routeId] = { records=[{ name, time, date }] } }
local lobbies = {}  -- { [routeId] = { players={src,...}, timer=nil } }

local function loadDB()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if raw and #raw > 2 then
        local ok, parsed = pcall(json.decode, raw)
        if ok and parsed then db = parsed end
    end
end

local function saveDB()
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, json.encode(db), -1)
end

loadDB()

local function getRoute(id)
    for _, r in ipairs(Config.Routes) do
        if r.id == id then return r end
    end
end

local function recordTime(routeId, playerName, time)
    if not db[routeId] then db[routeId] = { records={} } end
    table.insert(db[routeId].records, { name=playerName, time=time, date=os.date('%Y-%m-%d') })
    -- Keep top 10 only
    table.sort(db[routeId].records, function(a,b) return a.time < b.time end)
    while #db[routeId].records > 10 do
        table.remove(db[routeId].records)
    end
    saveDB()
end

local function getTier(route, time)
    if time <= route.par.gold   then return 'gold'   end
    if time <= route.par.silver then return 'silver' end
    return 'bronze'
end

local function getReward(tier, position)
    if position then
        return Config.Rewards.multi[position] or Config.Rewards.multi[3] or 500
    end
    return Config.Rewards.solo[tier] or Config.Rewards.solo.bronze
end

-- ── Lobby ────────────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-racing:joinLobby')
AddEventHandler('eonexis-racing:joinLobby', function(routeId)
    local src = source
    local route = getRoute(routeId)
    if not route then return end

    if not lobbies[routeId] then
        lobbies[routeId] = { players={}, startTime=nil }
    end
    local lobby = lobbies[routeId]

    -- Add player if not already in
    for _, p in ipairs(lobby.players) do
        if p == src then return end
    end
    table.insert(lobby.players, src)

    print(string.format('[racing] %s joined lobby: %s (%d players)', GetPlayerName(src), routeId, #lobby.players))

    -- Start timer if first player or start immediately after LobbyWait
    if not lobby.timerStarted then
        lobby.timerStarted = true
        CreateThread(function()
            Wait(Config.LobbyWait * 1000)
            if lobbies[routeId] and #lobbies[routeId].players > 0 then
                -- Start race
                local players = lobbies[routeId].players
                lobbies[routeId] = nil  -- clear lobby
                for _, p in ipairs(players) do
                    TriggerClientEvent('eonexis-racing:start', p, routeId, 3)
                end
                -- Track lobby finish order
                lobbies['active_' .. routeId] = { players=players, finished={}, startedAt=os.time() }
            end
        end)
    end
end)

-- ── Race finish ───────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-racing:finish')
AddEventHandler('eonexis-racing:finish', function(routeId, time)
    local src = source
    local route = getRoute(routeId)
    if not route then return end

    local tier = getTier(route, time)
    local activeKey = 'active_' .. routeId
    local position = nil
    local reward

    if lobbies[activeKey] then
        -- Multiplayer: determine finish position
        table.insert(lobbies[activeKey].finished, { src=src, time=time })
        position = #lobbies[activeKey].finished
        reward = getReward(nil, position)
    else
        -- Solo run
        reward = getReward(tier, nil)
    end

    exports['eonexis-economy']:addMoney(src, reward, 'race finish: ' .. routeId)
    TriggerClientEvent('eonexis-racing:finished', src, time, tier, reward, position)
    recordTime(routeId, GetPlayerName(src), time)
    TriggerEvent('eonexis-quests:objectiveDone', src, 'race_finished')
    if position == 1 then
        TriggerEvent('eonexis-quests:objectiveDone', src, 'race_joined')
    end

    print(string.format('[racing] %s finished %s in %.2fs (tier:%s pos:%s +$%d)',
        GetPlayerName(src), routeId, time, tier, tostring(position), reward))
end)

-- ── Leaderboard ───────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-racing:requestLeaderboard')
AddEventHandler('eonexis-racing:requestLeaderboard', function()
    local src = source
    local payload = {}
    for _, route in ipairs(Config.Routes) do
        local records = db[route.id] and db[route.id].records or {}
        table.insert(payload, { id=route.id, name=route.name, records=records })
    end
    TriggerClientEvent('eonexis-racing:leaderboardUpdate', src, payload)
end)

AddEventHandler('playerDropped', function() saveDB() end)
