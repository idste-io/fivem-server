-- eonexis-daily — client

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Daily Bonus', msg, t or 'info', 6000)
    end
end

-- Auto-claim on spawn after 5s so server has time to load economy
CreateThread(function()
    Wait(5000)
    TriggerServerEvent('eonexis-daily:claim')
end)

RegisterNetEvent('eonexis-daily:result')
AddEventHandler('eonexis-daily:result', function(success, label, amount, streak)
    if success then
        notify(string.format('%s\n+$%d  (Streak: Day %d)', label, amount, streak), 'success')
    else
        notify(label, 'info')
    end
end)

-- Manual /daily command
RegisterCommand('daily', function()
    TriggerServerEvent('eonexis-daily:claim')
end, false)

TriggerEvent('chat:addSuggestion', '/daily', 'Claim your daily check-in bonus')
