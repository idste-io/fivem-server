-- eonexis-discord-notify — server
-- Sends Discord webhook messages for join/leave events and a 12-hour status digest.

local WEBHOOK = 'https://discord.com/api/webhooks/1521149305615028436/EUAzXACR6xfolaoqj5Z_GJz5yWfiWawpvyCR2uLxoFBP2Y31HeHnalRVIrIWN8jSyuzU'
local COLOUR_JOIN   = 3066993   -- green
local COLOUR_LEAVE  = 15158332  -- red
local COLOUR_STATUS = 5793266   -- purple

local function getPlayerCount()
    return #GetPlayers()
end

local function sendWebhook(payload)
    PerformHttpRequest(WEBHOOK, function(code, body, headers)
        if code ~= 200 and code ~= 204 then
            print(('[discord-notify] webhook error: HTTP %d'):format(code or 0))
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

local function joinEmbed(name, id)
    return {
        embeds = {{
            title       = '✅ Player Joined',
            description = string.format('**%s** connected to Eonexis RP', name),
            color       = COLOUR_JOIN,
            fields      = {
                { name='Server ID', value=tostring(id), inline=true },
                { name='Online',    value=tostring(getPlayerCount()), inline=true },
            },
            footer  = { text='Eonexis RP' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        }}
    }
end

local function leaveEmbed(name, id, reason)
    return {
        embeds = {{
            title       = '❌ Player Left',
            description = string.format('**%s** disconnected from Eonexis RP', name),
            color       = COLOUR_LEAVE,
            fields      = {
                { name='Server ID', value=tostring(id),     inline=true },
                { name='Online',    value=tostring(getPlayerCount()), inline=true },
                { name='Reason',    value=reason or 'Disconnected', inline=false },
            },
            footer  = { text='Eonexis RP' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        }}
    }
end

local function statusEmbed()
    local players = GetPlayers()
    local names   = {}
    for _, src in ipairs(players) do
        table.insert(names, GetPlayerName(src))
    end
    local nameList = #names > 0 and table.concat(names, ', ') or '_No players online_'

    return {
        embeds = {{
            title       = '📊 Eonexis RP — Server Status',
            color       = COLOUR_STATUS,
            fields      = {
                { name='Players Online', value=string.format('%d / 64', #players), inline=true },
                { name='Server',        value='Eonexis — Custom RP',               inline=true },
                { name='IP',            value='187.124.93.157:30120',               inline=false },
                { name='Who\'s Online', value=nameList,                             inline=false },
            },
            footer  = { text='12-hour status digest • Eonexis RP' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        }}
    }
end

-- Player join
AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    sendWebhook(joinEmbed(name, src))
    deferrals.done()
end)

-- Player leave
AddEventHandler('playerDropped', function(reason)
    local src  = source
    local name = GetPlayerName(src) or 'Unknown'
    sendWebhook(leaveEmbed(name, src, reason))
end)

-- 12-hour status digest
CreateThread(function()
    -- Wait 60s on resource start before first post
    Wait(60000)
    sendWebhook(statusEmbed())
    while true do
        Wait(12 * 60 * 60 * 1000)  -- 12 hours
        sendWebhook(statusEmbed())
    end
end)

print('[eonexis-discord-notify] loaded — webhook active')
