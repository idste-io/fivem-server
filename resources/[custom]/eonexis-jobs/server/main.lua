-- eonexis-jobs — server

local playerTasks = {}

local licenseFile = 'data/licenses.json'
local licenseData = {}

-- ── License persistence ────────────────────────────────────────────────────────

local function loadLicenses()
    local raw = LoadResourceFile(GetCurrentResourceName(), licenseFile)
    if raw and raw ~= '' then
        licenseData = json.decode(raw) or {}
    end
end

local function saveLicenses()
    SaveResourceFile(GetCurrentResourceName(), licenseFile, json.encode(licenseData), -1)
end

local function getPlayerId(src)
    return GetPlayerIdentifierByType(src, 'license') or
           GetPlayerIdentifierByType(src, 'steam')  or
           tostring(src)
end

local function hasLicense(src, licId)
    if not licId then return true end
    local owned = licenseData[getPlayerId(src)] or {}
    for _, l in ipairs(owned) do
        if l == licId then return true end
    end
    return false
end

local function grantLicense(src, licId)
    local pid = getPlayerId(src)
    licenseData[pid] = licenseData[pid] or {}
    for _, l in ipairs(licenseData[pid]) do
        if l == licId then return true end
    end
    table.insert(licenseData[pid], licId)
    saveLicenses()
    return true
end

-- ── Helpers ────────────────────────────────────────────────────────────────────

local function rnd(t) return t[math.random(#t)] end

local function pay(job) return math.random(job.pay.min, job.pay.max) end

local function notify(src, msg, t)
    TriggerClientEvent('eonexis-economy:notify', src, msg, t or 'info')
end

local function getLicenseDef(licId)
    for _, l in ipairs(Config.Licenses) do
        if l.id == licId then return l end
    end
end

local function getJobDef(jobId)
    for _, j in ipairs(Config.Jobs) do
        if j.id == jobId then return j end
    end
end

-- ── License events ─────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-jobs:buyLicense')
AddEventHandler('eonexis-jobs:buyLicense', function(licId)
    local src = source
    local lic = getLicenseDef(licId)
    if not lic then return end

    if hasLicense(src, licId) then
        notify(src, 'You already own this license.', 'info'); return
    end

    local cash = exports['eonexis-economy']:getMoney(src)
    if cash < lic.cost then
        notify(src, ('Not enough cash! Need $%d.'):format(lic.cost), 'error'); return
    end

    exports['eonexis-economy']:removeMoney(src, lic.cost, 'license purchase: ' .. licId)
    grantLicense(src, licId)
    notify(src, ('✅ %s purchased for $%d!'):format(lic.label, lic.cost), 'success')
    TriggerClientEvent('eonexis-jobs:licenseGranted', src, licId)
    TriggerEvent('eonexis-jobs:onLicensePurchased', src, licId)   -- server-side hook for other mods
    print(('[jobs] %s bought license: %s'):format(GetPlayerName(src), licId))
end)

RegisterNetEvent('eonexis-jobs:requestLicenses')
AddEventHandler('eonexis-jobs:requestLicenses', function()
    local src = source
    local owned = licenseData[getPlayerId(src)] or {}
    TriggerClientEvent('eonexis-jobs:setLicenses', src, owned)
end)

-- ── Job selection ─────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-jobs:selectJob')
AddEventHandler('eonexis-jobs:selectJob', function(jobId)
    local src = source
    local job = getJobDef(jobId)
    if not job then return end

    -- License check
    if job.license and not hasLicense(src, job.license) then
        local lic = getLicenseDef(job.license)
        local label = lic and lic.label or job.license
        notify(src, ('❌ You need a %s first.'):format(label), 'error')
        -- Tell client to waypoint to the license office
        if lic then
            TriggerClientEvent('eonexis-jobs:needLicense', src, job.license, lic.pos)
        end
        return
    end

    exports['eonexis-economy']:setJob(src, jobId)
    playerTasks[src] = nil
    TriggerClientEvent('eonexis-jobs:setJob', src, jobId)
    notify(src, ('✅ You are now a %s. Use /work to get a task.'):format(job.label), 'success')
    print(('[jobs] %s selected job: %s'):format(GetPlayerName(src), jobId))

    if job.vehicle then
        TriggerClientEvent('eonexis-jobs:spawnWorkVehicle', src, job.vehicle)
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

-- ── Task assignment ────────────────────────────────────────────────────────────

local function makeTask(src, jobId)
    local job = getJobDef(jobId)
    if not job then return end

    local amount = pay(job)
    local task

    if jobId == 'taxi' then
        task = { stage='pickup', pos=rnd(Config.TaxiPickups), label='Pick up customer', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='pickup',
            next={ stage='dropoff', pos=rnd(Config.TaxiDropoffs), label='Drop off customer' } }

    elseif jobId == 'delivery' then
        task = { stage='pickup', pos=rnd(Config.DeliveryPickups), label='Collect package', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='pickup',
            next={ stage='dropoff', pos=rnd(Config.DeliveryDropoffs), label='Deliver package' } }

    elseif jobId == 'courier' then
        task = { stage='pickup', pos=rnd(Config.CourierPickups), label='Collect parcel', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='pickup',
            next={ stage='dropoff', pos=rnd(Config.CourierDropoffs), label='Deliver parcel' } }

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

    elseif jobId == 'bartender' then
        task = { stage='bartend', pos=rnd(Config.BartenderSpots), label='Serve customers', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='bartend' }

    elseif jobId == 'chef' then
        task = { stage='cook', pos=rnd(Config.ChefSpots), label='Prepare meals', pay=amount }
        playerTasks[src] = { job=jobId, pay=amount, stage='cook' }
    end

    if task then
        TriggerClientEvent('eonexis-jobs:startTask', src, task)
    end
end

RegisterNetEvent('eonexis-jobs:requestTask')
AddEventHandler('eonexis-jobs:requestTask', function()
    local src = source
    local current = exports['eonexis-economy']:getJob(src)
    if current == 'unemployed' then
        notify(src, 'Get a job first! Visit the Job Center.', 'error'); return
    end
    if playerTasks[src] then
        notify(src, 'Finish your current task first!', 'warning'); return
    end
    makeTask(src, current)
end)

RegisterNetEvent('eonexis-jobs:taskDone')
AddEventHandler('eonexis-jobs:taskDone', function()
    local src  = source
    local task = playerTasks[src]
    if not task then return end

    -- Multi-stage: advance to next stage
    if task.stage == 'pickup' and task.next then
        playerTasks[src].stage = task.next.stage
        TriggerClientEvent('eonexis-jobs:startTask', src, {
            stage = task.next.stage,
            pos   = task.next.pos,
            label = task.next.label,
            pay   = task.pay,
        })
        notify(src, 'Collected! Now make the delivery.', 'info')
        return
    end

    -- Payout
    local amount = task.pay
    exports['eonexis-economy']:addMoney(src, amount, 'job: ' .. task.job)
    playerTasks[src] = nil
    TriggerClientEvent('eonexis-jobs:taskComplete', src, amount,
        ('Task done! Earned $%d.'):format(amount))
    print(('[jobs] %s finished %s, paid $%d'):format(GetPlayerName(src), task.job, amount))
    TriggerEvent('eonexis-quests:objectiveDone', src, 'job_task_done')
    TriggerEvent('eonexis-skilltree:taskDone', src)
end)

-- Export: check if player has license (used by other mods)
exports('hasLicense', function(src, licId)
    return hasLicense(src, licId)
end)

AddEventHandler('playerDropped', function()
    playerTasks[source] = nil
end)

loadLicenses()
print('[eonexis-jobs] loaded — ' .. #Config.Jobs .. ' jobs, ' .. #Config.Licenses .. ' license types')
