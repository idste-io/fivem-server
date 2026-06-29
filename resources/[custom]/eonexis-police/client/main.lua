-- eonexis-police — client

local wantedStars = 0
local isCuffed    = false
local isJailed    = false
local onDuty      = false
local officerBlips = {}

-- Station blips
CreateThread(function()
    for _, s in ipairs(Config.Stations) do
        local b = AddBlipForCoord(s.pos.x, s.pos.y, s.pos.z)
        SetBlipSprite(b, 60)   -- police station icon
        SetBlipColour(b, 3)
        SetBlipScale(b, 0.9)
        SetBlipAsShortRange(b, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(s.name)
        EndTextCommandSetBlipName(b)
    end
end)

-- ── Duty status ───────────────────────────────────────────────────────────────

RegisterCommand('duty', function()
    local job = 'police' -- resolved server-side, but guard locally
    TriggerNetEvent('eonexis-police:setDuty', not onDuty)
end, false)

RegisterNetEvent('eonexis-police:dutyOn')
AddEventHandler('eonexis-police:dutyOn', function()
    onDuty = true
    -- Apply police ped skin
    local ped = PlayerPedId()
    RequestModel('s_m_y_cop_01')
    while not HasModelLoaded('s_m_y_cop_01') do Wait(0) end
    SetPlayerModel(PlayerId(), 's_m_y_cop_01')
    SetModelAsNoLongerNeeded('s_m_y_cop_01')
    -- Give weapon
    GiveWeaponToPed(PlayerPedId(), GetHashKey(Config.PoliceWeapon), 100, false, true)
    -- Spawn police vehicle nearby
    local pos = GetEntityCoords(PlayerPedId())
    local veh = CreateVehicle(GetHashKey(Config.PoliceVehicle), pos.x + 3.0, pos.y, pos.z, GetEntityHeading(PlayerPedId()), true, false)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
end)

RegisterNetEvent('eonexis-police:dutyOff')
AddEventHandler('eonexis-police:dutyOff', function()
    onDuty = false
    -- Remove police weapons (keep pistol only)
    RemoveWeaponFromPed(PlayerPedId(), GetHashKey(Config.PoliceWeapon))
end)

-- ── Officer blips ─────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-police:officerUpdate')
AddEventHandler('eonexis-police:officerUpdate', function(officers)
    for _, b in pairs(officerBlips) do RemoveBlip(b) end
    officerBlips = {}
    for _, o in ipairs(officers) do
        if o.id ~= GetPlayerServerId(PlayerId()) then
            local target = GetPlayerPed(GetPlayerFromServerId(o.id))
            if DoesEntityExist(target) then
                local b = AddBlipForEntity(target)
                SetBlipSprite(b, 1)
                SetBlipColour(b, 3)
                SetBlipScale(b, 0.8)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString('Officer ' .. o.name)
                EndTextCommandSetBlipName(b)
                officerBlips[o.id] = b
            end
        end
    end
end)

-- ── Cuff ─────────────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-police:cuffed')
AddEventHandler('eonexis-police:cuffed', function(officerId)
    isCuffed = true
    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    -- Play cuff animation
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do Wait(0) end
    TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)

    CreateThread(function()
        while isCuffed do
            -- Block movement
            DisableControlAction(0, 30, true)  -- move LR
            DisableControlAction(0, 31, true)  -- move UD
            DisableControlAction(0, 21, true)  -- sprint
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)  -- look controls
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            Wait(0)
        end
        ClearPedTasks(ped)
    end)
end)

RegisterNetEvent('eonexis-police:uncuffed')
AddEventHandler('eonexis-police:uncuffed', function()
    isCuffed = false
    ClearPedTasks(PlayerPedId())
end)

-- ── Jail ─────────────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-police:jailed')
AddEventHandler('eonexis-police:jailed', function(jailPos, heading, mins)
    isJailed = true
    local ped = PlayerPedId()
    SetEntityCoords(ped, jailPos.x, jailPos.y, jailPos.z, false, false, false, true)
    SetEntityHeading(ped, heading)
    exports['eonexis-notify']:Notify('⚖️ Jailed', ('Sentence: %d min. Behave or ask for release.'):format(mins), 'error', 10000)

    -- Auto-release
    CreateThread(function()
        Wait(mins * 60 * 1000)
        if isJailed then
            isJailed = false
            local spawn = Config.Stations[1].pos
            SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
            exports['eonexis-notify']:Notify('⚖️ Released', 'Sentence served. Stay out of trouble.', 'success', 5000)
        end
    end)
end)

RegisterNetEvent('eonexis-police:released')
AddEventHandler('eonexis-police:released', function()
    isJailed = false
    local spawn = Config.Stations[1].pos
    SetEntityCoords(PlayerPedId(), spawn.x, spawn.y, spawn.z, false, false, false, true)
    exports['eonexis-notify']:Notify('Released', 'You are free to go.', 'success', 5000)
end)

-- ── Wanted level HUD ─────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-police:updateWanted')
AddEventHandler('eonexis-police:updateWanted', function(stars)
    wantedStars = stars
    if stars > 0 then
        exports['eonexis-notify']:Notify('⭐ Wanted', ('Wanted level: %d star%s!'):format(stars, stars > 1 and 's' or ''), 'warning', 4000)
    else
        exports['eonexis-notify']:Notify('Cleared', 'Wanted level cleared.', 'success', 3000)
    end
end)

RegisterNetEvent('eonexis-police:clearWanted')
AddEventHandler('eonexis-police:clearWanted', function()
    wantedStars = 0
end)

TriggerEvent('chat:addSuggestion', '/duty',   'Toggle on/off duty (police only)', {})
TriggerEvent('chat:addSuggestion', '/cuff',   'Cuff a player', {{ name='id/name', help='Target' }})
TriggerEvent('chat:addSuggestion', '/jail',   'Jail a player', {{ name='id/name', help='Target' }, { name='minutes', help='Duration' }})
TriggerEvent('chat:addSuggestion', '/911',    'Emergency call', {{ name='message', help='Emergency' }})
TriggerEvent('chat:addSuggestion', '/radio',  'Police radio', {{ name='message', help='Message' }})
