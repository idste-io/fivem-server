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
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    end
end)

-- Bring: target teleports to admin
RegisterNetEvent('eonexis-admintools:bringMe')
AddEventHandler('eonexis-admintools:bringMe', function(adminSrc)
    local adminPed = GetPlayerPed(GetPlayerFromServerId(adminSrc))
    if DoesEntityExist(adminPed) then
        local coords = GetEntityCoords(adminPed)
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
    SetEntityCollision(ped, not noclip, true)
    if noclip then
        SetEntityAlpha(ped, 180, false)
    else
        ResetEntityAlpha(ped)
    end
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Admin', noclip and 'Noclip ON' or 'Noclip OFF', 'info', 2000)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if noclip then
            local ped = PlayerPedId()
            local speed = 0.5
            if IsControlPressed(0, 21) then speed = 2.0 end  -- shift = fast
            local fwd   = GetEntityForwardVector(ped)
            local dx, dy, dz = 0.0, 0.0, 0.0
            if IsControlPressed(0, 32) then dx = fwd.x * speed; dy = fwd.y * speed end
            if IsControlPressed(0, 33) then dx = -fwd.x * speed; dy = -fwd.y * speed end
            if IsControlPressed(0, 34) then dx = -fwd.y * speed; dy = fwd.x * speed end
            if IsControlPressed(0, 35) then dx = fwd.y * speed; dy = -fwd.x * speed end
            if IsControlPressed(0, 44) then dz = speed end   -- Q up
            if IsControlPressed(0, 38) then dz = -speed end  -- E down
            local pos = GetEntityCoords(ped)
            SetEntityVelocity(ped, 0, 0, 0)
            SetEntityCoords(ped, pos.x + dx, pos.y + dy, pos.z + dz, false, false, false, false)
            ClearPedTasks(ped)
        end
    end
end)
