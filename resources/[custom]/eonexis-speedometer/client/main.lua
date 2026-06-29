-- eonexis-speedometer — client

local function mps_to_display(mps)
    if Config.UseKPH then
        return math.floor(mps * 3.6), 'KPH'
    else
        return math.floor(mps * 2.237), 'MPH'
    end
end

local function drawSpeedo(veh)
    local speed, unit = mps_to_display(GetEntitySpeed(veh))
    local gear        = GetVehicleCurrentGear(veh)
    local rpm         = GetVehicleCurrentRpm(veh)  -- 0.0–1.0

    local x, y = Config.PosX, Config.PosY

    -- RPM bar
    if Config.ShowRPM then
        local bW, bH = 0.10, 0.008
        DrawRect(x, y - 0.035, bW + 0.003, bH + 0.003, 0, 0, 0, 150)
        local rpmR = rpm > 0.85 and 255 or 140
        local rpmG = rpm > 0.85 and 50  or 220
        DrawRect(x - (bW / 2) + (bW * rpm / 2), y - 0.035, bW * rpm, bH, rpmR, rpmG, 80, 210)
    end

    -- Speed number
    SetTextFont(7)
    SetTextScale(0.55, 0.55)
    SetTextColour(255, 255, 255, 240)
    SetTextRightJustify(true)
    SetTextEntry('STRING')
    AddTextComponentString(tostring(speed))
    DrawText(x + 0.012, y - 0.025)

    -- Unit label
    SetTextFont(4)
    SetTextScale(0.24, 0.24)
    SetTextColour(200, 200, 200, 180)
    SetTextRightJustify(true)
    SetTextEntry('STRING')
    AddTextComponentString(unit)
    DrawText(x + 0.012, y + 0.005)

    -- Gear
    if Config.ShowGear then
        local gearStr = gear == 0 and 'R' or tostring(gear)
        SetTextFont(7)
        SetTextScale(0.38, 0.38)
        SetTextColour(140, 100, 255, 220)
        SetTextRightJustify(false)
        SetTextEntry('STRING')
        AddTextComponentString(gearStr)
        DrawText(x - 0.065, y - 0.018)
    end
end

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetIsVehicleEngineRunning(veh) then
            drawSpeedo(veh)
        end
    end
end)
