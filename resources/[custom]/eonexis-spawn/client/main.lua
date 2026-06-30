-- eonexis-spawn — client (updated: last location + home spawn)

local chosen = false

local function doSpawnAt(sp, label)
    TriggerEvent('eonexis-spawn:spawned')  -- anticheat grace before teleport
    exports.spawnmanager:spawnPlayer({
        x = sp.x, y = sp.y, z = sp.z,
        heading = sp.h or 0.0,
        model = 'mp_m_freemode_01',
    }, function()
        TriggerEvent('eonexis-spawn:spawned')  -- also after, in case spawn takes a moment
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'hide' })
        if exports['eonexis-notify'] then
            exports['eonexis-notify']:Notify('Spawn', 'Spawned at ' .. (label or 'location'), 'success', 4000)
        end
    end)
end

-- NUI callbacks
RegisterNUICallback('selectSpawn', function(data, cb)
    chosen = true
    cb({})
    local idx = tonumber(data.index)
    local sp = Config.SpawnPoints[idx] or Config.SpawnPoints[Config.DefaultSpawnIndex]
    doSpawnAt(sp, sp.label)
end)

RegisterNUICallback('spawnLastLocation', function(data, cb)
    chosen = true
    cb({})
    doSpawnAt({ x=data.x, y=data.y, z=data.z, h=data.h }, 'Last Location')
end)

RegisterNUICallback('spawnHome', function(data, cb)
    chosen = true
    cb({})
    doSpawnAt({ x=data.x, y=data.y, z=data.z, h=data.h }, data.label or 'Home')
end)

-- Server sends extra spawn options (last location, home)
RegisterNetEvent('eonexis-spawn:extraOptions')
AddEventHandler('eonexis-spawn:extraOptions', function(opts)
    SendNUIMessage({ action = 'extraOptions', opts = opts })
end)

-- Show menu on first load
AddEventHandler('onClientGameTypeStart', function()
    exports.spawnmanager:setAutoSpawn(false)
    Wait(1500)

    -- Request extra options from server (last location + home)
    TriggerServerEvent('eonexis-spawn:requestOptions')

    -- Standard spawn points
    local spawnData = {}
    for i, sp in ipairs(Config.SpawnPoints) do
        table.insert(spawnData, { index = i, label = sp.label, desc = sp.desc })
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show', spawns = spawnData })

    -- Fallback
    SetTimeout(45000, function()
        if not chosen then
            chosen = true
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'hide' })
            local sp = Config.SpawnPoints[Config.DefaultSpawnIndex]
            doSpawnAt(sp, sp.label)
        end
    end)
end)

AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)
