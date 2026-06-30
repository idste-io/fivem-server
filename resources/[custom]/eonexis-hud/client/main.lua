-- eonexis-hud — client
-- Updates NUI every 500ms with player state

local hudVisible = true
local speedUnit  = 'MPH' -- 'MPH' or 'KPH'

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'show', visible = true })
end)

-- Toggle HUD with F5
RegisterCommand('hud', function()
    hudVisible = not hudVisible
    SendNUIMessage({ type = 'show', visible = hudVisible })
end, false)

-- Toggle speed unit with /speedunit
RegisterCommand('speedunit', function()
    speedUnit = speedUnit == 'MPH' and 'KPH' or 'MPH'
    exports['eonexis-notify']:Notify('HUD', 'Speed unit: ' .. speedUnit, 'info', 2000)
end, false)

CreateThread(function()
    while true do
        Wait(500)
        if not hudVisible then goto continue end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local inVeh   = vehicle ~= 0

        -- Health (GTA native: 0=dead, 200=full — base 100 is "0 HP" for player)
        local hp     = math.max(0, math.floor(((GetEntityHealth(ped) - 100) / 100) * 100))
        local armour = math.floor(GetPedArmour(ped))

        -- Speed
        local speed = 0
        if inVeh then
            local raw = GetEntitySpeed(vehicle)
            speed = speedUnit == 'MPH' and math.floor(raw * 2.2369) or math.floor(raw * 3.6)
        end

        -- Street name
        local px, py, pz = table.unpack(GetEntityCoords(ped))
        local streetHash = GetStreetNameAtCoord(px, py, pz)
        local street     = GetStreetNameFromHashKey(streetHash)

        -- Server clock (synced)
        local hour, minute = GetClockHours(), GetClockMinutes()
        local time = string.format('%02d:%02d', hour, minute)

        -- Engine on/off
        local engineOn = inVeh and GetIsVehicleEngineRunning(vehicle) or false

        SendNUIMessage({
            type    = 'update',
            hp      = hp,
            armour  = armour,
            speed   = speed,
            unit    = speedUnit,
            street  = street or '',
            time    = time,
            inVeh   = inVeh,
            engine  = engineOn,
        })

        ::continue::
    end
end)

AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)
