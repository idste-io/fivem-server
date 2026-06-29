-- eonexis-character — server

local DATA_FILE = 'data/characters.json'

local function readData()
    local f = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if f and f ~= '' then
        local ok, t = pcall(json.decode, f)
        if ok and t then return t end
    end
    return {}
end

local function writeData(t)
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, json.encode(t, { indent = true }), -1)
end

local function getIdentifier(src)
    local lic = GetPlayerIdentifierByType(src, 'license')
    if lic and lic ~= '' then return lic end
    return GetPlayerIdentifier(src, 0)
end

local function notify(src, msg, t)
    TriggerClientEvent('eonexis-notify:notify', src, 'Character', msg, t or 'info', 6000)
end

-- ── Load character ────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-character:load')
AddEventHandler('eonexis-character:load', function()
    local src = source
    local id  = getIdentifier(src)
    if not id then return end
    local db   = readData()
    local char = db[id]
    TriggerClientEvent('eonexis-character:receive', src, char)
end)

-- ── Save / create character ───────────────────────────────────────────────────

RegisterNetEvent('eonexis-character:save')
AddEventHandler('eonexis-character:save', function(data)
    local src = source
    local id  = getIdentifier(src)
    if not id then return end

    local db   = readData()
    local char = db[id]

    if char then
        -- Existing character — check name change cost
        if data.name ~= char.name then
            local cost = Config.NameChangeCost
            local eco  = exports['eonexis-economy']
            if not eco then
                return TriggerClientEvent('eonexis-character:error', src, 'Economy not available.')
            end
            local pd = eco:getPlayerData(src)
            if (pd and pd.cash or 0) < cost then
                return TriggerClientEvent('eonexis-character:error', src,
                    string.format('Name change costs $%d. You have $%d.', cost, pd and pd.cash or 0))
            end
            eco:removeMoney(src, cost, 'character name change')
        end
    end

    -- Outfit cost for non-first-time
    if char and data.outfit and data.outfit ~= (char.outfit or 'basic_m') then
        local outfitCost = 0
        for _, o in ipairs(Config.Outfits) do
            if o.id == data.outfit then outfitCost = o.price break end
        end
        if outfitCost > 0 then
            local eco = exports['eonexis-economy']
            local pd  = eco and eco:getPlayerData(src)
            if (pd and pd.cash or 0) < outfitCost then
                return TriggerClientEvent('eonexis-character:error', src,
                    string.format('Outfit costs $%d. You have $%d.', outfitCost, pd and pd.cash or 0))
            end
            if eco then eco:removeMoney(src, outfitCost, 'outfit change') end
        end
    end

    local isNew = not char
    db[id] = {
        name     = data.name or GetPlayerName(src),
        gender   = data.gender or 'male',
        outfit   = data.outfit or 'basic_m',
        bio      = data.bio or '',
        createdAt= (char and char.createdAt) or os.time(),
        updatedAt= os.time(),
    }
    writeData(db)

    TriggerClientEvent('eonexis-character:saved', src, db[id], isNew)
    if isNew then
        notify(src, 'Character created! Welcome to Eonexis.', 'success')
        TriggerEvent('eonexis-quests:objectiveDone', src, 'character_created')
        -- Notify bot admin channel: new player first join
        PerformHttpRequest('http://127.0.0.1:3001/event', function() end, 'POST',
            json.encode({
                type    = 'newplayer',
                name    = db[id].name,
                license = id,
                gender  = db[id].gender,
                server_id = src,
            }),
            { ['Content-Type'] = 'application/json', ['X-Bot-Secret'] = 'eonexis_bot_secret_2024_xK9mQ' })
    else
        notify(src, 'Character updated.', 'success')
    end
    print(string.format('[character] %s saved as "%s"', id, db[id].name))
end)

-- ── Get character (export for other mods) ────────────────────────────────────

exports('getCharacter', function(src)
    local id = getIdentifier(src)
    if not id then return nil end
    return readData()[id]
end)

-- ── Monthly reset ─────────────────────────────────────────────────────────────

local function doMonthlyReset()
    print('[character] Running monthly server reset...')

    -- Reset quests
    local questFile = 'data/quests.json'
    local qResource = 'eonexis-quests'
    SaveResourceFile(qResource, questFile, json.encode({}), -1)

    -- Reset skill tree
    local stFile = 'data/skilltree.json'
    local stResource = 'eonexis-skilltree'
    SaveResourceFile(stResource, stFile, json.encode({}), -1)

    -- Reset racing leaderboard
    local rFile = 'data/leaderboard.json'
    local rResource = 'eonexis-racing'
    SaveResourceFile(rResource, rFile, json.encode({}), -1)

    -- Reset economy: keep money + bank, wipe vehicles + job progress + properties (not homes)
    local ecoResource = 'eonexis-economy'
    local ecoPath     = 'data/players.json'
    local raw = LoadResourceFile(ecoResource, ecoPath)
    if raw and raw ~= '' then
        local ok, eco = pcall(json.decode, raw)
        if ok and eco then
            for license, pd in pairs(eco) do
                -- Keep money, bank, and home properties
                local keepProps = {}
                if pd.properties then
                    for propId, prop in pairs(pd.properties) do
                        if prop.type == 'house' then
                            keepProps[propId] = prop
                        end
                    end
                end
                eco[license] = {
                    cash       = pd.cash or 0,
                    bank       = pd.bank or 0,
                    job        = 'unemployed',
                    properties = keepProps,
                    vehicles   = {},
                    inventory  = {},
                    lastSaved  = os.time(),
                }
            end
            SaveResourceFile(ecoResource, ecoPath, json.encode(eco, { indent = true }), -1)
        end
    end

    -- Notify online players
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 147, 82, 219 },
        multiline = true,
        args = { 'Server Reset', 'Monthly reset complete! Vehicles & job progress wiped. Money and homes kept.' }
    })

    print('[character] Monthly reset complete.')
end

-- Check if it's reset day on startup + once per hour
local function checkResetSchedule()
    local t = os.date('*t')
    if t.day == Config.ResetDayOfMonth and t.hour == Config.ResetHour then
        local marker = LoadResourceFile(GetCurrentResourceName(), 'data/last_reset.txt') or ''
        local thisMonth = string.format('%d-%02d', t.year, t.month)
        if marker ~= thisMonth then
            doMonthlyReset()
            SaveResourceFile(GetCurrentResourceName(), 'data/last_reset.txt', thisMonth, -1)
        end
    end
end

CreateThread(function()
    while true do
        Wait(3600000)  -- check every hour
        checkResetSchedule()
    end
end)

-- Admin command to force reset
RegisterCommand('forcereset', function(src, args)
    if src ~= 0 then
        local adminResource = 'eonexis-admintools'
        -- Only allow admins
        return
    end
    doMonthlyReset()
    print('[character] Forced reset by server console.')
end, true)
