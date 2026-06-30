-- eonexis-spawn — client
-- Auto-spawns player at city center immediately, no NUI chooser.
-- Players can use the Phone (TAB) → Spawn app to fast-travel after loading in.

local spawned = false

AddEventHandler('onClientGameTypeStart', function()
    if spawned then return end
    exports.spawnmanager:setAutoSpawn(false)
    Wait(2000)

    -- Get last location from server before spawning
    TriggerServerEvent('eonexis-spawn:requestOptions')
end)

-- Server returns extra options (last location, home)
-- We use the best option: home > last location > default city center
RegisterNetEvent('eonexis-spawn:extraOptions')
AddEventHandler('eonexis-spawn:extraOptions', function(opts)
    if spawned then return end

    local sp = Config.SpawnPoints[Config.DefaultSpawnIndex]  -- default fallback

    for _, opt in ipairs(opts) do
        if opt.type == 'home' then
            sp = { x=opt.x, y=opt.y, z=opt.z, h=opt.h, label=opt.label }
            break
        elseif opt.type == 'last' then
            sp = { x=opt.x, y=opt.y, z=opt.z, h=opt.h, label='Last Location' }
        end
    end

    doSpawnAt(sp, sp.label)
end)

-- Fallback: if server doesn't respond in 5s, spawn at default
CreateThread(function()
    Wait(7000)
    if not spawned then
        local sp = Config.SpawnPoints[Config.DefaultSpawnIndex]
        doSpawnAt(sp, sp.label)
    end
end)

function doSpawnAt(sp, label)
    if spawned then return end
    spawned = true
    TriggerEvent('eonexis-spawn:spawned')  -- anticheat grace
    exports.spawnmanager:spawnPlayer({
        x = sp.x, y = sp.y, z = sp.z,
        heading = sp.h or 0.0,
        model = 'mp_m_freemode_01',
    }, function()
        TriggerEvent('eonexis-spawn:spawned')  -- anticheat grace again after spawn completes
        if exports['eonexis-notify'] then
            exports['eonexis-notify']:Notify('Welcome', 'Press TAB to open your phone.', 'info', 6000)
        end
        -- Tell character mod we've spawned so it can show the creator if needed
        TriggerEvent('eonexis-spawn:done')
    end)
end

AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)
