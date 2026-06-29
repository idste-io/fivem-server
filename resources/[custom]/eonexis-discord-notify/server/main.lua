-- eonexis-discord-notify — server
-- Posts join/leave events and 12-hour status to the Discord bot via local HTTP.
-- The webhook was replaced by the eonexis-bot; this now calls the bot's event endpoint.

local BOT_URL    = 'http://127.0.0.1:3001/event'
local BOT_SECRET = 'eonexis_bot_secret_2024_xK9mQ'  -- must match BOT_SECRET in eonexis-bot .env

local function getPlayerCount()
    return #GetPlayers()
end

local function postEvent(payload)
    PerformHttpRequest(BOT_URL, function(code)
        if code ~= 200 and code ~= 0 then
            print(('[discord-notify] bot HTTP error: %d'):format(code or 0))
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
        ['x-bot-secret'] = BOT_SECRET,
    })
end

AddEventHandler('playerJoining', function()
    local src  = source
    local name = GetPlayerName(src) or 'Unknown'
    postEvent({
        type        = 'join',
        name        = name,
        playerCount = getPlayerCount(),
        maxPlayers  = 64,
    })
end)

AddEventHandler('playerDropped', function(reason)
    local src  = source
    local name = GetPlayerName(src) or 'Unknown'
    postEvent({
        type        = 'leave',
        name        = name,
        reason      = reason or 'Disconnected',
        playerCount = math.max(0, getPlayerCount() - 1),
        maxPlayers  = 64,
    })
end)

-- 12-hour status is now handled by the bot's cron (tasks.js).
-- We only send first-start ping so the bot can refresh its info dashboard.
CreateThread(function()
    Wait(30000)  -- 30s after resource start
    postEvent({ type = 'servermon', errors = {} })  -- triggers bot to refresh
end)

print('[eonexis-discord-notify] loaded — posting to bot HTTP on port 3001')
