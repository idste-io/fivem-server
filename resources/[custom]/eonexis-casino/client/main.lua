-- eonexis-casino — client

local casinoOpen = false

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Casino', msg, t or 'info', 4000)
    end
end

local function openCasino()
    if casinoOpen then return end
    casinoOpen = true
    SetNuiFocus(true, true)
    -- Send prizes config to NUI
    local prizes = {}
    for _, p in ipairs(Config.Prizes) do
        table.insert(prizes, { label=p.label, colour=p.colour })
    end
    SendNUIMessage({ action='open', prizes=prizes, cost=Config.SpinCost })
end

local function closeCasino()
    casinoOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
end

-- Marker at casino location
CreateThread(function()
    local casinoBlip = AddBlipForCoord(Config.CasinoPos.x, Config.CasinoPos.y, Config.CasinoPos.z)
    SetBlipSprite(casinoBlip, 404)
    SetBlipColour(casinoBlip, 46)
    SetBlipScale(casinoBlip, 1.0)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Lucky Wheel Casino')
    EndTextCommandSetBlipName(casinoBlip)

    while true do
        Wait(0)
        local pos = Config.CasinoPos
        DrawMarker(1, pos.x, pos.y, pos.z - 1.0, 0,0,0, 0,0,0, 1.5,1.5,0.5, 255,180,0,180, false, true, 2, nil,nil, false)

        local ped = PlayerPedId()
        local px,py,pz = table.unpack(GetEntityCoords(ped))
        local dist = #(vector3(px,py,pz) - pos)

        if dist < 2.5 then
            if not casinoOpen then
                DrawText3D(pos.x, pos.y, pos.z + 0.5, '~g~[E]~w~ Lucky Wheel Casino')
            end
            if IsControlJustReleased(0, 38) or (not IsUsingKeyboard(2) and IsControlJustReleased(0, 176)) then
                if casinoOpen then closeCasino() else openCasino() end
            end
        end
    end
end)

-- NUI callbacks
RegisterNUICallback('close', function(_, cb) cb({}); closeCasino() end)

RegisterNUICallback('spin', function(_, cb)
    cb({})
    TriggerServerEvent('eonexis-casino:spin')
end)

RegisterNetEvent('eonexis-casino:spinResult')
AddEventHandler('eonexis-casino:spinResult', function(prizeIndex, prize)
    -- Tell NUI to animate wheel to this segment
    SendNUIMessage({ action='spinResult', prizeIndex=prizeIndex, prize=prize })
end)

RegisterNetEvent('eonexis-casino:error')
AddEventHandler('eonexis-casino:error', function(msg)
    SendNUIMessage({ action='error', msg=msg })
    notify(msg, 'error')
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
