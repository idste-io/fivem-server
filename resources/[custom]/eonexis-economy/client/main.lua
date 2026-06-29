-- eonexis-economy — client

local cash = 0
local bank = 0
local job  = 'unemployed'

-- Request data after spawn
AddEventHandler('onClientGameTypeStart', function()
    Wait(2000)
    TriggerServerEvent('eonexis-economy:requestData')
end)

RegisterNetEvent('eonexis-economy:receiveData')
AddEventHandler('eonexis-economy:receiveData', function(data)
    cash = data.cash
    bank = data.bank
    job  = data.job
end)

RegisterNetEvent('eonexis-economy:updateCash')
AddEventHandler('eonexis-economy:updateCash', function(v) cash = v end)

RegisterNetEvent('eonexis-economy:updateBank')
AddEventHandler('eonexis-economy:updateBank', function(v) bank = v end)

RegisterNetEvent('eonexis-economy:updateJob')
AddEventHandler('eonexis-economy:updateJob', function(v) job = v end)

RegisterNetEvent('eonexis-economy:notify')
AddEventHandler('eonexis-economy:notify', function(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Bank', msg, t or 'info', 4000)
    end
end)

RegisterNetEvent('eonexis-economy:showBalance')
AddEventHandler('eonexis-economy:showBalance', function(c, b)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Balance',
            ('Cash: $%s   Bank: $%s'):format(
                tostring(math.floor(c)), tostring(math.floor(b))
            ), 'info', 6000)
    end
end)

-- Save location when server requests
RegisterNetEvent('eonexis-economy:requestLocation')
AddEventHandler('eonexis-economy:requestLocation', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end  -- don't save mid-drive
    local pos = GetEntityCoords(ped)
    local h   = GetEntityHeading(ped)
    TriggerServerEvent('eonexis-economy:saveLocation', pos.x, pos.y, pos.z, h)
end)

-- HUD: cash display bottom-left
CreateThread(function()
    while true do
        Wait(0)
        if not Config.ShowHUD then goto continue end
        -- Cash label
        SetTextFont(4)
        SetTextScale(0.3, 0.3)
        SetTextColour(255, 255, 255, 200)
        SetTextEntry('STRING')
        AddTextComponentString(('$%s  |  Bank: $%s  |  %s'):format(
            tostring(math.floor(cash)),
            tostring(math.floor(bank)),
            job
        ))
        DrawText(0.01, 0.95)
        ::continue::
    end
end)

-- Export for other client-side mods to read local cash
exports('getCash', function() return cash end)
exports('getJob',  function() return job  end)
