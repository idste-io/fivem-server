-- eonexis-admintools — client

local frozen   = false
local godMode  = false
local noclip   = false
local noclipVel = vector3(0, 0, 0)

RegisterNetEvent('eonexis-admintools:notify')
AddEventHandler('eonexis-admintools:notify', function(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Admin', msg, t or 'info', 4000)
    end
end)

-- TP to another player
RegisterNetEvent('eonexis-admintools:tpTo')
AddEventHandler('eonexis-admintools:tpTo', function(targetSrc)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
    if DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        TriggerEvent('eonexis-admintools:teleported')
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    end
end)

-- Bring: target teleports to admin
RegisterNetEvent('eonexis-admintools:bringMe')
AddEventHandler('eonexis-admintools:bringMe', function(adminSrc)
    local adminPed = GetPlayerPed(GetPlayerFromServerId(adminSrc))
    if DoesEntityExist(adminPed) then
        local coords = GetEntityCoords(adminPed)
        TriggerEvent('eonexis-admintools:teleported')
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0, false, false, false, true)
    end
end)

-- Freeze toggle
RegisterNetEvent('eonexis-admintools:freeze')
AddEventHandler('eonexis-admintools:freeze', function()
    frozen = not frozen
    FreezeEntityPosition(PlayerPedId(), frozen)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Admin', frozen and 'You have been frozen.' or 'You have been unfrozen.', 'warning', 4000)
    end
end)

-- God mode toggle
RegisterNetEvent('eonexis-admintools:toggleGod')
AddEventHandler('eonexis-admintools:toggleGod', function()
    godMode = not godMode
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Admin', godMode and 'God mode ON' or 'God mode OFF', 'info', 3000)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if godMode then
            local ped = PlayerPedId()
            SetEntityHealth(ped, 200)
            SetPedArmour(ped, 100)
            SetEntityInvincible(ped, true)
        end
    end
end)

-- Noclip toggle
RegisterNetEvent('eonexis-admintools:toggleNoclip')
AddEventHandler('eonexis-admintools:toggleNoclip', function()
    noclip = not noclip
    local ped = PlayerPedId()
    if noclip then
        TriggerEvent('eonexis-admintools:teleported')  -- initial grace on enable
    else
        -- Restore full entity state when noclip disabled
        SetEntityCollision(ped, true, true)
        ResetEntityAlpha(ped)
        SetEntityVelocity(ped, 0, 0, 0)
        TriggerEvent('eonexis-admintools:teleported')  -- grace for the landing
    end
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Admin', noclip and 'Noclip ON — WASD + Q/E + Shift/Ctrl' or 'Noclip OFF', 'info', 2000)
    end
end)

local noclipGraceTimer = 0

CreateThread(function()
    while true do
        Wait(0)
        if noclip then
            local ped = PlayerPedId()

            -- Renew anticheat grace every 4s while noclip is on
            if GetGameTimer() - noclipGraceTimer > 4000 then
                noclipGraceTimer = GetGameTimer()
                TriggerEvent('eonexis-admintools:teleported')
            end

            -- Exit vehicle if in one
            if IsPedInAnyVehicle(ped, false) then
                TaskLeaveAnyVehicle(ped, 0, 16)
                Wait(500)
            end

            local speed = 0.5
            if IsControlPressed(0, 21) then speed = 2.5 end  -- shift = fast
            if IsControlPressed(0, 36)  then speed = 8.0 end  -- ctrl = very fast

            local camFwd = GetGameplayCamForwardVector()
            local dx, dy, dz = 0.0, 0.0, 0.0

            if IsControlPressed(0, 32) then  -- W — forward along camera direction
                dx = camFwd.x * speed; dy = camFwd.y * speed; dz = camFwd.z * speed
            end
            if IsControlPressed(0, 33) then  -- S — backward
                dx = -camFwd.x * speed; dy = -camFwd.y * speed; dz = -camFwd.z * speed
            end
            -- Strafe
            local right = vector3(-camFwd.y, camFwd.x, 0.0)
            if IsControlPressed(0, 34) then dx = dx + right.x * speed; dy = dy + right.y * speed end
            if IsControlPressed(0, 35) then dx = dx - right.x * speed; dy = dy - right.y * speed end
            -- Vertical
            if IsControlPressed(0, 44) then dz = dz + speed end  -- Q
            if IsControlPressed(0, 38) then dz = dz - speed end  -- E

            local pos = GetEntityCoords(ped)
            SetEntityCollision(ped, false, true)
            SetEntityVelocity(ped, 0, 0, 0)
            SetEntityCoords(ped, pos.x + dx, pos.y + dy, pos.z + dz, false, false, false, false)
            SetEntityAlpha(ped, 180, false)
            FreezeEntityPosition(ped, false)
        else
            noclipGraceTimer = 0
        end
    end
end)
