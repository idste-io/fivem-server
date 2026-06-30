-- eonexis-discord — client
-- Shows a Discord invite toast after the player spawns, once per session

local shown = false

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if Config.ShowOncePerSession and shown then return end

    CreateThread(function()
        Wait(Config.ShowAfterSeconds * 1000)
        if Config.ShowOncePerSession and shown then return end
        shown = true
        SendNUIMessage({
            type    = 'show',
            invite  = Config.DiscordInvite,
            server  = Config.ServerName,
        })
        -- Auto-hide after 12 seconds
        Wait(12000)
        SendNUIMessage({ type = 'hide' })
    end)
end)

RegisterNUICallback('openDiscord', function(_, cb)
    -- Player clicked "Join Discord" — open external link
    -- (FiveM doesn't natively open URLs; we just send a chat message with the link)
    TriggerEvent('chat:addMessage', {
        color = { 114, 137, 218 },
        multiline = true,
        args = { 'Discord', 'Join us at: ' .. Config.DiscordInvite },
    })
    cb({})
end)

RegisterNUICallback('dismiss', function(_, cb)
    SendNUIMessage({ type = 'hide' })
    cb({})
end)

AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)
