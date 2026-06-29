-- eonexis-anticheat — client
-- Reports speed/position to server for detection; no client-side enforcement

local lastPos    = nil
local graceUntil = 0  -- epoch ms — skip checks during spawn/teleport grace period

-- Grant 12s grace period after spawn to prevent false flags
AddEventHandler('sessionmanager:playerLoaded', function()
    lastPos    = nil
    graceUntil = GetGameTimer() + 12000
end)

-- Also reset on any teleport event from admin tools
AddEventHandler('eonexis-admintools:teleported', function()
    lastPos    = nil
    graceUntil = GetGameTimer() + 5000
end)

CreateThread(function()
    while true do
        Wait(Config.CheckInterval)
        if GetGameTimer() < graceUntil then
            lastPos = GetEntityCoords(PlayerPedId())
        else
            local ped   = PlayerPedId()
            local pos   = GetEntityCoords(ped)
            local spd   = GetEntitySpeed(ped)
            local inVeh = GetVehiclePedIsIn(ped, false) ~= 0

            if lastPos then
                local dist = #(pos - lastPos)
                TriggerServerEvent('eonexis-anticheat:report', {
                    speed    = spd,
                    dist     = dist,
                    inVehicle= inVeh,
                })
            end
            lastPos = pos
        end
    end
end)
