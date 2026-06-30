-- eonexis-drugs — client

local producing = false
local selling   = false

-- Lab markers + blips
CreateThread(function()
    for _, lab in ipairs(Config.Labs) do
        local b = AddBlipForCoord(lab.pos.x, lab.pos.y, lab.pos.z)
        SetBlipSprite(b, 469)
        SetBlipColour(b, 5)   -- yellow
        SetBlipScale(b, 0.7)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Drug Lab — ' .. lab.name)
        EndTextCommandSetBlipName(b)
    end
    for _, d in ipairs(Config.Dealers) do
        local b = AddBlipForCoord(d.pos.x, d.pos.y, d.pos.z)
        SetBlipSprite(b, 140)
        SetBlipColour(b, 2)   -- green
        SetBlipScale(b, 0.7)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Drug Dealer')
        EndTextCommandSetBlipName(b)
    end
end)

-- Main loop: lab proximity
CreateThread(function()
    while true do
        local ped   = PlayerPedId()
        local pos   = GetEntityCoords(ped)
        local sleep = 500

        for _, lab in ipairs(Config.Labs) do
            local dist = #(pos - lab.pos)
            if dist < 25.0 then
                sleep = 0
                DrawMarker(1, lab.pos.x, lab.pos.y, lab.pos.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    255, 220, 50, 120, false, true, 2, nil, nil, false)

                if dist < Config.MarkerRadius then
                    if not producing then
                        exports['eonexis-notify']:Notify('Drug Lab', 'Press [E] to start ' .. lab.product .. ' production', 'info', 2000)
                        if IsControlJustPressed(0, 38) then
                            producing = true
                            TriggerServerEvent('eonexis-drugs:startProd', lab.id)
                        end
                    end
                end
            end
        end

        -- Dealer proximity
        for _, d in ipairs(Config.Dealers) do
            local dist = #(pos - d.pos)
            if dist < 20.0 then
                sleep = 0
                DrawMarker(1, d.pos.x, d.pos.y, d.pos.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    50, 255, 80, 120, false, true, 2, nil, nil, false)

                if dist < Config.MarkerRadius then
                    if not selling then
                        exports['eonexis-notify']:Notify('Dealer', 'Press [E] to sell drugs', 'info', 2000)
                        if IsControlJustPressed(0, 38) then
                            selling = true
                            showSellMenu()
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function showSellMenu()
    local inv = {}
    local drugs = { 'weed', 'cocaine', 'meth' }
    -- Check inventory via server
    TriggerServerEvent('eonexis-drugs:requestInventory')
end

-- Server sends inventory, show what can be sold
RegisterNetEvent('eonexis-drugs:receiveInventory')
AddEventHandler('eonexis-drugs:receiveInventory', function(inv)
    local hasDrugs = false
    for _, drug in ipairs({'weed', 'cocaine', 'meth'}) do
        if (inv[drug] or 0) > 0 then
            hasDrugs = true
            -- Auto-sell all drugs
            TriggerServerEvent('eonexis-drugs:sell', drug)
        end
    end
    if not hasDrugs then
        exports['eonexis-notify']:Notify('Dealer', 'No drugs to sell.', 'error', 3000)
    end
    selling = false
end)

-- Production done
RegisterNetEvent('eonexis-drugs:prodBegin')
AddEventHandler('eonexis-drugs:prodBegin', function(labId, duration)
    exports['eonexis-notify']:Notify('Lab', ('Processing... %ds. Stay nearby!'):format(duration), 'warning', duration * 1000)
    CreateThread(function()
        Wait(duration * 1000)
        TriggerServerEvent('eonexis-drugs:prodDone', labId)
        producing = false
    end)
end)

-- Abort if player leaves
RegisterNetEvent('eonexis-drugs:policeAlert')
AddEventHandler('eonexis-drugs:policeAlert', function(location)
    exports['eonexis-notify']:Notify('🚨 Police Alert', 'Drug activity reported near ' .. location, 'error', 8000)
end)

-- Handle sell inventory request response
RegisterNetEvent('eonexis-drugs:doSell')
AddEventHandler('eonexis-drugs:doSell', function(drugId)
    TriggerServerEvent('eonexis-drugs:sell', drugId)
end)
