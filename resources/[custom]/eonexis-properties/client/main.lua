-- eonexis-properties — client

local ownedProps  = {}
local menuOpen    = false
local nearProp    = nil

-- Receive ownership list from server on spawn
RegisterNetEvent('eonexis-properties:receiveOwned')
AddEventHandler('eonexis-properties:receiveOwned', function(props)
    ownedProps = props or {}
end)

AddEventHandler('onClientGameTypeStart', function()
    Wait(3000)
    TriggerServerEvent('eonexis-properties:requestOwned')
end)

local function owns(id)
    for _, v in ipairs(ownedProps) do if v == id then return true end end
    return false
end

local function openMenu(prop)
    if menuOpen then return end
    menuOpen = true
    local owned = owns(prop.id)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'show',
        prop    = {
            id      = prop.id,
            label   = prop.label,
            type    = prop.type,
            price   = prop.price,
            desc    = prop.desc,
            icon    = prop.icon,
            owned   = owned,
            isHome  = false,  -- server will confirm
        }
    })
end

RegisterNUICallback('buy', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-properties:buy', data.id)
end)

RegisterNUICallback('sell', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-properties:sell', data.id)
end)

RegisterNUICallback('setHome', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-properties:setHome', data.id)
end)

RegisterNUICallback('close', function(_, cb)
    cb({})
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
end)

-- Server responses
RegisterNetEvent('eonexis-properties:bought')
AddEventHandler('eonexis-properties:bought', function(propId)
    table.insert(ownedProps, propId)
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
end)

RegisterNetEvent('eonexis-properties:sold')
AddEventHandler('eonexis-properties:sold', function(propId)
    for i, v in ipairs(ownedProps) do
        if v == propId then table.remove(ownedProps, i); break end
    end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
end)

-- Draw markers and check proximity
CreateThread(function()
    while true do
        Wait(0)
        local myPos = GetEntityCoords(PlayerPedId())
        nearProp = nil

        for _, prop in ipairs(Config.Properties) do
            local dist = #(myPos - prop.blipPos)

            -- Draw marker when close
            if dist < 50.0 then
                local owned = owns(prop.id)
                local r, g, b = owned and 80 or 255, owned and 200 or 165, owned and 80 or 0
                DrawMarker(Config.MarkerType,
                    prop.blipPos.x, prop.blipPos.y, prop.blipPos.z - 0.5,
                    0,0,0, 0,0,0,
                    Config.MarkerRadius, Config.MarkerRadius, 0.5,
                    r, g, b, 120, false, true, 2, false, nil, nil, false)
            end

            if dist < Config.MarkerRadius then
                nearProp = prop
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(
                    owns(prop.id)
                    and string.format('~INPUT_CONTEXT~ Manage %s', prop.label)
                    or  string.format('~INPUT_CONTEXT~ View %s (%s$%d)', prop.label, Config.CurrencySymbol or '$', prop.price)
                )
                EndTextCommandDisplayHelp(0, false, true, -1)
            end
        end

        -- E key to open menu
        if nearProp and IsControlJustPressed(0, 38) and not menuOpen then
            openMenu(nearProp)
        end
    end
end)

-- Add blips for all properties
CreateThread(function()
    for _, prop in ipairs(Config.Properties) do
        local blip = AddBlipForCoord(prop.blipPos.x, prop.blipPos.y, prop.blipPos.z)
        SetBlipSprite(blip, prop.type == 'house' and 40 or 374)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, prop.type == 'house' and 2 or 5)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(prop.label)
        EndTextCommandSetBlipName(blip)
    end
end)
