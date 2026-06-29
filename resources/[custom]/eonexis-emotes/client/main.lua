-- eonexis-emotes — client

local activeDict = nil
local activePed  = nil

local function stopEmote()
    if activePed and DoesEntityExist(activePed) then
        ClearPedTasksImmediately(activePed)
    end
    activePed  = nil
    activeDict = nil
end

local function loadDict(dict)
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        t = t + 10
        if t > 3000 then return false end
    end
    return true
end

local function playEmote(name)
    local emote = Config.Emotes[name]
    if not emote then
        if exports['eonexis-notify'] then
            exports['eonexis-notify']:Notify('Emotes', 'Unknown emote: ' .. name, 'error', 3000)
        end
        return
    end
    stopEmote()
    local ped = PlayerPedId()
    if not loadDict(emote.dict) then return end
    local flags = emote.loop and 1 or 0
    TaskPlayAnim(ped, emote.dict, emote.clip, 2.0, 2.0, emote.loop and -1 or 2000, flags, 0, false, false, false)
    activePed  = ped
    activeDict = emote.dict
end

RegisterCommand('e', function(_, args)
    local name = args[1]
    if not name or name == 'stop' or name == 'cancel' then
        stopEmote()
        return
    end
    playEmote(name)
end, false)

-- Stop emote when getting in a vehicle
CreateThread(function()
    local wasInVeh = false
    while true do
        Wait(500)
        local inVeh = GetVehiclePedIsIn(PlayerPedId(), false) ~= 0
        if inVeh and not wasInVeh and activePed then
            stopEmote()
        end
        wasInVeh = inVeh
    end
end)

-- Chat suggestion
TriggerEvent('chat:addSuggestion', '/e', 'Play an emote (/e stop to cancel)',
    {{ name='name', help='sit|wave|clap|dance|lean|smoke|kneel|pushups|situps|yoga|phone|eat|bow|salute|shrug|point|thumbsup|fistbump|stop' }})
