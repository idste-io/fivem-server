-- eonexis-rules — client
-- /rules — open rules NUI
-- ESC or click X to close

local rulesOpen = false

RegisterCommand('rules', function()
    rulesOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open' })
    TriggerServerEvent('eonexis-skilltree:complete', 'check_rules')
    TriggerEvent('eonexis-rules:opened')
    TriggerServerEvent('eonexis-quests:serverKey', 'rules_opened')
end, false)

RegisterKeyMapping('rules', 'Open Server Rules', 'keyboard', 'F2')

RegisterNUICallback('close', function(_, cb)
    rulesOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    cb({})
end)

AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)
