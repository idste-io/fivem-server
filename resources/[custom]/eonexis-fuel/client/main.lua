-- eonexis-fuel — client

local fuel         = Config.StartFuel
local lastVeh      = nil
local warned       = false
local refueling    = false

-- Persist fuel per vehicle session (reset on new vehicle)
local function getCurrentVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    return veh ~= 0 and veh or nil
end

local function nearGasPump()
    local pos = GetEntityCoords(PlayerPedId())
    for _, pump in ipairs(Config.GasStations) do
        if #(pos - pump) <= Config.RefuelRadius then return true end
    end
    return false
end

-- HUD: fuel bar in bottom-right corner
local function drawFuelBar()
    if not Config.ShowHUD then return end
    local veh = getCurrentVehicle()
    if not veh then return end

    local barW, barH = 0.12, 0.012
    local x, y = 0.88, 0.94

    -- background
    DrawRect(x, y, barW + 0.004, barH + 0.004, 0, 0, 0, 160)
    -- fill
    local pct = fuel / Config.MaxFuel
    local r   = fuel < Config.LowFuelWarn and 220 or 80
    local g   = fuel < Config.LowFuelWarn and 40  or 200
    DrawRect(x - (barW / 2) + (barW * pct / 2), y, barW * pct, barH, r, g, 80, 210)

    -- label
    SetTextFont(4)
    SetTextScale(0.28, 0.28)
    SetTextColour(255, 255, 255, 200)
    SetTextRightJustify(true)
    SetTextEntry('STRING')
    AddTextComponentString(string.format('FUEL  %d%%', math.floor(fuel)))
    DrawText(x + barW / 2, y - 0.018)
end

-- Main fuel tick
CreateThread(function()
    while true do
        Wait(1000)
        local veh = getCurrentVehicle()
        if veh then
            if veh ~= lastVeh then
                -- new vehicle — carry current fuel or start fresh
                lastVeh = veh
                warned = false
            end

            if GetIsVehicleEngineRunning(veh) then
                local speed = GetEntitySpeed(veh)
                local drain = speed > 1.0 and Config.DrainRate or Config.IdleDrainRate
                fuel = math.max(0, fuel - drain)

                -- Cut engine at empty
                if fuel <= 0 then
                    SetVehicleEngineOn(veh, false, true, true)
                    if exports['eonexis-notify'] then
                        exports['eonexis-notify']:Notify('Fuel', 'Tank empty — find a gas station.', 'error', 6000)
                    end
                elseif fuel < Config.LowFuelWarn and not warned then
                    warned = true
                    if exports['eonexis-notify'] then
                        exports['eonexis-notify']:Notify('Fuel', string.format('Low fuel — %d%% remaining.', math.floor(fuel)), 'warning', 5000)
                    end
                end
            end
        else
            lastVeh = nil
            warned = false
        end
    end
end)

-- Refuel thread: hold E near pump
CreateThread(function()
    while true do
        Wait(500)
        local veh = getCurrentVehicle()
        if veh and nearGasPump() and fuel < Config.MaxFuel then
            -- prompt
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('Hold ~INPUT_CONTEXT~ to refuel')
            EndTextCommandDisplayHelp(0, false, true, -1)

            if IsControlPressed(0, 38) then  -- E key
                if not refueling then
                    refueling = true
                    if exports['eonexis-notify'] then
                        exports['eonexis-notify']:Notify('Fuel', 'Refueling...', 'info', 2000)
                    end
                end
                Wait(0)
                fuel = math.min(Config.MaxFuel, fuel + (Config.RefuelRate / 2))
                if fuel >= Config.MaxFuel then
                    refueling = false
                    if exports['eonexis-notify'] then
                        exports['eonexis-notify']:Notify('Fuel', 'Tank full!', 'success', 3000)
                    end
                end
                warned = false
            else
                refueling = false
            end
        else
            refueling = false
        end
    end
end)

-- HUD render thread
CreateThread(function()
    while true do
        Wait(0)
        drawFuelBar()
    end
end)

-- Sync fuel when entering a new session (server tells us current value if tracked)
RegisterNetEvent('eonexis-fuel:setFuel')
AddEventHandler('eonexis-fuel:setFuel', function(val)
    fuel = val
end)
