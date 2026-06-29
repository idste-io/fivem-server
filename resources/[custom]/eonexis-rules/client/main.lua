-- eonexis-rules — client
-- /rules — open rules NUI
-- ESC or click X to close

local rulesOpen = false

RegisterCommand('rules', function()
    rulesOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'open' })
end, false)

RegisterKeyMapping('rules', 'Open Server Rules', 'keyboard', 'F2')

RegisterNUICallback('close', function(_, cb)
    rulesOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    cb({})
end)
