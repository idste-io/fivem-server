-- eonexis-clothing — client

local nuiOpen = false

CreateThread(function()
    for _, s in ipairs(Config.Stores) do
        local b = AddBlipForCoord(s.pos.x, s.pos.y, s.pos.z)
        SetBlipSprite(b, 73)   -- clothing store icon
        SetBlipColour(b, 30)
        SetBlipScale(b, 0.8)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Clothing — ' .. s.name)
        EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    while true do
        local ped   = PlayerPedId()
        local pos   = GetEntityCoords(ped)
        local sleep = 500

        for _, s in ipairs(Config.Stores) do
            local dist = #(pos - s.pos)
            if dist < 20.0 then
                sleep = 0
                DrawMarker(1, s.pos.x, s.pos.y, s.pos.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    255, 100, 200, 120, false, true, 2, nil, nil, false)

                if dist < Config.MarkerRadius then
                    if not nuiOpen then
                        exports['eonexis-notify']:Notify(s.name, 'Press [E] to open wardrobe', 'info', 2000)
                        if IsControlJustPressed(0, 38) then
                            openWardrobe()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function openWardrobe()
    nuiOpen = true
    SetNuiFocus(true, true)
    -- Get current component drawables/textures to populate UI
    local ped = PlayerPedId()
    local current = {}
    for _, comp in ipairs(Config.Components) do
        current[tostring(comp.id)] = {
            drawable = GetPedDrawableVariation(ped, comp.id),
            texture  = GetPedTextureVariation(ped, comp.id),
            maxDraw  = GetNumberOfPedDrawableVariations(ped, comp.id) - 1,
            maxTex   = 0,
        }
        if current[tostring(comp.id)].maxDraw >= 0 then
            current[tostring(comp.id)].maxTex = GetNumberOfPedTextureVariations(ped, comp.id, current[tostring(comp.id)].drawable) - 1
        end
    end
    SendNUIMessage({ action='open', components=Config.Components, current=current })
end

RegisterNUICallback('preview', function(data, cb)
    -- Live preview: apply component temporarily
    local ped = PlayerPedId()
    SetPedComponentVariation(ped, tonumber(data.comp), tonumber(data.drawable), tonumber(data.texture), 2)
    cb({})
end)

RegisterNUICallback('save', function(data, cb)
    -- Save the current outfit (components already applied via preview)
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
    exports['eonexis-notify']:Notify('Wardrobe', 'Outfit saved!', 'success', 3000)
    -- Tell server to charge if applicable
    if Config.ChangeCost > 0 then
        TriggerNetEvent('eonexis-clothing:pay', Config.ChangeCost)
    end
    cb({})
end)

RegisterNUICallback('close', function(_, cb)
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
    cb({})
end)

CreateThread(function()
    while true do
        Wait(0)
        if nuiOpen and IsControlJustPressed(0, 200) then
            nuiOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action='close' })
        end
    end
end)
