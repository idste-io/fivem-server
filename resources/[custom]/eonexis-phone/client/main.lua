-- eonexis-phone — client

local phoneOpen  = false
local activeApp  = nil
local cash       = 0
local bank       = 0
local job        = 'unemployed'
local myLicenses = {}
local isAdmin    = false
local dutyOn     = false

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Phone', msg, t or 'info', 4000)
    end
end

local function sendSpawnLocs()
    local locs = {}
    for _, l in ipairs(Config.SpawnLocations) do
        table.insert(locs, { id=l.id, label=l.label, desc=l.desc })
    end
    SendNUIMessage({ action='setSpawnLocs', locs=locs })
end

local function sendGPSLocs()
    local ok, locs = pcall(function() return exports['eonexis-gps']:getGPSLocations() end)
    if ok and locs then SendNUIMessage({ action='setGPSLocs', locs=locs }) end
end

local function getJobDefs()
    local ok, defs = pcall(function() return exports['eonexis-jobs']:getJobDefs() end)
    if ok and defs then return defs end
    return {}
end

local function getLicenseDefs()
    local ok, defs = pcall(function() return exports['eonexis-jobs']:getLicenseDefs() end)
    if ok and defs then return defs end
    return {}
end

local function sendCharData()
    local ok, char = pcall(function() return exports['eonexis-character']:getMyCharacter() end)
    if ok and char then
        SendNUIMessage({ action='setCharData', char=char })
    end
end

local function openPhone()
    if phoneOpen then return end
    phoneOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'open',
        cash     = cash,
        bank     = bank,
        job      = job,
        licenses = myLicenses,
        isAdmin  = isAdmin,
        dutyOn   = dutyOn,
        jobs     = getJobDefs(),
        licDefs  = getLicenseDefs(),
    })
    sendSpawnLocs()
    sendGPSLocs()
    sendCharData()
end

local function closePhone()
    phoneOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
end

-- Toggle phone: P key or controller SELECT/BACK (196) or Menu button hold
RegisterKeyMapping('+openphone', 'Open Eonexis Phone', 'keyboard', 'p')
RegisterCommand('+openphone', function()
    if phoneOpen then closePhone() else openPhone() end
end, false)

-- Controller: BACK/SELECT button (196) opens phone
CreateThread(function()
    while true do
        Wait(0)
        if not IsUsingKeyboard(2) then
            -- Hold BACK (196) for 0.6s to open phone without conflicting with menu
            if IsControlPressed(0, 196) then
                Wait(600)
                if IsControlPressed(0, 196) then
                    if phoneOpen then closePhone() else openPhone() end
                    Wait(500)
                end
            end
        end
    end
end)

-- TAB also opens the phone (suppresses the weapon wheel on TAB while on foot).
-- Control 37 = INPUT_SELECT_WEAPON (TAB). Vehicle weapon wheel is left untouched.
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            DisableControlAction(0, 37, true)
            if IsDisabledControlJustPressed(0, 37) then
                if phoneOpen then closePhone() else openPhone() end
                Wait(300)
            end
        end
    end
end)

-- Receive economy data updates
RegisterNetEvent('eonexis-economy:updateCash')
AddEventHandler('eonexis-economy:updateCash', function(v)
    cash = v
    if phoneOpen then SendNUIMessage({ action='updateMoney', cash=v, bank=bank }) end
end)

RegisterNetEvent('eonexis-economy:updateBank')
AddEventHandler('eonexis-economy:updateBank', function(v)
    bank = v
    if phoneOpen then SendNUIMessage({ action='updateMoney', cash=cash, bank=v }) end
end)

RegisterNetEvent('eonexis-economy:updateJob')
AddEventHandler('eonexis-economy:updateJob', function(v)
    job = v
    if phoneOpen then SendNUIMessage({ action='updateJob', job=v, licenses=myLicenses }) end
end)

-- License updates from jobs mod
RegisterNetEvent('eonexis-jobs:licenseGranted')
AddEventHandler('eonexis-jobs:licenseGranted', function(licId)
    local found = false
    for _, l in ipairs(myLicenses) do if l == licId then found = true; break end end
    if not found then table.insert(myLicenses, licId) end
    if phoneOpen then SendNUIMessage({ action='updateJob', job=job, licenses=myLicenses }) end
end)

RegisterNetEvent('eonexis-jobs:setLicenses')
AddEventHandler('eonexis-jobs:setLicenses', function(lics)
    myLicenses = lics or {}
end)

RegisterNetEvent('eonexis-economy:receiveData')
AddEventHandler('eonexis-economy:receiveData', function(d)
    cash = d.cash; bank = d.bank; job = d.job
end)

-- NUI callbacks
RegisterNUICallback('close', function(_, cb)
    cb({})
    closePhone()
end)

RegisterNUICallback('deposit', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-phone:deposit', tonumber(data.amount))
end)

RegisterNUICallback('withdraw', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-phone:withdraw', tonumber(data.amount))
end)

RegisterNUICallback('requestWork', function(_, cb)
    cb({})
    closePhone()
    TriggerServerEvent('eonexis-jobs:requestTask')
end)

RegisterNUICallback('quitJob', function(_, cb)
    cb({})
    TriggerServerEvent('eonexis-jobs:quitJob')
    closePhone()
end)

-- Apply for a job via phone — waypoint to job center
RegisterNUICallback('applyJob', function(data, cb)
    cb({})
    closePhone()
    -- Set waypoint to job center and pre-select the job when player gets there
    local ok, jpos = pcall(function() return exports['eonexis-jobs']:getJobCenterPos() end)
    if ok and jpos then
        local u = jpos.x / 8192.0 + 0.5
        local v = jpos.y / 8192.0 * -1.0 + 0.5
        SetNewWaypoint(u, v)
    end
    -- Tell jobs mod to auto-select this job when player arrives at job center
    TriggerServerEvent('eonexis-jobs:pendingJobSelect', data.jobId)
    exports['eonexis-notify']:Notify('Jobs', 'Head to the Job Center (yellow marker) to start!', 'info', 5000)
end)

-- Waypoint to license office
RegisterNUICallback('waypointToLicense', function(data, cb)
    cb({})
    closePhone()
    local ok, lpos = pcall(function() return exports['eonexis-jobs']:getLicensePos(data.licId) end)
    if ok and lpos then
        local u = lpos.x / 8192.0 + 0.5
        local v = lpos.y / 8192.0 * -1.0 + 0.5
        SetNewWaypoint(u, v)
        exports['eonexis-notify']:Notify('License Office', 'Head to the marker to purchase your license.', 'info', 5000)
    end
end)

-- Police duty toggle from phone
RegisterNUICallback('toggleDuty', function(_, cb)
    cb({})
    TriggerServerEvent('eonexis-police:setDuty', not dutyOn)
    dutyOn = not dutyOn
    SendNUIMessage({ action='setDuty', dutyOn=dutyOn })
end)

RegisterNUICallback('openInventory', function(_, cb)
    cb({})
    closePhone()
    TriggerEvent('eonexis-inventory:open')
end)

RegisterNUICallback('getPlayers', function(_, cb)
    cb({})
    TriggerServerEvent('eonexis-phone:getPlayers')
end)

RegisterNetEvent('eonexis-phone:receivePlayerList')
AddEventHandler('eonexis-phone:receivePlayerList', function(players)
    SendNUIMessage({ action='showPlayers', players=players })
end)

-- ── Spawn App ────────────────────────────────────────────────────────────────

RegisterNUICallback('spawnParachute', function(data, cb)
    cb({})
    closePhone()

    local loc = nil
    for _, l in ipairs(Config.SpawnLocations) do
        if l.id == data.id then loc = l; break end
    end
    if not loc then return end

    TriggerEvent('eonexis-phone:spawned')  -- anticheat grace
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, GetHashKey('gadget_parachute'), 1, false, true)
    SetEntityCoords(ped, loc.x, loc.y, loc.airZ, false, false, false, true)

    notify('Parachute activated! Pull chute with F!', 'info')
end)

RegisterNUICallback('spawnBuilding', function(data, cb)
    cb({})
    TriggerEvent('eonexis-phone:spawned')  -- anticheat grace before server teleports us
    TriggerServerEvent('eonexis-phone:buildingSpawn', data.id)
end)

RegisterNetEvent('eonexis-phone:doSpawn')
AddEventHandler('eonexis-phone:doSpawn', function(loc)
    closePhone()
    TriggerEvent('eonexis-phone:spawned')  -- anticheat grace
    local ped = PlayerPedId()
    SetEntityCoords(ped, loc.x, loc.y, loc.z + 0.5, false, false, false, true)
    notify('Spawned at ' .. loc.label, 'success')
end)

RegisterNetEvent('eonexis-phone:notify')
AddEventHandler('eonexis-phone:notify', function(msg, t)
    notify(msg, t)
end)

-- GPS waypoint setter from phone NUI
RegisterNUICallback('setWaypoint', function(data, cb)
    cb({})
    closePhone()
    local x, y = tonumber(data.x), tonumber(data.y)
    -- Convert world coords to minimap UV (GTA map is 8192x8192 centred at 0,0)
    local u = x / 8192.0 + 0.5
    local v = y / 8192.0 * -1.0 + 0.5
    SetNewWaypoint(u, v)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('GPS', 'Waypoint set!', 'success', 3000)
    end
end)

-- Send GPS locations when phone opens
AddEventHandler('eonexis-phone:open', function()
    if phoneOpen then closePhone() else openPhone() end
end)

-- ── Character App ─────────────────────────────────────────────────────────────

RegisterNUICallback('openCharacterCreator', function(_, cb)
    cb({})
    closePhone()
    local ok, _ = pcall(function() exports['eonexis-character']:openCharacterCreator() end)
end)

-- ── Quests App ────────────────────────────────────────────────────────────────

RegisterNUICallback('openQuests', function(_, cb)
    cb({})
    closePhone()
    TriggerEvent('eonexis-quests:openNUI')
end)

-- ── Stats App ─────────────────────────────────────────────────────────────────

RegisterNUICallback('getStats', function(_, cb)
    cb({})
    local skillLevel = 1
    local ok, lvl = pcall(function() return exports['eonexis-skilltree']:getLevel() end)
    if ok and lvl then skillLevel = lvl end
    SendNUIMessage({ action='setStats', cash=cash, bank=bank, job=job, skill=skillLevel })
end)

-- ── Admin App ─────────────────────────────────────────────────────────────────

RegisterNUICallback('adminSpawnVehicle', function(data, cb)
    cb({})
    if not isAdmin then return end
    closePhone()
    local modelName = tostring(data.model or ''):lower():gsub('%s', '')
    if modelName == '' then return end
    local hash = GetHashKey(modelName)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 8000 do Wait(200); t = t + 200 end
    if not HasModelLoaded(hash) then
        notify('Model "' .. modelName .. '" not found.', 'error'); return
    end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local veh = CreateVehicle(hash, pos.x + fwd.x * 5, pos.y + fwd.y * 5, pos.z, GetEntityHeading(ped), true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetEntityAsNoLongerNeeded(veh)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleEngineOn(veh, true, true, false)
    notify('Spawned ' .. modelName .. ' (admin).', 'success')
end)

RegisterNUICallback('adminOpenTools', function(_, cb)
    cb({})
    closePhone()
    TriggerEvent('eonexis-admintools:openMenu')
end)

RegisterNUICallback('adminNoclip', function(_, cb)
    cb({})
    TriggerServerEvent('eonexis-admintools:noclip')
end)

RegisterNUICallback('adminGod', function(_, cb)
    cb({})
    TriggerServerEvent('eonexis-admintools:god')
end)

RegisterNUICallback('adminFreeze', function(_, cb)
    cb({})
    TriggerServerEvent('eonexis-admintools:freezeAll')
end)

RegisterNUICallback('adminTeleportHome', function(_, cb)
    cb({})
    closePhone()
    local ped = PlayerPedId()
    SetEntityCoords(ped, -269.3, -955.4, 31.2, false, false, false, true)
end)

-- Check admin status and show/hide admin app icon
RegisterNetEvent('eonexis-admintools:setAdminStatus')
AddEventHandler('eonexis-admintools:setAdminStatus', function(adminFlag)
    isAdmin = adminFlag
    SendNUIMessage({ action='setAdmin', isAdmin=adminFlag })
end)

-- Forward global UI scale changes to phone NUI
AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)

RegisterCommand('resetui', function()
    if phoneOpen then
        print('[eonexis-phone] /resetui: force-closing phone')
        closePhone()
    end
end, false)

