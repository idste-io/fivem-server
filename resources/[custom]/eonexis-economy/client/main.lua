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

-- HUD: always-on money panel — bottom-left corner
CreateThread(function()
    while true do
        Wait(0)
        if not Config.ShowHUD then goto continue end

        -- Background pill
        DrawRect(0.065, 0.945, 0.125, 0.055, 10, 10, 20, 190)

        -- Cash line
        SetTextFont(4)
        SetTextScale(0.32, 0.32)
        SetTextColour(80, 255, 120, 255)
        SetTextEntry('STRING')
        AddTextComponentString(string.format('💵  $%s', tostring(math.floor(cash)):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')))
        DrawText(0.01, 0.925)

        -- Bank line
        SetTextFont(4)
        SetTextScale(0.28, 0.28)
        SetTextColour(100, 180, 255, 220)
        SetTextEntry('STRING')
        AddTextComponentString(string.format('🏦  $%s', tostring(math.floor(bank)):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')))
        DrawText(0.01, 0.953)

        ::continue::
    end
end)

-- Export for other client-side mods to read local cash
exports('getCash', function() return cash end)
exports('getJob',  function() return job  end)
