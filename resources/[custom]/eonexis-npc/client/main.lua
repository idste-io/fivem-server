local spawnedNPCs   = {}
local playerJobMap  = {}
local policeNPCs    = {}
local hasRealPolice = false

local function deleteNPCList(list)
    for _, e in ipairs(list) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
end

local function loadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) do
        Wait(200)
        t = t + 200
        if t > 8000 then return nil end
    end
    return hash
end

local function spawnWanderingNPC(model, x, y, z, radius)
    local hash = loadModel(model)
    if not hash then return nil end
    local ped = CreatePed(4, hash, x + math.random(-radius, radius),
        y + math.random(-radius, radius), z, math.random(360), false, true)
    if not DoesEntityExist(ped) then return nil end
    SetBlockingOfNonTemporaryEvents(ped, false)
    TaskWanderInArea(ped, x, y, z, radius, 1.0, 0)
    SetPedRelationshipGroupHash(ped, GetHashKey('CIVMALE'))
    return ped
end

local function spawnStandingNPC(model, x, y, z, heading)
    local hash = loadModel(model)
    if not hash then return nil end
    local ped = CreatePed(4, hash, x, y, z, heading, false, true)
    if not DoesEntityExist(ped) then return nil end
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStandStill(ped, -1)
    return ped
end

-- ── Police NPCs ───────────────────────────────────────────────────────────────

local function spawnPolicePedAt(wp)
    local hash = loadModel('s_m_y_cop_01')
    if not hash then return end
    local ped = CreatePed(4, hash, wp.x, wp.y, wp.z, wp.h, false, true)
    if not DoesEntityExist(ped) then return end
    SetPedAsGroupMember(ped, 0)
    SetBlockingOfNonTemporaryEvents(ped, false)
    TaskWanderInArea(ped, wp.x, wp.y, wp.z, 40.0, 1.0, 0)
    GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 100, false, true)
    table.insert(policeNPCs, ped)

    -- Spawn police vehicle
    local vHash = GetHashKey('police')
    RequestModel(vHash)
    local vt = 0
    while not HasModelLoaded(vHash) do Wait(200); vt = vt + 200; if vt > 5000 then break end end
    if HasModelLoaded(vHash) then
        local veh = CreateVehicle(vHash, wp.x + 5, wp.y + 5, wp.z, wp.h, false, true)
        if DoesEntityExist(veh) then
            table.insert(policeNPCs, veh)
        end
    end
end

local function refreshPoliceNPCs(realCopOnline)
    hasRealPolice = realCopOnline
    if realCopOnline then
        deleteNPCList(policeNPCs)
        policeNPCs = {}
        return
    end
    -- Already enough NPCs?
    local alive = 0
    for _, e in ipairs(policeNPCs) do
        if DoesEntityExist(e) then alive = alive + 1 end
    end
    if alive >= Config.MinPoliceNPCs then return end
    -- Clean dead references
    local keep = {}
    for _, e in ipairs(policeNPCs) do if DoesEntityExist(e) then keep[#keep+1] = e end end
    policeNPCs = keep
    -- Spawn missing
    local needed = Config.MinPoliceNPCs - #policeNPCs
    for i = 1, needed do
        local wp = Config.PolicePatrols[((i - 1) % #Config.PolicePatrols) + 1]
        spawnPolicePedAt(wp)
        Wait(200)
    end
end

-- ── Job NPCs ──────────────────────────────────────────────────────────────────

local function refreshJobNPCs()
    deleteNPCList(spawnedNPCs)
    spawnedNPCs = {}

    local jobCounts = {}
    for _, job in pairs(playerJobMap) do
        jobCounts[job] = (jobCounts[job] or 0) + 1
    end

    for job, cfg in pairs(Config.JobNPCs) do
        if not jobCounts[job] or jobCounts[job] == 0 then
            -- No real player on this job — spawn an NPC
            local cx = Config.JobCenterPos.x
            local cy = Config.JobCenterPos.y
            local cz = Config.JobCenterPos.z
            local ped
            if cfg.action == 'stand' then
                ped = spawnStandingNPC(cfg.model, cx + math.random(-5,5), cy + math.random(-5,5), cz, 0.0)
            else
                ped = spawnWanderingNPC(cfg.model, cx, cy, cz, cfg.radius)
            end
            if ped then table.insert(spawnedNPCs, ped) end
        end
    end
end

-- ── Events ────────────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-npc:refreshNPCs')
AddEventHandler('eonexis-npc:refreshNPCs', function(jobMap)
    playerJobMap = jobMap or {}
    -- Check police presence
    local realCop = false
    for _, job in pairs(playerJobMap) do
        if job == 'police' then realCop = true; break end
    end
    refreshPoliceNPCs(realCop)
    refreshJobNPCs()
end)

-- ── Init ──────────────────────────────────────────────────────────────────────

AddEventHandler('onClientResourceStart', function(res)
    if res == GetCurrentResourceName() then
        Wait(3000)
        TriggerServerEvent('eonexis-npc:requestState')
    end
end)

-- Periodic refresh every 5 min
CreateThread(function()
    while true do
        Wait(300000)
        TriggerServerEvent('eonexis-npc:requestState')
        -- Clean up dead NPCs from lists
        local aliveJob = {}
        for _, e in ipairs(spawnedNPCs) do if DoesEntityExist(e) then aliveJob[#aliveJob+1] = e end end
        spawnedNPCs = aliveJob
        local alivePol = {}
        for _, e in ipairs(policeNPCs) do if DoesEntityExist(e) then alivePol[#alivePol+1] = e end end
        policeNPCs = alivePol
    end
end)
