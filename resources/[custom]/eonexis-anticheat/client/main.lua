-- eonexis-anticheat — client
-- Reports speed/position to server for detection; no client-side enforcement

local lastPos = nil

CreateThread(function()
    while true do
        Wait(Config.CheckInterval)
        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)
        local spd  = GetEntitySpeed(ped)
        local inVeh= GetVehiclePedIsIn(ped, false) ~= 0

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
end)
