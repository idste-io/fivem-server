-- eonexis-shops — client

local shopOpen  = false
local nearShop  = nil

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Shop', msg, t or 'info', 4000)
    end
end

local function openShop(shop)
    if shopOpen then return end
    shopOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action='open', shopLabel=shop.label, items=Config.Items })
    TriggerServerEvent('eonexis-shops:requestCash')
end

local function closeShop()
    shopOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
end

-- NUI callbacks
RegisterNUICallback('close', function(_, cb)
    cb({})
    closeShop()
end)

RegisterNUICallback('buy', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-shops:buy', data.id)
end)

-- Cash update
RegisterNetEvent('eonexis-shops:updateCash')
AddEventHandler('eonexis-shops:updateCash', function(cash)
    SendNUIMessage({ action='updateCash', cash=cash })
end)

-- Buy result
RegisterNetEvent('eonexis-shops:buyResult')
AddEventHandler('eonexis-shops:buyResult', function(ok, msg, cash)
    if ok then
        SendNUIMessage({ action='updateCash', cash=cash })
        notify(msg, 'success')
    else
        notify(msg, 'error')
    end
end)

-- World markers + proximity thread
CreateThread(function()
    -- Place blips
    for _, shop in ipairs(Config.Shops) do
        local blip = AddBlipForCoord(shop.pos.x, shop.pos.y, shop.pos.z)
        SetBlipSprite(blip, shop.blipSprite)
        SetBlipColour(blip, 2)
        SetBlipScale(blip, 0.75)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(shop.label)
        EndTextCommandSetBlipName(blip)
    end

    while true do
        Wait(0)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        nearShop  = nil

        for _, shop in ipairs(Config.Shops) do
            local dist = #(pos - shop.pos)
            DrawMarker(1, shop.pos.x, shop.pos.y, shop.pos.z - 1.0,
                0,0,0, 0,0,0, 1.2,1.2,0.5, 0,180,100,160, false, true, 2, nil,nil,false)
            if dist < 2.5 then
                nearShop = shop
            end
        end

        if nearShop and not shopOpen then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Shop')
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176) then
                openShop(nearShop)
            end
        end
    end
end)
