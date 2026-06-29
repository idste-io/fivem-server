-- eonexis-vehicles — client (multi-dealership)

local menuOpen    = false
local menuMode    = nil
local ownedVehs   = {}
local activeDlr   = nil

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Vehicles', msg, t or 'info', 4000)
    end
end

RegisterNetEvent('eonexis-vehicles:receiveOwned')
AddEventHandler('eonexis-vehicles:receiveOwned', function(vehs)
    ownedVehs = vehs or {}
end)

AddEventHandler('onClientGameTypeStart', function()
    Wait(3500)
    TriggerServerEvent('eonexis-vehicles:requestOwned')
end)

local function openDealer(dlr)
    if menuOpen then return end
    menuOpen = true; menuMode = 'dealer'; activeDlr = dlr
    -- Filter vehicles by this dealership
    local list = {}
    for _, v in ipairs(Config.Vehicles) do
        if v.dealer == dlr.id then table.insert(list, v) end
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action='showDealer', vehicles=list, dealerName=dlr.label })
end

local function openGarage()
    if menuOpen then return end
    menuOpen = true; menuMode = 'garage'
    local list = {}
    for _, model in ipairs(ownedVehs) do
        for _, v in ipairs(Config.Vehicles) do
            if v.model == model then table.insert(list, v); break end
        end
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ action='showGarage', vehicles=list, dealerName='My Garage' })
end

RegisterNUICallback('buy', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-vehicles:buy', data.model)
end)

RegisterNUICallback('retrieve', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-vehicles:retrieve', data.model)
end)

RegisterNUICallback('sell', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-vehicles:sell', data.model)
end)

RegisterNUICallback('close', function(_, cb)
    cb({})
    menuOpen = false; menuMode = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hide' })
end)

RegisterNetEvent('eonexis-vehicles:spawnVehicle')
AddEventHandler('eonexis-vehicles:spawnVehicle', function(model, isNew)
    menuOpen = false; menuMode = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hide' })

    local hash = GetHashKey(model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 10000 do Wait(100); t = t + 100 end
    if not HasModelLoaded(hash) then notify('Vehicle model failed to load.', 'error'); return end

    local sp = (isNew and activeDlr and activeDlr.spawnPos) or Config.GarageSpawn
    local veh = CreateVehicle(hash, sp.x, sp.y, sp.z, 0.0, true, false)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetEntityAsNoLongerNeeded(veh)
    SetModelAsNoLongerNeeded(hash)

    if isNew then SetVehicleColours(veh, 111, 111) end
    notify(isNew and 'Enjoy your new vehicle!' or 'Vehicle retrieved.', 'success')
end)

RegisterNetEvent('eonexis-vehicles:bought')
AddEventHandler('eonexis-vehicles:bought', function(model) table.insert(ownedVehs, model) end)

RegisterNetEvent('eonexis-vehicles:sold')
AddEventHandler('eonexis-vehicles:sold', function(model)
    for i, v in ipairs(ownedVehs) do if v == model then table.remove(ownedVehs, i); break end end
end)

-- Blips, markers, and proximity
CreateThread(function()
    -- Dealership blips
    for _, dlr in ipairs(Config.Dealerships) do
        local b = AddBlipForCoord(dlr.pos.x, dlr.pos.y, dlr.pos.z)
        SetBlipSprite(b, dlr.blipIcon); SetBlipScale(b, 0.8); SetBlipColour(b, dlr.blipColour)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(dlr.label); EndTextCommandSetBlipName(b)
    end
    -- Garage blip
    local gb = AddBlipForCoord(Config.GaragePos.x, Config.GaragePos.y, Config.GaragePos.z)
    SetBlipSprite(gb, 357); SetBlipScale(gb, 0.8); SetBlipColour(gb, 5); SetBlipAsShortRange(gb, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('My Garage'); EndTextCommandSetBlipName(gb)

    while true do
        Wait(0)
        local myPos = GetEntityCoords(PlayerPedId())

        -- Check each dealership
        for _, dlr in ipairs(Config.Dealerships) do
            local dist = #(myPos - dlr.pos)
            if dist < 60 then
                DrawMarker(1, dlr.pos.x, dlr.pos.y, dlr.pos.z - 0.5,
                    0,0,0, 0,0,0, 2.5,2.5,0.7, 255,165,0, 120, false, true, 2, false, nil, nil, false)
            end
            if dist < 3.0 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ ' .. dlr.label)
                EndTextCommandDisplayHelp(0, false, true, -1)
                if (IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176)) and not menuOpen then
                    openDealer(dlr)
                end
            end
        end

        -- Garage
        local gDist = #(myPos - Config.GaragePos)
        if gDist < 60 then
            DrawMarker(1, Config.GaragePos.x, Config.GaragePos.y, Config.GaragePos.z - 0.5,
                0,0,0, 0,0,0, 2.5,2.5,0.7, 80,200,80, 120, false, true, 2, false, nil, nil, false)
        end
        if gDist < 3.0 then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ My Garage')
            EndTextCommandDisplayHelp(0, false, true, -1)
            if (IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176)) and not menuOpen then
                openGarage()
            end
        end
    end
end)

-- Event hook for controller shortcut
AddEventHandler('eonexis-vehicles:openGarage', function() openGarage() end)
