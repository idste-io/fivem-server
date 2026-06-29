local myPoints   = 0       -- 0–50
local lastSeen   = 0       -- game timer when police last had LoS
local decaying   = false
local inSight    = false

-- NPC spawn tracking
local spawnedNPCs = {}

-- Weapon hash lookup for giving items
local WEAPON_HASHES = {
    pistol        = GetHashKey('WEAPON_PISTOL'),
    smg           = GetHashKey('WEAPON_SMG'),
    carbine_rifle = GetHashKey('WEAPON_CARBINERIFLE'),
    assault_rifle = GetHashKey('WEAPON_ASSAULTRIFLE'),
    shotgun       = GetHashKey('WEAPON_PUMPSHOTGUN'),
    sniper_rifle  = GetHashKey('WEAPON_SNIPERRIFLE'),
    rpg           = GetHashKey('WEAPON_RPG'),
    minigun       = GetHashKey('WEAPON_MINIGUN'),
}

local COP_MODELS = {}
for _, m in ipairs(Config.CopModels) do
    COP_MODELS[GetHashKey(m)] = true
end

-- ── Stars HUD ─────────────────────────────────────────────────────────────────

local function drawStarsHUD(stars)
    if stars <= 0 then return end
    local fullStars = math.floor(stars)
    local half      = (stars - fullStars) >= 0.5

    local x = 0.96
    local y = 0.04
    local sz = 0.025

    for i = 1, 5 do
        local col = i <= fullStars and { 255, 220, 0, 255 }
                 or (i == fullStars + 1 and half and { 255, 220, 0, 160 })
                 or { 80, 80, 80, 180 }
        if col then
            DrawRect(x - (i - 1) * 0.028, y, sz, sz * 1.77, col[1], col[2], col[3], col[4])
        end
    end

    -- text label
    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 220, 0, 255)
    SetTextEntry('STRING')
    AddTextComponentString(string.format('WANTED %.1f★', stars))
    DrawText(x - 4 * 0.028 - 0.01, y - 0.014)
end

-- ── NPC Spawning ──────────────────────────────────────────────────────────────

local RESPONSE = Config.Response

local function clearNPCs()
    for _, e in ipairs(spawnedNPCs) do
        if DoesEntityExist(e) then
            DeleteEntity(e)
        end
    end
    spawnedNPCs = {}
end

local function spawnCopNPC(model, x, y, z, heading, weapon, aggressive)
    RequestModel(GetHashKey(model))
    local t = 0
    while not HasModelLoaded(GetHashKey(model)) do
        Wait(100)
        t = t + 100
        if t > 5000 then return nil end
    end
    local ped = CreatePed(4, GetHashKey(model), x, y, z, heading, true, true)
    if not DoesEntityExist(ped) then return nil end
    SetPedAsEnemy(ped, true)
    SetPedCombatAbility(ped, 100)
    SetPedCombatMovement(ped, 2)
    SetPedCombatRange(ped, 2)
    SetEntityInvincible(ped, false)
    SetPedFleeAttributes(ped, 0, true)
    SetPedCanRagdoll(ped, true)
    if weapon then
        GiveWeaponToPed(ped, GetHashKey(weapon), 999, false, true)
    end
    if aggressive then
        TaskCombatPed(ped, PlayerPedId(), 0, 16)
    end
    table.insert(spawnedNPCs, ped)
    return ped
end

local function spawnResponseForStars(stars)
    clearNPCs()
    if stars <= 0 then return end

    local level = math.floor(stars)
    if level < 1 then return end
    local resp  = RESPONSE[math.min(level, 5)]
    if not resp then return end

    local playerPed = PlayerPedId()
    local px, py, pz = table.unpack(GetEntityCoords(playerPed))

    -- Spawn cop cars + peds behind player
    for i = 1, resp.cops do
        local angle  = math.rad((i / resp.cops) * 360)
        local dist   = 40 + i * 5
        local cx, cy = px + math.cos(angle) * dist, py + math.sin(angle) * dist
        local cz     = GetGroundZFor_3dCoord(cx, cy, pz + 5.0, false)

        local pedModel = resp.military and 's_m_y_marine_01' or
                         (resp.swat    and 's_m_y_swat_01'  or
                         (resp.fib     and 'u_m_y_fibsec_01' or 's_m_y_cop_01'))

        local weapon   = resp.military and 'WEAPON_ASSAULTRIFLE' or
                         (resp.swat    and 'WEAPON_CARBINERIFLE' or 'WEAPON_PISTOL')

        spawnCopNPC(pedModel, cx, cy, cz, 0.0, weapon, true)

        -- Spawn vehicle
        local vehModel = resp.military and 'crusader' or
                         (resp.swat    and 'riot'      or 'police')
        RequestModel(GetHashKey(vehModel))
        local vt = 0
        while not HasModelLoaded(GetHashKey(vehModel)) do Wait(100); vt = vt + 100; if vt > 5000 then break end end
        if HasModelLoaded(GetHashKey(vehModel)) then
            local veh = CreateVehicle(GetHashKey(vehModel), cx, cy, cz, 0.0, true, false)
            if DoesEntityExist(veh) then
                table.insert(spawnedNPCs, veh)
                SetVehicleSiren(veh, true)
            end
        end
    end

    -- Helicopter
    if resp.helicopter then
        local heliModel = resp.military and 'annihilator' or 'polmav'
        RequestModel(GetHashKey(heliModel))
        local ht = 0
        while not HasModelLoaded(GetHashKey(heliModel)) do Wait(100); ht = ht + 100; if ht > 5000 then break end end
        if HasModelLoaded(GetHashKey(heliModel)) then
            local heli = CreateVehicle(GetHashKey(heliModel), px + 20, py + 20, pz + 60, 0.0, true, false)
            if DoesEntityExist(heli) then
                table.insert(spawnedNPCs, heli)
                SetVehicleEngineOn(heli, true, true, false)
                -- Pilot
                local pilot = CreatePedInsideVehicle(heli, 4, GetHashKey('s_m_y_cop_01'), -1, true, true)
                table.insert(spawnedNPCs, pilot)
                TaskHeliChase(heli, playerPed, 0, 0, 0)
                -- Gunner (SWAT+)
                if resp.swat then
                    local gunner = CreatePedInsideVehicle(heli, 4, GetHashKey('s_m_y_swat_01'), 1, true, true)
                    table.insert(spawnedNPCs, gunner)
                    GiveWeaponToPed(gunner, GetHashKey('WEAPON_MINISMG'), 999, false, true)
                    TaskCombatPed(gunner, playerPed, 0, 16)
                end
            end
        end
    end

    -- Military tank at 5 stars
    if resp.military then
        local cx, cy = px + 60, py
        local cz = GetGroundZFor_3dCoord(cx, cy, pz + 5.0, false)
        RequestModel(GetHashKey('rhino'))
        local rt = 0
        while not HasModelLoaded(GetHashKey('rhino')) do Wait(100); rt = rt + 100; if rt > 5000 then break end end
        if HasModelLoaded(GetHashKey('rhino')) then
            local tank = CreateVehicle(GetHashKey('rhino'), cx, cy, cz, 0.0, true, false)
            if DoesEntityExist(tank) then
                table.insert(spawnedNPCs, tank)
                SetVehicleEngineOn(tank, true, true, false)
                local driver = CreatePedInsideVehicle(tank, 4, GetHashKey('s_m_y_marine_01'), -1, true, true)
                table.insert(spawnedNPCs, driver)
                TaskVehicleChase(driver, playerPed)
                SetTaskVehicleChaseBehaviorFlag(driver, 1, true)
            end
        end
    end
end

-- ── LoS detection ─────────────────────────────────────────────────────────────

local function checkPoliceLoS()
    local myPed = PlayerPedId()
    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
            local ped = GetPlayerPed(pid)
            if GetPedCurrentVehicleWeapon and HasEntityClearLosToEntity(ped, myPed, 17) then
                -- another real player cop could see us — check if they're police
            end
        end
    end
    -- Also check spawned cop NPCs
    for _, npc in ipairs(spawnedNPCs) do
        if DoesEntityExist(npc) and IsEntityAPed(npc) then
            if HasEntityClearLosToEntity(npc, myPed, 17) then
                return true
            end
        end
    end
    return false
end

-- ── Death detection for cop NPCs ─────────────────────────────────────────────

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim  = args[1]
        local killed  = args[4] == 1
        local attacker = args[2]
        if killed and attacker == PlayerPedId() then
            local model = GetEntityModel(victim)
            if COP_MODELS[model] then
                TriggerServerEvent('eonexis-wanted:copKilled')
                -- Escalate wanted for killing police
                TriggerServerEvent('eonexis-wanted:addCrime', 'killing_police')
            end
        end
    end
end)

-- ── Main thread ───────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-wanted:updateStars')
AddEventHandler('eonexis-wanted:updateStars', function(pts)
    local oldLevel = math.floor(myPoints / 10)
    myPoints = pts
    local newLevel = math.floor(myPoints / 10)
    if newLevel ~= oldLevel then
        -- Re-spawn response units for new star level
        CreateThread(function()
            Wait(500)
            local stars = myPoints / 10
            spawnResponseForStars(stars)
        end)
    end
    if myPoints == 0 then
        clearNPCs()
        exports['eonexis-notify']:Notify('✅ Wanted Cleared', 'You are no longer wanted', 'success', 3000)
    end
end)

-- Decay thread
CreateThread(function()
    while true do
        Wait(1000)
        if myPoints > 0 then
            local hasSight = checkPoliceLoS()
            if hasSight then
                lastSeen  = GetGameTimer()
                decaying  = false
            else
                local gap = (GetGameTimer() - lastSeen) / 1000
                if gap >= Config.DecayDelay then
                    decaying = true
                end
            end
            if decaying then
                myPoints = math.max(0, myPoints - Config.DecayPerSecond)
                TriggerServerEvent('eonexis-wanted:decay', myPoints)
            end
        else
            decaying = false
        end
    end
end)

-- HUD thread
CreateThread(function()
    while true do
        Wait(0)
        local stars = myPoints / 10
        if stars > 0 then
            drawStarsHUD(stars)
        end
    end
end)

-- Crime detection hooks for driving offenses
CreateThread(function()
    while true do
        Wait(2000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                local speed = GetEntitySpeed(veh) * 3.6
                if speed > 160 then
                    TriggerServerEvent('eonexis-wanted:addCrime', 'vehicleramming')
                end
            end
        end
    end
end)

-- /wanted command (player self-check)
RegisterCommand('wanted', function()
    local stars = myPoints / 10
    if stars <= 0 then
        exports['eonexis-notify']:Notify('✅ Clean Record', 'You have no wanted level', 'info', 3000)
    else
        exports['eonexis-notify']:Notify('🚨 Wanted Level',
            string.format('%.1f stars (%d points)', stars, myPoints), 'warning', 4000)
    end
end, false)
