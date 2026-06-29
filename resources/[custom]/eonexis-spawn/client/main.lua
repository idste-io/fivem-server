-- eonexis-spawn — client

local chosen = false

local function doSpawn(idx)
    local sp = Config.SpawnPoints[idx] or Config.SpawnPoints[Config.DefaultSpawnIndex]
    exports.spawnmanager:spawnPlayer({
        x = sp.x, y = sp.y, z = sp.z,
        heading = sp.h,
        model = 'mp_m_freemode_01',
    }, function()
        TriggerEvent('sessionmanager:playerLoaded')
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'hide' })
        if exports['eonexis-notify'] then
            exports['eonexis-notify']:Notify('Spawn', 'Spawned at ' .. sp.label, 'success', 4000)
        end
    end)
end

-- NUI callback — player clicked a spawn button
RegisterNUICallback('selectSpawn', function(data, cb)
    chosen = true
    cb({})
    doSpawn(tonumber(data.index))
end)

-- Show menu on first load
AddEventHandler('onClientGameTypeStart', function()
    exports.spawnmanager:setAutoSpawn(false)
    Wait(1000)

    -- Build spawn list for NUI
    local spawnData = {}
    for i, sp in ipairs(Config.SpawnPoints) do
        table.insert(spawnData, { index = i, label = sp.label, desc = sp.desc })
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show', spawns = spawnData })

    -- Fallback if NUI takes too long
    SetTimeout(30000, function()
        if not chosen then
            chosen = true
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'hide' })
            doSpawn(Config.DefaultSpawnIndex)
        end
    end)
end)
