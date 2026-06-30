-- eonexis-anticheat — client
-- Reports speed/position to server for detection; no client-side enforcement

local lastPos    = nil
local graceUntil = 0  -- GetGameTimer() ms — skip checks during spawn/teleport grace period

local function grantGrace(ms)
    lastPos    = nil
    graceUntil = GetGameTimer() + (ms or 8000)
end

-- Initial grace on resource start (covers initial game load)
grantGrace(20000)

-- Grant grace when spawn mod places the player
AddEventHandler('eonexis-spawn:spawned', function()
    grantGrace(10000)
end)

-- Grant grace when phone building-spawn teleports the player
AddEventHandler('eonexis-phone:spawned', function()
    grantGrace(8000)
end)

-- Grant grace for admin teleports
AddEventHandler('eonexis-admintools:teleported', function()
    grantGrace(5000)
end)

-- Server can also grant grace (used by server-side spawn events)
RegisterNetEvent('eonexis-anticheat:grantGrace')
AddEventHandler('eonexis-anticheat:grantGrace', function(ms)
    grantGrace(ms or 8000)
end)

CreateThread(function()
    while true do
        Wait(Config.CheckInterval)
        local now = GetGameTimer()
        if now < graceUntil then
            -- In grace period — just update lastPos so we don't get a stale distance on exit
            lastPos = GetEntityCoords(PlayerPedId())
        else
            local ped   = PlayerPedId()
            local pos   = GetEntityCoords(ped)
            local spd   = GetEntitySpeed(ped)
            local inVeh = GetVehiclePedIsIn(ped, false) ~= 0

            if lastPos then
                local dist = #(pos - lastPos)
                TriggerServerEvent('eonexis-anticheat:report', {
                    speed     = spd,
                    dist      = dist,
                    inVehicle = inVeh,
                })
            end
            lastPos = pos
        end
    end
end)
