-- eonexis-notify — client
-- Usage from any other mod:
--   exports['eonexis-notify']:Notify('Title', 'Message', 'info', 5000)
-- Types: 'info' | 'success' | 'error' | 'warning'

local nuiOpen = false

exports('Notify', function(title, message, notifType, duration)
    SendNUIMessage({
        type     = 'notify',
        title    = tostring(title or ''),
        message  = tostring(message or ''),
        notifType = notifType or 'info',
        duration = duration or 4000,
    })
end)

-- Allow other resources to trigger via event (useful from server-side)
RegisterNetEvent('eonexis-notify:client:Notify')
AddEventHandler('eonexis-notify:client:Notify', function(title, message, notifType, duration)
    exports['eonexis-notify']:Notify(title, message, notifType, duration)
end)
