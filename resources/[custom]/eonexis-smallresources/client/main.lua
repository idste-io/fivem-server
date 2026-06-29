-- eonexis-smallresources — client
-- Seatbelt, AFK kick, cruise control, auto-helmet on bikes

local seatbelt    = false
local lastPos     = vector3(0, 0, 0)
local lastSpeed   = 0.0
local lastMoveMs  = 0
local afkWarned   = false
local cruiseOn    = false
local cruiseSpeed = 0.0
local workVeh     = nil  -- current job vehicle entity

local function notify(title, msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify(title, msg, t or 'info', 3500)
    end
end

-- ── Seatbelt ────────────────────────────────────────────────────────────────
if Config.Seatbelt.enabled then
    RegisterKeyMapping('seatbelt', 'Toggle Seatbelt', 'keyboard', Config.Seatbelt.key)
    RegisterCommand('seatbelt', function()
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            notify('Seatbelt', 'You need to be in a vehicle.', 'warning')
            return
        end
        seatbelt = not seatbelt
        notify('Seatbelt', seatbelt and 'Seatbelt ON' or 'Seatbelt OFF', seatbelt and 'success' or 'warning')
    end, false)
    TriggerEvent('chat:addSuggestion', '/seatbelt', 'Toggle your seatbelt')
end

-- ── Cruise Control ───────────────────────────────────────────────────────────
if Config.CruiseControl.enabled then
    RegisterKeyMapping('cruisecontrol', 'Toggle Cruise Control', 'keyboard', Config.CruiseControl.key)
    RegisterCommand('cruisecontrol', function()
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then return end
        cruiseOn = not cruiseOn
        if cruiseOn then
            local veh = GetVehiclePedIsIn(ped, false)
            cruiseSpeed = GetEntitySpeed(veh)
            notify('Cruise', string.format('Cruise Control ON — %.0f mph', cruiseSpeed * 2.237), 'info')
        else
            notify('Cruise', 'Cruise Control OFF', 'info')
        end
    end, false)
end

-- ── Main loop ────────────────────────────────────────────────────────────────
CreateThread(function()
    lastMoveMs = GetGameTimer()

    while true do
        local wait = 500
        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)

        -- AFK detection (foot + vehicle) — skip while a NUI menu has focus
        if Config.AfkKick.enabled and not IsNuiFocused() then
            local moved = #(pos - lastPos) > 0.5
            local input = IsControlPressed(0, 30) or IsControlPressed(0, 31) or  -- W/S
                          IsControlPressed(0, 34) or IsControlPressed(0, 35) or  -- A/D
                          IsControlPressed(0, 24) or IsControlPressed(0, 25) or  -- attack
                          IsControlPressed(0, 71) or IsControlPressed(0, 72)     -- accel/brake
            if moved or input then
                lastMoveMs = GetGameTimer()
                afkWarned  = false
            end

            local idleMs = GetGameTimer() - lastMoveMs
            if idleMs >= Config.AfkKick.warnMs and not afkWarned then
                afkWarned = true
                notify('AFK Warning', 'You will be kicked for inactivity in 60 seconds!', 'warning')
            end
            if idleMs >= Config.AfkKick.timeoutMs then
                TriggerServerEvent('eonexis-smallresources:afkKick')
                lastMoveMs = GetGameTimer()  -- prevent spam
            end
        elseif IsNuiFocused() then
            -- keep the AFK timer fresh while a menu is open
            lastMoveMs = GetGameTimer()
            afkWarned  = false
        end
        lastPos = pos

        -- In-vehicle logic
        if IsPedInAnyVehicle(ped, false) then
            wait = 200
            local veh       = GetVehiclePedIsIn(ped, false)
            local speedMs   = GetEntitySpeed(veh)
            local speedMph  = speedMs * 2.237
            local vClass    = GetVehicleClass(veh)

            -- Auto-equip helmet on motorcycles (class 8) and quads (class 13)
            if Config.Helmet.enabled and Config.Helmet.autoEquip then
                if vClass == 8 or vClass == 13 then
                    if not IsPedWearingHelmet(ped) then
                        GivePedHelmet(ped, false, 4, 0)
                        SetPedHelmet(ped, true)
                    end
                end
            end

            -- Seatbelt: detect sudden decel (crash) and eject
            if Config.Seatbelt.enabled and not seatbelt and lastSpeed > Config.Seatbelt.ejectSpeed then
                if speedMph < lastSpeed * 0.3 and lastSpeed > Config.Seatbelt.ejectSpeed then
                    -- Crash! Eject player
                    local fwd = GetEntityForwardVector(veh)
                    TaskLeaveVehicle(ped, veh, 4160)
                    Wait(50)
                    SetEntityVelocity(ped,
                        fwd.x * lastSpeed * 0.25,
                        fwd.y * lastSpeed * 0.25,
                        lastSpeed * 0.15)
                    notify('Crash!', 'You were ejected — wear your seatbelt!', 'error')
                end
            end
            lastSpeed = speedMph

            -- Cruise control: hold speed unless braking
            if cruiseOn then
                local braking  = IsControlPressed(0, 71) or IsControlPressed(0, 72)
                local handbrake = IsControlPressed(0, 75)
                if braking or handbrake then
                    cruiseOn = false
                    notify('Cruise', 'Cruise Control OFF', 'info')
                else
                    SetVehicleForwardSpeed(veh, cruiseSpeed)
                end
            end
        else
            -- Left vehicle — reset state
            seatbelt  = false
            lastSpeed = 0.0
            cruiseOn  = false
        end

        Wait(wait)
    end
end)
