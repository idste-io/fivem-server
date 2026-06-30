-- eonexis-crafting — client

local nuiOpen = false

-- Workbench blips
CreateThread(function()
    for _, wb in ipairs(Config.Workbenches) do
        local b = AddBlipForCoord(wb.pos.x, wb.pos.y, wb.pos.z)
        SetBlipSprite(b, 352)
        SetBlipColour(b, 8)   -- orange
        SetBlipScale(b, 0.8)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Workbench — ' .. wb.name)
        EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    while true do
        local ped   = PlayerPedId()
        local pos   = GetEntityCoords(ped)
        local sleep = 500

        for _, wb in ipairs(Config.Workbenches) do
            local dist = #(pos - wb.pos)
            if dist < 20.0 then
                sleep = 0
                DrawMarker(1, wb.pos.x, wb.pos.y, wb.pos.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    255, 140, 0, 120, false, true, 2, nil, nil, false)

                if dist < Config.MarkerRadius then
                    if not nuiOpen then
                        exports['eonexis-notify']:Notify('Workbench', 'Press [E] to craft items', 'info', 2000)
                        if IsControlJustPressed(0, 38) then
                            openCraftingNUI()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function openCraftingNUI()
    nuiOpen = true
    SetNuiFocus(true, true)
    TriggerServerEvent('eonexis-crafting:requestRecipes')
end

RegisterNetEvent('eonexis-crafting:receiveRecipes')
AddEventHandler('eonexis-crafting:receiveRecipes', function(recipes, inv)
    SendNUIMessage({ action='open', recipes=recipes, inventory=inv })
end)

RegisterNUICallback('craft', function(data, cb)
    TriggerServerEvent('eonexis-crafting:craft', data.recipeId)
    -- Brief delay then refresh inventory display
    Citizen.SetTimeout(1500, function()
        TriggerServerEvent('eonexis-crafting:requestRecipes')
    end)
    cb({})
end)

RegisterNUICallback('close', function(_, cb)
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
    cb({})
end)

-- Close on Escape
CreateThread(function()
    while true do
        Wait(0)
        if nuiOpen and IsControlJustPressed(0, 200) then  -- ESC
            nuiOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action='close' })
        end
    end
end)
