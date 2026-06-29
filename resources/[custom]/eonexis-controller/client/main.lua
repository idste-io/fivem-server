-- eonexis-controller — client
-- Xbox / gamepad quick actions.
-- FiveM handles controller natively for driving — this mod adds:
--   • DPAD shortcuts for common server actions
--   • LB modifier: hold LB + DPAD for emotes
--   • Controller-aware help text

-- GTA uses input groups: 0=player, 2=vehicle, 1=game (menus)
-- IsUsingKeyboard returns false when a controller is connected and active.

local lbHeld  = false  -- LB / L1 held

local function runEmote(name)
    -- Trigger eonexis-emotes command equivalent
    TriggerEvent('chat:addMessage', {}) -- silent; just fire the console command
    ExecuteCommand('e ' .. name)
end

local function runAction(action)
    if action == 'work'      then ExecuteCommand('work')
    elseif action == 'balance'  then ExecuteCommand('balance')
    elseif action == 'jobcenter' then
        TriggerEvent('eonexis-jobs:openMenu')  -- client event to open job center
    elseif action == 'garage' then
        TriggerEvent('eonexis-vehicles:openGarage')
    end
end

-- Show controller hint on-screen when a pad is connected
local function showHint(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, 3000)
end

CreateThread(function()
    while true do
        Wait(0)

        -- Only run controller logic when a gamepad is connected
        -- (FiveM exposes this via IsUsingKeyboard — false = gamepad in use)
        if IsUsingKeyboard(2) then goto noPad end

        -- LB state
        lbHeld = IsControlPressed(0, 200)

        if lbHeld then
            -- LB + DPAD → emote
            if IsControlJustPressed(0, 172) then runEmote(Config.DpadEmote.UP)    end
            if IsControlJustPressed(0, 173) then runEmote(Config.DpadEmote.DOWN)  end
            if IsControlJustPressed(0, 174) then runEmote(Config.DpadEmote.LEFT)  end
            if IsControlJustPressed(0, 175) then runEmote(Config.DpadEmote.RIGHT) end
            -- LB + X/Square
            if IsControlJustPressed(0, 76)  then runEmote(Config.FaceEmotes.X)   end
            -- LB + Y/Triangle
            if IsControlJustPressed(0, 246) then runEmote(Config.FaceEmotes.Y)   end
        else
            -- Plain DPAD → actions (only on foot, not in vehicle)
            local ped   = PlayerPedId()
            local inVeh = GetVehiclePedIsIn(ped, false) ~= 0
            if not inVeh then
                if IsControlJustPressed(0, 172) then runAction(Config.DpadNormal.UP)    end
                if IsControlJustPressed(0, 173) then runAction(Config.DpadNormal.DOWN)  end
                if IsControlJustPressed(0, 174) then runAction(Config.DpadNormal.LEFT)  end
                if IsControlJustPressed(0, 175) then runAction(Config.DpadNormal.RIGHT) end
            end
        end

        ::noPad::
    end
end)

-- Listen for job center open event (triggered by controller or proximity)
AddEventHandler('eonexis-jobs:openMenu', function()
    -- Walk player to job center or just open via server trigger
    -- The job center client already handles the menu opening when near the marker.
    -- This just teleports to job center if far, then opens.
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Controller', 'Head to the Job Center (yellow marker on map)', 'info', 4000)
    end
end)

AddEventHandler('eonexis-vehicles:openGarage', function()
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Controller', 'Head to My Garage (green marker on map)', 'info', 4000)
    end
end)
