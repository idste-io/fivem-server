-- eonexis-jobs — client

local currentJob  = 'unemployed'
local myLicenses  = {}     -- list of license IDs the player owns
local activeTask  = nil    -- { stage, pos, blip, label, pay }
local menuOpen    = false
local licMenuOpen = false  -- license purchase menu open
local fishing     = false
local guarding    = false
local guardTimer  = 0
local workVehicle = nil
local licOfficeBlips = {}  -- blip for each license office

-- ── Helpers ────────────────────────────────────────────────────────────────────

local function notify(msg, t)
    exports['eonexis-notify']:Notify('Job', msg, t or 'info', 5000)
end

local function hasLicense(licId)
    if not licId then return true end
    for _, l in ipairs(myLicenses) do
        if l == licId then return true end
    end
    return false
end

local function clearTask()
    if activeTask and activeTask.blip and DoesBlipExist(activeTask.blip) then
        RemoveBlip(activeTask.blip)
    end
    activeTask = nil
    ClearGpsPlayerWaypoint()
end

local function setTaskBlip(pos, label, colour)
    if activeTask and activeTask.blip and DoesBlipExist(activeTask.blip) then
        RemoveBlip(activeTask.blip)
    end
    local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(blip, 1); SetBlipColour(blip, colour or 3); SetBlipScale(blip, 0.9)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(label); EndTextCommandSetBlipName(blip)
    return blip
end

local function setWaypoint(pos)
    SetNewWaypoint(pos.x, pos.y)
end

-- ── Work vehicle ───────────────────────────────────────────────────────────────

local function deleteWorkVehicle()
    if workVehicle and DoesEntityExist(workVehicle) then
        DeleteVehicle(workVehicle)
    end
    workVehicle = nil
end

RegisterNetEvent('eonexis-jobs:spawnWorkVehicle')
AddEventHandler('eonexis-jobs:spawnWorkVehicle', function(model)
    deleteWorkVehicle()
    local hash = GetHashKey(model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) do Wait(200); t = t + 200; if t > 10000 then return end end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    workVehicle = CreateVehicle(hash, pos.x + fwd.x * 5, pos.y + fwd.y * 5, pos.z, GetEntityHeading(ped), true, false)
    SetEntityAsMissionEntity(workVehicle, true, true)
    SetVehicleEngineOn(workVehicle, true, true, false)
    TaskWarpPedIntoVehicle(ped, workVehicle, -1)
    SetModelAsNoLongerNeeded(hash)
    notify('Work vehicle spawned — hop in!', 'success')
end)

-- ── Job events from server ─────────────────────────────────────────────────────

RegisterNetEvent('eonexis-jobs:setJob')
AddEventHandler('eonexis-jobs:setJob', function(jobId)
    currentJob = jobId
    clearTask()
    deleteWorkVehicle()
end)

RegisterNetEvent('eonexis-jobs:setLicenses')
AddEventHandler('eonexis-jobs:setLicenses', function(owned)
    myLicenses = owned or {}
    SendNUIMessage({ action='setLicenses', licenses=myLicenses })
end)

RegisterNetEvent('eonexis-jobs:licenseGranted')
AddEventHandler('eonexis-jobs:licenseGranted', function(licId)
    local already = false
    for _, l in ipairs(myLicenses) do if l == licId then already = true; break end end
    if not already then table.insert(myLicenses, licId) end
    SendNUIMessage({ action='setLicenses', licenses=myLicenses })
end)

RegisterNetEvent('eonexis-jobs:needLicense')
AddEventHandler('eonexis-jobs:needLicense', function(licId, pos)
    -- Find the license def to tell player where to go
    for _, l in ipairs(Config.Licenses) do
        if l.id == licId then
            notify(('You need a %s. Setting waypoint to %s.'):format(l.label, l.blipLabel), 'warning')
            setWaypoint(vector3(pos.x, pos.y, pos.z))
            return
        end
    end
end)

RegisterNetEvent('eonexis-jobs:startTask')
AddEventHandler('eonexis-jobs:startTask', function(task)
    clearTask()
    local pos = vector3(task.pos.x, task.pos.y, task.pos.z)
    local colour = (task.stage == 'pickup' and 3) or (task.stage == 'dropoff' and 1) or 5
    activeTask = {
        stage = task.stage,
        pos   = pos,
        label = task.label,
        pay   = task.pay,
        blip  = setTaskBlip(pos, task.label, colour),
    }
    notify(task.label .. ' — follow the GPS.', 'info')
    setWaypoint(pos)
end)

RegisterNetEvent('eonexis-jobs:taskComplete')
AddEventHandler('eonexis-jobs:taskComplete', function(amount, msg)
    clearTask()
    fishing = false; guarding = false
    notify(msg or ('Task done! Earned $' .. amount), 'success')
end)

-- ── NUI callbacks ─────────────────────────────────────────────────────────────

RegisterNUICallback('selectJob', function(data, cb)
    cb({})
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hide' })
    TriggerServerEvent('eonexis-jobs:selectJob', data.id)
end)

RegisterNUICallback('quitJob', function(_, cb)
    cb({})
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hide' })
    TriggerServerEvent('eonexis-jobs:quitJob')
end)

RegisterNUICallback('startShift', function(_, cb)
    cb({})
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hide' })
    TriggerServerEvent('eonexis-jobs:requestTask')
end)

RegisterNUICallback('buyLicense', function(data, cb)
    cb({})
    licMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hideLicMenu' })
    TriggerServerEvent('eonexis-jobs:buyLicense', data.id)
end)

RegisterNUICallback('closeLic', function(_, cb)
    cb({})
    licMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hideLicMenu' })
end)

RegisterNUICallback('close', function(_, cb)
    cb({})
    menuOpen = false
    licMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hide' })
    SendNUIMessage({ action='hideLicMenu' })
end)

local function Draw3DLabel(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    local camPos = GetGameplayCamCoords()
    local dist   = #(camPos - vector3(x, y, z))
    local scale  = math.min(1 / dist * 3.0, 0.42)
    SetTextScale(0.0, scale)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 240)
    SetTextDropShadow()
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(sx, sy)
end

-- ── Open job center ────────────────────────────────────────────────────────────

local function openJobCenter()
    if menuOpen or licMenuOpen then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'show',
        jobs     = Config.Jobs,
        current  = currentJob,
        licenses = myLicenses,
    })
end

local function openLicMenu(lic)
    if menuOpen or licMenuOpen then return end
    licMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'showLicMenu',
        license = lic,
        owned   = hasLicense(lic.id),
    })
end

-- ── License office blips ───────────────────────────────────────────────────────

CreateThread(function()
    for _, lic in ipairs(Config.Licenses) do
        local blip = AddBlipForCoord(lic.pos.x, lic.pos.y, lic.pos.z)
        SetBlipSprite(blip, lic.blipSprite or 57)
        SetBlipColour(blip, lic.blipColour or 5)
        SetBlipScale(blip, 0.75)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(lic.blipLabel)
        EndTextCommandSetBlipName(blip)
        table.insert(licOfficeBlips, blip)
    end
end)

-- ── Main interaction thread ───────────────────────────────────────────────────

CreateThread(function()
    -- Job center blip
    local jcBlip = AddBlipForCoord(Config.JobCenterPos.x, Config.JobCenterPos.y, Config.JobCenterPos.z)
    SetBlipSprite(jcBlip, 436); SetBlipColour(jcBlip, 5); SetBlipScale(jcBlip, 0.9)
    SetBlipAsShortRange(jcBlip, false)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Job Center'); EndTextCommandSetBlipName(jcBlip)

    -- Request licenses on spawn
    TriggerServerEvent('eonexis-jobs:requestLicenses')

    while true do
        Wait(0)
        local ped   = PlayerPedId()
        local myPos = GetEntityCoords(ped)

        -- ── Job center ──────────────────────────────────────────────────────────
        local jcDist = #(myPos - Config.JobCenterPos)
        if jcDist < 100.0 then
            DrawMarker(1, Config.JobCenterPos.x, Config.JobCenterPos.y, Config.JobCenterPos.z - 0.5,
                0,0,0, 0,0,0, 2.2,2.2,0.5, 255,200,0,140, false, true, 2, false, nil, nil, false)
        end
        if jcDist < 40.0 and jcDist > 2.5 then
            Draw3DLabel(Config.JobCenterPos.x, Config.JobCenterPos.y, Config.JobCenterPos.z + 1.5, '💼 Job Center')
        end
        if jcDist < 2.5 then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Job Center')
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustPressed(0, 38) and not menuOpen and not licMenuOpen then
                openJobCenter()
            end
        end

        -- ── License offices ─────────────────────────────────────────────────────
        for _, lic in ipairs(Config.Licenses) do
            local lPos  = lic.pos
            local lDist = #(myPos - lPos)
            if lDist < 100.0 then
                DrawMarker(1, lPos.x, lPos.y, lPos.z - 0.5,
                    0,0,0, 0,0,0, 2.0,2.0,0.5, 80,160,255,120, false, true, 2, false, nil, nil, false)
            end
            if lDist < 40.0 and lDist > 2.5 then
                local owned = hasLicense(lic.id)
                Draw3DLabel(lPos.x, lPos.y, lPos.z + 1.5,
                    (owned and '✅ ' or '📋 ') .. lic.label)
            end
            if lDist < 2.5 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(
                    hasLicense(lic.id) and ('✅ ' .. lic.label .. ' — Owned')
                                       or ('~INPUT_CONTEXT~ Buy ' .. lic.label .. ' ($' .. lic.cost .. ')'))
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustPressed(0, 38) and not menuOpen and not licMenuOpen then
                    openLicMenu(lic)
                end
            end
        end

        -- ── Active task ──────────────────────────────────────────────────────────
        if activeTask then
            local tDist = #(myPos - activeTask.pos)
            local r, g, b = 80, 200, 80
            if activeTask.stage == 'pickup' then r,g,b = 255,165,0 end
            DrawMarker(1, activeTask.pos.x, activeTask.pos.y, activeTask.pos.z - 0.5,
                0,0,0, 0,0,0, 2.5,2.5,0.7, r,g,b,140, false, true, 2, false, nil, nil, false)

            if tDist < 3.0 then
                local stage = activeTask.stage

                if stage == 'fishing' and not fishing then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Start fishing')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) then
                        fishing = true
                        notify('Fishing… wait for a bite!', 'info')
                        local waitTime = Config.FishTime + math.random(0, 10000)
                        SetTimeout(waitTime, function()
                            if fishing then
                                TriggerServerEvent('eonexis-jobs:taskDone')
                                fishing = false
                            end
                        end)
                    end

                elseif stage == 'work' and not guarding then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Start guard shift (2 min)')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) then
                        guarding = true
                        guardTimer = GetGameTimer()
                        notify('On duty! Stay at post for 2 minutes.', 'info')
                    end

                elseif stage == 'repair' then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Repair vehicle')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) then
                        notify('Repairing…', 'info')
                        SetTimeout(8000, function()
                            TriggerServerEvent('eonexis-jobs:taskDone')
                        end)
                    end

                elseif stage == 'bartend' then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Serve drinks')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) then
                        notify('Serving drinks…', 'info')
                        RequestAnimDict('mp_player_int_drinkingwater')
                        while not HasAnimDictLoaded('mp_player_int_drinkingwater') do Wait(100) end
                        TaskPlayAnim(ped, 'mp_player_int_drinkingwater', 'mp_player_int_wimpy_drinkingwater', 8.0, -8.0, Config.BartendTime, 1, 0, false, false, false)
                        SetTimeout(Config.BartendTime, function()
                            ClearPedTasks(PlayerPedId())
                            TriggerServerEvent('eonexis-jobs:taskDone')
                        end)
                    end

                elseif stage == 'cook' then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Prepare meal')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) then
                        notify('Preparing meal…', 'info')
                        RequestAnimDict('mp_player_int_eatdrink')
                        while not HasAnimDictLoaded('mp_player_int_eatdrink') do Wait(100) end
                        TaskPlayAnim(ped, 'mp_player_int_eatdrink', 'mp_player_int_wimpy_eat_fork', 8.0, -8.0, Config.ChefTime, 1, 0, false, false, false)
                        SetTimeout(Config.ChefTime, function()
                            ClearPedTasks(PlayerPedId())
                            TriggerServerEvent('eonexis-jobs:taskDone')
                        end)
                    end

                elseif stage == 'pickup' or stage == 'dropoff' then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ ' .. activeTask.label)
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('eonexis-jobs:taskDone')
                    end
                end
            end

            -- Guard timer
            if guarding then
                local elapsed = GetGameTimer() - guardTimer
                if elapsed >= Config.GuardTime then
                    guarding = false
                    TriggerServerEvent('eonexis-jobs:taskDone')
                end
            end
        end
    end
end)

-- ── /work command ──────────────────────────────────────────────────────────────

RegisterCommand('work', function()
    if currentJob == 'unemployed' then
        notify('Visit the Job Center to get a job first.', 'error'); return
    end
    TriggerServerEvent('eonexis-jobs:requestTask')
end, false)

TriggerEvent('chat:addSuggestion', '/work', 'Get your next job task', {})

-- ── Client exports for eonexis-phone ─────────────────────────────────────────

exports('getJobDefs', function()
    -- Return serialisable copy (no vectors) for phone NUI
    local defs = {}
    for _, j in ipairs(Config.Jobs) do
        table.insert(defs, {
            id      = j.id,
            label   = j.label,
            icon    = j.icon,
            desc    = j.desc,
            pay     = j.pay,
            license = j.license,
        })
    end
    return defs
end)

exports('getLicenseDefs', function()
    local defs = {}
    for _, l in ipairs(Config.Licenses) do
        table.insert(defs, {
            id    = l.id,
            label = l.label,
            cost  = l.cost,
            desc  = l.desc,
        })
    end
    return defs
end)

exports('getJobCenterPos', function()
    return { x=Config.JobCenterPos.x, y=Config.JobCenterPos.y, z=Config.JobCenterPos.z }
end)

exports('getLicensePos', function(licId)
    for _, l in ipairs(Config.Licenses) do
        if l.id == licId then return { x=l.pos.x, y=l.pos.y, z=l.pos.z } end
    end
    return nil
end)

AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)
