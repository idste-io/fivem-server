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

-- ── Respawn system ────────────────────────────────────────────────────────────

local function doRespawn()
    spawned = false
    local sp = Config.SpawnPoints[Config.DefaultSpawnIndex]
    doSpawnAt(sp, 'Hospital')
    exports['eonexis-notify']:Notify('Respawn', 'You woke up at the hospital.', 'info', 5000)
end

RegisterCommand('respawn', function()
    if not IsEntityDead(PlayerPedId()) then
        exports['eonexis-notify']:Notify('Respawn', 'You are not dead.', 'error', 3000)
        return
    end
    doRespawn()
end, false)

TriggerEvent('chat:addSuggestion', '/respawn', 'Respawn at the hospital when dead', {})

-- Hold R for 5s when dead to respawn
local respawnHoldStart = nil

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if IsEntityDead(ped) then
            if IsControlPressed(0, 45) then  -- R / INPUT_RELOAD
                if not respawnHoldStart then respawnHoldStart = GetGameTimer() end
                local held  = GetGameTimer() - respawnHoldStart
                local pct   = math.min(held / 5000, 1.0)
                local remaining = math.ceil((5000 - held) / 1000)

                -- Background track
                DrawRect(0.5, 0.92, 0.32, 0.018, 30, 30, 50, 180)
                -- Fill
                DrawRect(0.5 - (0.32 / 2) + (0.32 * pct / 2), 0.92, 0.32 * pct, 0.018, 100, 180, 255, 220)

                SetTextFont(4); SetTextScale(0, 0.32); SetTextColour(255, 255, 255, 255)
                SetTextCentre(true); SetTextOutline()
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(('Hold R to respawn... %ds'):format(remaining))
                EndTextCommandDisplayText(0.5, 0.895)

                if held >= 5000 then
                    respawnHoldStart = nil
                    doRespawn()
                end
            else
                respawnHoldStart = nil
                -- Show dead hint
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Hold ~INPUT_RELOAD~ for 5s to respawn  |  /respawn')
                EndTextCommandDisplayHelp(0, false, true, -1)
            end
        else
            respawnHoldStart = nil
        end
    end
end)

AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)
