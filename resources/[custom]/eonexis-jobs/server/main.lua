-- eonexis-jobs — server

local playerTasks = {}  -- [src] = { stage, pay, job }

local function rnd(t) return t[math.random(#t)] end
local function pay(job) return math.random(job.pay.min, job.pay.max) end

local function notify(src, msg, t)
    TriggerClientEvent('eonexis-economy:notify', src, msg, t or 'info')
end

local function makeTask(src, jobId)
    local job = nil
    for _, j in ipairs(Config.Jobs) do if j.id == jobId then job = j; break end end
    if not job then return end

    local amount = pay(job)
    local task

    if jobId == 'taxi' then
        task = { stage='pickup', pos=rnd(Config.TaxiPickups),  label='Pick up customer',  pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='pickup',
            next={ stage='dropoff', pos=rnd(Config.TaxiDropoffs), label='Drop off customer' } }

    elseif jobId == 'delivery' then
        task = { stage='pickup', pos=rnd(Config.DeliveryPickups), label='Collect package', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='pickup',
            next={ stage='dropoff', pos=rnd(Config.DeliveryDropoffs), label='Deliver package' } }

    elseif jobId == 'mechanic' then
        task = { stage='repair', pos=rnd(Config.MechanicSpots), label='Repair vehicle', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='repair' }

    elseif jobId == 'trucker' then
        task = { stage='pickup', pos=rnd(Config.TruckerPickups), label='Load freight', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='pickup',
            next={ stage='dropoff', pos=rnd(Config.TruckerDropoffs), label='Deliver freight' } }

    elseif jobId == 'fisher' then
        task = { stage='fishing', pos=rnd(Config.FishingSpots), label='Fish here', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='fishing' }

    elseif jobId == 'guard' then
        task = { stage='work', pos=rnd(Config.GuardSpots), label='Guard post (2 min)', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='work' }
    end

    if task then
        TriggerClientEvent('eonexis-jobs:startTask', src, task)
    end
end

RegisterNetEvent('eonexis-jobs:selectJob')
AddEventHandler('eonexis-jobs:selectJob', function(jobId)
    local src = source
    exports['eonexis-economy']:setJob(src, jobId)
    playerTasks[src] = nil
    TriggerClientEvent('eonexis-jobs:setJob', src, jobId)
    notify(src, ('You are now a %s. Type /work to get a task.'):format(jobId), 'success')
    print(('[jobs] %s selected job: %s'):format(GetPlayerName(src), jobId))

    -- Spawn job vehicle if this job has one
    for _, j in ipairs(Config.Jobs) do
        if j.id == jobId and j.vehicle then
            TriggerClientEvent('eonexis-jobs:spawnWorkVehicle', src, j.vehicle)
            break
        end
    end
end)

RegisterNetEvent('eonexis-jobs:quitJob')
AddEventHandler('eonexis-jobs:quitJob', function()
    local src = source
    exports['eonexis-economy']:setJob(src, 'unemployed')
    playerTasks[src] = nil
    TriggerClientEvent('eonexis-jobs:setJob', src, 'unemployed')
    notify(src, 'You quit your job.', 'info')
end)

RegisterNetEvent('eonexis-jobs:requestTask')
AddEventHandler('eonexis-jobs:requestTask', function(jobId)
    local src = source
    local current = exports['eonexis-economy']:getJob(src)
    if current == 'unemployed' then notify(src, 'Get a job first!', 'error'); return end
    makeTask(src, current)
end)

RegisterNetEvent('eonexis-jobs:taskDone')
AddEventHandler('eonexis-jobs:taskDone', function(jobId)
    local src  = source
    local task = playerTasks[src]
    if not task then return end

    -- Multi-stage jobs: pickup → dropoff
    if task.stage == 'pickup' and task.next then
        -- Move to next stage
        playerTasks[src].stage = task.next.stage
        TriggerClientEvent('eonexis-jobs:startTask', src, {
            stage = task.next.stage,
            pos   = task.next.pos,
            label = task.next.label,
            pay   = task.pay,
        })
        if task.next.stage == 'dropoff' then
            notify(src, 'Package collected — now deliver it!', 'info')
        end
        return
    end

    -- Final stage: pay out
    local amount = task.pay
    exports['eonexis-economy']:addMoney(src, amount, 'job payout: ' .. (task.job or jobId))
    playerTasks[src] = nil
    TriggerClientEvent('eonexis-jobs:taskComplete', src, amount,
        ('Job done! Earned $%d.'):format(amount))
    print(('[jobs] %s completed %s task, paid $%d'):format(GetPlayerName(src), task.job or jobId, amount))
end)

AddEventHandler('playerDropped', function()
    playerTasks[source] = nil
end)
