-- eonexis-anticheat — server

local function log(msg)
    if Config.LogToConsole then
        print('[eonexis-anticheat] ' .. msg)
    end
end

local function notifyDiscord(name, license, reason)
    if not Config.NotifyDiscord then return end
    local body = json.encode({
        type    = 'anticheat',
        player  = name,
        license = license,
        reason  = reason,
        time    = os.date('%H:%M UTC'),
    })
    PerformHttpRequest(
        ('http://127.0.0.1:%d/event'):format(Config.BotHttpPort),
        function() end,
        'POST',
        body,
        { ['Content-Type'] = 'application/json', ['x-bot-secret'] = Config.BotSecret }
    )
end

local function flag(src, reason)
    local name    = GetPlayerName(src) or '?'
    local license = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0) or '?'
    log(string.format('FLAG [%s/%s] — %s', src, name, reason))
    notifyDiscord(name, license, reason)
    if Config.AutoKick then
        DropPlayer(src, '[Eonexis AC] ' .. reason)
    end
end

RegisterNetEvent('eonexis-anticheat:report')
AddEventHandler('eonexis-anticheat:report', function(data)
    local src    = source
    local maxSpd = data.inVehicle and Config.MaxCarSpeed or Config.MaxPedSpeed

    if data.speed and data.speed > maxSpd then
        flag(src, string.format('speed %.1f m/s (max %.1f)', data.speed, maxSpd))
    end

    if data.dist and data.dist > Config.TeleportThresh then
        flag(src, string.format('teleport %.1f m in %d ms', data.dist, Config.CheckInterval))
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src  = source
    local name = GetPlayerName(src) or '?'
    log(string.format('Player %s (%s) dropped: %s', src, name, reason))
end)
