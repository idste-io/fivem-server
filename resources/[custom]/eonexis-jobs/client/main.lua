-- eonexis-jobs — client

local currentJob   = 'unemployed'
local activeTask   = nil   -- { stage='pickup'|'dropoff'|'work', pos, blip, label }
local menuOpen     = false
local fishing      = false
local guarding     = false
local guardTimer   = 0
local workVehicle  = nil   -- current spawned job vehicle entity

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Job', msg, t or 'info', 5000)
    end
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
    SetBlipSprite(blip, 1); SetBlipColour(blip, colour or 3)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(label); EndTextCommandSetBlipName(blip)
    return blip
end

-- Spawn / delete work vehicle
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
    while not HasModelLoaded(hash) do
        Wait(100)
        t = t + 100
        if t > 10000 then
            notify('Could not load job vehicle model.', 'error')
            return
        end
    end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local hdg = GetEntityHeading(ped)
    -- Spawn 4m in front of player
    local fwd = GetEntityForwardVector(ped)
    workVehicle = CreateVehicle(hash, pos.x + fwd.x * 4, pos.y + fwd.y * 4, pos.z, hdg, true, false)
    SetEntityAsMissionEntity(workVehicle, true, true)
    SetVehicleEngineOn(workVehicle, true, true, false)
    TaskWarpPedIntoVehicle(ped, workVehicle, -1)
    SetModelAsNoLongerNeeded(hash)
    notify('Your work vehicle is ready!', 'success')
end)

RegisterNetEvent('eonexis-jobs:deleteWorkVehicle')
AddEventHandler('eonexis-jobs:deleteWorkVehicle', function()
    deleteWorkVehicle()
end)

-- Receive job assignment from server
RegisterNetEvent('eonexis-jobs:setJob')
AddEventHandler('eonexis-jobs:setJob', function(jobId)
    currentJob = jobId
    clearTask()
    deleteWorkVehicle()
end)

RegisterNetEvent('eonexis-jobs:startTask')
AddEventHandler('eonexis-jobs:startTask', function(task)
    -- task: { stage, pos={x,y,z}, label, pay }
    clearTask()
    local pos = vector3(task.pos.x, task.pos.y, task.pos.z)
    activeTask = {
        stage = task.stage,
        pos   = pos,
        label = task.label,
        pay   = task.pay,
        blip  = setTaskBlip(pos, task.label, task.stage == 'pickup' and 3 or 1),
        data  = task.data,
    }
    notify(task.label, 'info')
end)

RegisterNetEvent('eonexis-jobs:taskComplete')
AddEventHandler('eonexis-jobs:taskComplete', function(pay, msg)
    clearTask()
    fishing = false; guarding = false
    notify(msg or ('Task complete! Earned $' .. pay), 'success')
end)

-- Job center NUI
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
    TriggerServerEvent('eonexis-jobs:requestTask', currentJob)
end)

RegisterNUICallback('close', function(_, cb)
    cb({})
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='hide' })
end)

-- Open job center menu
local function openJobCenter()
    if menuOpen then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action  = 'show',
        jobs    = Config.Jobs,
        current = currentJob,
    })
end

-- Proximity + task detection thread
CreateThread(function()
    -- Job center blip
    local blip = AddBlipForCoord(Config.JobCenterPos.x, Config.JobCenterPos.y, Config.JobCenterPos.z)
    SetBlipSprite(blip, 436); SetBlipScale(blip, 0.85); SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Job Center'); EndTextCommandSetBlipName(blip)

    while true do
        Wait(0)
        local ped   = PlayerPedId()
        local myPos = GetEntityCoords(ped)

        -- Job center interaction
        local jcDist = #(myPos - Config.JobCenterPos)
        DrawMarker(1, Config.JobCenterPos.x, Config.JobCenterPos.y, Config.JobCenterPos.z - 0.5,
            0,0,0, 0,0,0, 2.0,2.0,0.5, 255,200,0, 120, false, true, 2, false, nil, nil, false)
        if jcDist < 2.5 then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Job Center')
            EndTextCommandDisplayHelp(0, false, true, -1)
            if (IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176)) and not menuOpen then
                openJobCenter()
            end
        end

        -- Active task interaction
        if activeTask then
            local tDist = #(myPos - activeTask.pos)
            DrawMarker(1, activeTask.pos.x, activeTask.pos.y, activeTask.pos.z - 0.5,
                0,0,0, 0,0,0, 2.5,2.5,0.7,
                activeTask.stage == 'pickup' and 255 or 80,
                activeTask.stage == 'pickup' and 165 or 200,
                80, 140, false, true, 2, false, nil, nil, false)

            if tDist < 3.0 then
                if activeTask.stage == 'fishing' and not fishing then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Fish here')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176) then
                        fishing = true
                        notify('Fishing... wait for a bite.', 'info')
                        SetTimeout(Config.FishTime + math.random(0, 10000), function()
                            if fishing then
                                TriggerServerEvent('eonexis-jobs:taskDone', currentJob)
                                fishing = false
                            end
                        end)
                    end
                elseif activeTask.stage == 'work' and not guarding then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Start working')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176) then
                        guarding = true
                        guardTimer = GetGameTimer()
                        notify('Working... stay at post for 2 minutes.', 'info')
                    end
                elseif activeTask.stage == 'pickup' or activeTask.stage == 'dropoff' then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ ' .. activeTask.label)
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176) then
                        TriggerServerEvent('eonexis-jobs:taskDone', currentJob)
                    end
                elseif activeTask.stage == 'repair' then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Repair vehicle')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 176) then
                        notify('Repairing...', 'info')
                        SetTimeout(8000, function()
                            TriggerServerEvent('eonexis-jobs:taskDone', currentJob)
                        end)
                    end
                end
            end

            -- Guard post timer
            if guarding then
                local elapsed = GetGameTimer() - guardTimer
                if elapsed >= 120000 then
                    guarding = false
                    TriggerServerEvent('eonexis-jobs:taskDone', currentJob)
                end
            end
        end
    end
end)

-- /work command — get next task
RegisterCommand('work', function()
    if currentJob == 'unemployed' then
        notify('You need a job first. Visit the Job Center.', 'error')
        return
    end
    TriggerServerEvent('eonexis-jobs:requestTask', currentJob)
end, false)

TriggerEvent('chat:addSuggestion', '/work', 'Get your next job task', {})
