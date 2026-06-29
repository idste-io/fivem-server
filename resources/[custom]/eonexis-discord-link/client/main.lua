-- eonexis-discord-link — client

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Discord Link', msg, t or 'info', 8000)
    end
end

RegisterNetEvent('eonexis-discord-link:showCode')
AddEventHandler('eonexis-discord-link:showCode', function(code, expiry)
    notify(string.format(
        'Your link code: **%s**\nGo to Discord → #verify and type:\n`/verify %s`\n(expires in %ds)',
        code, code, expiry
    ), 'info')
    -- Also print to chat for easy copying
    TriggerEvent('chat:addMessage', {
        color = { 147, 82, 219 },
        multiline = true,
        args = { 'Discord', string.format('Link code: %s — use /verify %s in Discord', code, code) }
    })
end)

RegisterNetEvent('eonexis-discord-link:verified')
AddEventHandler('eonexis-discord-link:verified', function(discordId)
    notify('Your Discord has been linked! Welcome to Eonexis.', 'success')
end)

RegisterNetEvent('eonexis-discord-link:msg')
AddEventHandler('eonexis-discord-link:msg', function(msg, t)
    notify(msg, t)
end)

-- Notify when loading screen is done
AddEventHandler('onClientGameTypeStart', function()
    -- nothing for now
end)
