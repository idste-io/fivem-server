-- eonexis-welcomegift — client
-- Handles the welcome event: shows a notification and optional spawn

RegisterNetEvent('eonexis-welcomegift:welcome')
AddEventHandler('eonexis-welcomegift:welcome', function(message)
    -- Show welcome notification using eonexis-notify if available
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Welcome!', message, 'success', 8000)
    else
        -- Fallback to chat message
        TriggerEvent('chat:addMessage', {
            color = { 114, 217, 114 },
            multiline = true,
            args = { Config.ServerName, message },
        })
    end
end)
