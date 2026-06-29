-- eonexis-vehicles — client

local menuOpen    = false
local menuMode    = nil   -- 'dealer' | 'garage'
local ownedVehs   = {}
local activeVeh   = nil   -- spawned owned vehicle entity

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Vehicles', msg, t or 'info', 4000)
    end
end

-- Receive owned vehicle list
RegisterNetEvent('eonexis-vehicles:receiveOwned')
AddEventHandler('eonexis-vehicles:receiveOwned', function(vehs)
    ownedVehs = vehs or {}
end)

AddEventHandler('onClientGameTypeStart', function()
    Wait(3500)
    TriggerServerEvent('eonexis-vehicles:requestOwned')
end)

local function openDealer()
    if menuOpen then return end
    menuOpen = true; menuMode = 'dealer'
    SetNuiFocus(true, true)
    SendNUIMessage({ action='showDealer', vehicles=Config.Vehicles })
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
    SendNUIMessage({ action='showGarage', vehicles=list })
end

-- NUI callbacks
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

-- Server spawns vehicle
RegisterNetEvent('eonexis-vehicles:spawnVehicle')
AddEventHandler('eonexis-vehicles:spawnVehicle', function(model, isNew)
    menuOpen = false; menuMode = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hide' })

    local hash = GetHashKey(model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) do Wait(100); t = t + 100; if t > 10000 then return end end

    local sp = Config.DealershipSpawn
    if not isNew then sp = Config.GarageSpawn end
    local veh = CreateVehicle(hash, sp.x, sp.y, sp.z, 0.0, true, false)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetEntityAsNoLongerNeeded(veh)
    SetModelAsNoLongerNeeded(hash)
    activeVeh = veh

    if isNew then
        -- New purchase: nice color
        SetVehicleColours(veh, 111, 111)
        notify('Enjoy your new vehicle!', 'success')
    else
        notify('Vehicle retrieved from garage.', 'info')
    end
end)

RegisterNetEvent('eonexis-vehicles:bought')
AddEventHandler('eonexis-vehicles:bought', function(model)
    table.insert(ownedVehs, model)
end)

RegisterNetEvent('eonexis-vehicles:sold')
AddEventHandler('eonexis-vehicles:sold', function(model)
    for i, v in ipairs(ownedVehs) do
        if v == model then table.remove(ownedVehs, i); break end
    end
end)

-- Draw markers + prompts
CreateThread(function()
    -- Dealership blip
    local dBlip = AddBlipForCoord(Config.DealershipPos.x, Config.DealershipPos.y, Config.DealershipPos.z)
    SetBlipSprite(dBlip, 326); SetBlipScale(dBlip, 0.8); SetBlipColour(dBlip, 3)
    SetBlipAsShortRange(dBlip, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Premium Deluxe Motorsport'); EndTextCommandSetBlipName(dBlip)

    local gBlip = AddBlipForCoord(Config.GaragePos.x, Config.GaragePos.y, Config.GaragePos.z)
    SetBlipSprite(gBlip, 357); SetBlipScale(gBlip, 0.8); SetBlipColour(gBlip, 5)
    SetBlipAsShortRange(gBlip, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('My Garage'); EndTextCommandSetBlipName(gBlip)

    while true do
        Wait(0)
        local myPos = GetEntityCoords(PlayerPedId())

        -- Dealership
        local dDist = #(myPos - Config.DealershipPos)
        DrawMarker(1, Config.DealershipPos.x, Config.DealershipPos.y, Config.DealershipPos.z - 0.5,
            0,0,0, 0,0,0, 2.0,2.0,0.5, 255,165,0, 120, false, true, 2, false, nil, nil, false)
        if dDist < 2.5 then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Open Dealership')
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustPressed(0, 38) and not menuOpen then openDealer() end
        end

        -- Garage
        local gDist = #(myPos - Config.GaragePos)
        DrawMarker(1, Config.GaragePos.x, Config.GaragePos.y, Config.GaragePos.z - 0.5,
            0,0,0, 0,0,0, 2.0,2.0,0.5, 80,200,80, 120, false, true, 2, false, nil, nil, false)
        if gDist < 2.5 then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Open Garage')
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustPressed(0, 38) and not menuOpen then openGarage() end
        end

        -- Controller: also accept DPAD_RIGHT (same input id on gamepad)
        if IsControlJustPressed(0, 38) then end  -- already handled above
    end
end)
