-- eonexis-economy — client

local cash = 0
local bank = 0
local job  = 'unemployed'

-- Request data on first load
AddEventHandler('onClientGameTypeStart', function()
    Wait(2000)
    TriggerServerEvent('eonexis-economy:requestData')
end)

-- Re-sync cash/bank/job on every spawn and respawn
AddEventHandler('eonexis-spawn:done', function()
    Wait(500)
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

-- HUD: always-on money panel — top-left (clear of minimap and right-side HUD)
local function fmtMoney(n)
    return tostring(math.floor(n)):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
end

CreateThread(function()
    while true do
        Wait(0)
        if not Config.ShowHUD then goto continue end

        -- Background pill
        DrawRect(0.068, 0.042, 0.13, 0.052, 10, 10, 20, 190)

        -- Cash line
        SetTextFont(4)
        SetTextScale(0.30, 0.30)
        SetTextColour(80, 255, 120, 255)
        SetTextEntry('STRING')
        AddTextComponentString('💵  $' .. fmtMoney(cash))
        DrawText(0.01, 0.018)

        -- Bank line
        SetTextFont(4)
        SetTextScale(0.26, 0.26)
        SetTextColour(100, 180, 255, 220)
        SetTextEntry('STRING')
        AddTextComponentString('🏦  $' .. fmtMoney(bank))
        DrawText(0.01, 0.044)

        ::continue::
    end
end)

-- Export for other client-side mods to read local cash
exports('getCash', function() return cash end)
exports('getJob',  function() return job  end)
