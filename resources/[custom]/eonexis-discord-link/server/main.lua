-- eonexis-discord-link — server
-- HTTP API for Discord bot + /link command + join/leave events

local pendingCodes = {}   -- code → { license, name, expiry }
local linkedPlayers = {}  -- license → discordId (in-memory, loaded from bot)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function getIdentifier(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if license and license ~= '' then return license end
    local steam = GetPlayerIdentifierByType(src, 'steam')
    if steam and steam ~= '' then return steam end
    return GetPlayerIdentifier(src, 0)
end

local function generateCode()
    local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    local code  = ''
    for _ = 1, 6 do
        code = code .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return code
end

local function parseQuery(path)
    local params = {}
    for k, v in path:gmatch('[?&]([^=&]+)=([^&]*)') do
        params[k] = v
    end
    return params
end

local function checkSecret(req)
    return req.headers and req.headers['x-bot-secret'] == Config.BotSecret
end

local function sendJson(res, code, data)
    res.writeHead(code, { ['Content-Type'] = 'application/json' })
    res.send(json.encode(data))
end

-- ── Bot notification ──────────────────────────────────────────────────────────

local function notifyBot(eventData)
    -- POST event to Discord bot HTTP server
    PerformHttpRequest(
        ('http://127.0.0.1:%d/event'):format(Config.BotHttpPort),
        function(status, body, headers) end,
        'POST',
        json.encode(eventData),
        { ['Content-Type'] = 'application/json', ['x-bot-secret'] = Config.BotSecret }
    )
end

-- ── HTTP API ─────────────────────────────────────────────────────────────────

SetHttpHandler(function(req, res)
    if not checkSecret(req) then
        return sendJson(res, 401, { error = 'Unauthorized' })
    end

    local path   = req.path or '/'
    local params = parseQuery(path)
    local route  = path:match('^(/[^?]*)')

    -- GET /verify?code=XXX
    if req.method == 'GET' and route == '/verify' then
        local code    = params.code
        local pending = code and pendingCodes[code]
        if not pending or os.time() > pending.expiry then
            return sendJson(res, 404, { error = 'Invalid or expired code' })
        end
        return sendJson(res, 200, { license = pending.license, name = pending.name })

    -- POST /linked  body: {code, discordId}
    elseif req.method == 'POST' and route == '/linked' then
        req.setDataHandler(function(body)
            local data = json.decode(body)
            if not data or not data.code or not data.discordId then
                return sendJson(res, 400, { error = 'Missing fields' })
            end
            local pending = pendingCodes[data.code]
            if pending then
                linkedPlayers[pending.license] = data.discordId
                pendingCodes[data.code] = nil
                -- Notify in-game player
                for _, src in ipairs(GetPlayers()) do
                    local lic = getIdentifier(tonumber(src))
                    if lic == pending.license then
                        TriggerClientEvent('eonexis-discord-link:verified', tonumber(src), data.discordId)
                        break
                    end
                end
                print(('[discord-link] Linked %s → Discord %s'):format(pending.license, data.discordId))
            end
            sendJson(res, 200, { ok = true })
        end)

    -- GET /balance?license=XXX
    elseif req.method == 'GET' and route == '/balance' then
        local license = params.license
        if not license then return sendJson(res, 400, { error = 'Missing license' }) end
        license = license:gsub('%%3A', ':')  -- decode URL-encoded colon
        -- Find online player
        for _, src in ipairs(GetPlayers()) do
            local lic = getIdentifier(tonumber(src))
            if lic == license then
                local ok, data = pcall(function() return exports['eonexis-economy']:getPlayerData(tonumber(src)) end)
                if ok and data then
                    return sendJson(res, 200, { cash = data.cash, bank = data.bank, job = data.job, online = true })
                end
            end
        end
        return sendJson(res, 200, { offline = true })

    -- POST /givemoney  body: {license, amount, reason}
    elseif req.method == 'POST' and route == '/givemoney' then
        req.setDataHandler(function(body)
            local data = json.decode(body)
            if not data or not data.license or not data.amount then
                return sendJson(res, 400, { error = 'Missing fields' })
            end
            local license = data.license
            for _, src in ipairs(GetPlayers()) do
                local lic = getIdentifier(tonumber(src))
                if lic == license then
                    pcall(function()
                        exports['eonexis-economy']:addMoney(tonumber(src), data.amount, data.reason or 'discord gift')
                    end)
                    TriggerClientEvent('eonexis-notify:notify', tonumber(src),
                        'Discord', ('You received $%d from Discord!'):format(data.amount), 'success', 6000)
                    return sendJson(res, 200, { ok = true })
                end
            end
            sendJson(res, 200, { ok = false, msg = 'Player not online' })
        end)

    -- POST /kick  body: {license, reason}
    elseif req.method == 'POST' and route == '/kick' then
        req.setDataHandler(function(body)
            local data = json.decode(body)
            if not data or not data.license then return sendJson(res, 400, { error = 'Missing license' }) end
            for _, src in ipairs(GetPlayers()) do
                local lic = getIdentifier(tonumber(src))
                if lic == data.license then
                    DropPlayer(tonumber(src), '[Discord Admin] ' .. (data.reason or 'Kicked by admin'))
                    return sendJson(res, 200, { ok = true })
                end
            end
            sendJson(res, 200, { ok = false, msg = 'Player not online' })
        end)

    -- GET /players
    elseif req.method == 'GET' and route == '/players' then
        local list = {}
        for _, src in ipairs(GetPlayers()) do
            table.insert(list, { id = tonumber(src), name = GetPlayerName(tonumber(src)) })
        end
        sendJson(res, 200, { players = list, count = #list })

    else
        sendJson(res, 404, { error = 'Not found' })
    end
end)

-- ── /link command ─────────────────────────────────────────────────────────────

RegisterCommand('link', function(src)
    if src == 0 then return end  -- ignore server console
    local license = getIdentifier(src)
    if not license then
        TriggerClientEvent('eonexis-discord-link:msg', src, 'Could not read your identifier.', 'error')
        return
    end
    -- Clean expired codes
    local now = os.time()
    for code, pending in pairs(pendingCodes) do
        if now > pending.expiry then pendingCodes[code] = nil end
    end
    -- Generate new code
    local code = generateCode()
    pendingCodes[code] = { license = license, name = GetPlayerName(src), expiry = now + Config.CodeExpiry }
    TriggerClientEvent('eonexis-discord-link:showCode', src, code, Config.CodeExpiry)
    print(('[discord-link] %s generated link code %s'):format(GetPlayerName(src), code))
end, false)

TriggerEvent('chat:addSuggestion', '/link', 'Get a code to link your Discord account')

-- ── Join / leave events ───────────────────────────────────────────────────────

AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.done()
    -- Notify bot after connection deferred (actual notification on playerSpawned instead)
end)

-- Use playerJoining or a slight delay after connect
local playerCount = 0
AddEventHandler('playerConnecting', function(name)
    CreateThread(function()
        Wait(3000)
        local src = source
        if not GetPlayerName(src) then return end
        local count = #GetPlayers()
        notifyBot({ type='join', name=name, playerCount=count, maxPlayers=64 })
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local src  = source
    local name = GetPlayerName(src) or 'Unknown'
    local count = math.max(0, #GetPlayers() - 1)
    notifyBot({ type='leave', name=name, playerCount=count, maxPlayers=64 })
end)

-- Export: check if player is linked
exports('getDiscordId', function(src)
    local lic = getIdentifier(src)
    return lic and linkedPlayers[lic] or nil
end)
