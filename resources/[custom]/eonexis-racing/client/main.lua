-- eonexis-racing — client

local inRace        = false
local raceRoute     = nil
local currentCP     = 1
local raceStartTime = 0
local cpBlips       = {}
local activeBlip    = nil
local lobbyOpen     = false

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Street Race', msg, t or 'info', 5000)
    end
end

local function clearBlips()
    for _, b in ipairs(cpBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    cpBlips = {}
    if activeBlip and DoesBlipExist(activeBlip) then
        RemoveBlip(activeBlip); activeBlip = nil
    end
end

local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format('%d:%05.2f', m, s)
end

local function getRoute(id)
    for _, r in ipairs(Config.Routes) do
        if r.id == id then return r end
    end
end

-- ── HUD during race ───────────────────────────────────────────────────────────

local function drawRaceHUD()
    if not inRace or not raceRoute then return end
    local elapsed = (GetGameTimer() - raceStartTime) / 1000
    local total   = #raceRoute.checkpoints + 1  -- +1 for start

    -- Timer top-center
    SetTextFont(7)
    SetTextScale(0.0, 0.55)
    SetTextColour(255, 255, 255, 240)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(formatTime(elapsed))
    EndTextCommandDisplayText(0.5, 0.02)

    -- Checkpoint counter
    SetTextFont(4)
    SetTextScale(0.0, 0.32)
    SetTextColour(200, 180, 255, 220)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(string.format('CP %d / %d', currentCP - 1, #raceRoute.checkpoints))
    EndTextCommandDisplayText(0.5, 0.068)
end

-- ── Race flow ─────────────────────────────────────────────────────────────────

local function setNextCheckpoint()
    if activeBlip and DoesBlipExist(activeBlip) then
        RemoveBlip(activeBlip)
    end
    if currentCP > #raceRoute.checkpoints then return end
    local pos = raceRoute.checkpoints[currentCP]
    activeBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(activeBlip, 38)
    SetBlipColour(activeBlip, 46)  -- yellow
    SetBlipScale(activeBlip, 1.0)
    SetBlipRoute(activeBlip, true)
    SetBlipRouteColour(activeBlip, 46)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Checkpoint ' .. currentCP)
    EndTextCommandSetBlipName(activeBlip)
end

local function startRace(routeId, countdown)
    raceRoute    = getRoute(routeId)
    currentCP    = 1
    inRace       = false
    clearBlips()
    if not raceRoute then return end

    -- Countdown
    notify(raceRoute.name .. ' — Get ready!', 'info')
    Wait((countdown or 3) * 1000)

    inRace       = true
    raceStartTime = GetGameTimer()
    setNextCheckpoint()
    notify('GO GO GO!', 'success')
    TriggerServerEvent('eonexis-quests:serverKey', 'race_joined')
end

local function finishRace()
    if not inRace then return end
    inRace = false
    clearBlips()
    local elapsed = (GetGameTimer() - raceStartTime) / 1000
    TriggerServerEvent('eonexis-racing:finish', raceRoute.id, elapsed)
end

-- Checkpoint proximity check
CreateThread(function()
    while true do
        Wait(200)
        if inRace and raceRoute then
            drawRaceHUD()
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if currentCP <= #raceRoute.checkpoints then
                local cp = raceRoute.checkpoints[currentCP]
                local dist = #(pos - cp)
                if dist < Config.CheckpointRadius then
                    -- Draw checkpoint hit flash
                    DrawRect(0.5, 0.5, 2.0, 2.0, 255, 255, 255, 40)
                    currentCP = currentCP + 1
                    if currentCP > #raceRoute.checkpoints then
                        finishRace()
                    else
                        setNextCheckpoint()
                        notify(string.format('Checkpoint! %d to go.', #raceRoute.checkpoints - currentCP + 1), 'info')
                    end
                end
            end
        end
    end
end)

-- ── Lobby / race start marker ─────────────────────────────────────────────────

local lobbyBlips = {}

CreateThread(function()
    Wait(2000)
    for _, route in ipairs(Config.Routes) do
        local b = AddBlipForCoord(route.start.x, route.start.y, route.start.z)
        SetBlipSprite(b, 408)    -- race flag
        SetBlipColour(b, 46)     -- yellow
        SetBlipScale(b, 0.8)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('[Race] ' .. route.name)
        EndTextCommandSetBlipName(b)
        table.insert(lobbyBlips, b)
    end
end)

-- Lobby interaction
CreateThread(function()
    while true do
        Wait(0)
        if not inRace then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            for _, route in ipairs(Config.Routes) do
                local dist = #(pos - route.start)
                if dist < 15.0 then
                    -- Draw race start marker
                    DrawMarker(1, route.start.x, route.start.y, route.start.z,
                        0,0,0, 0,0,0, 2.0, 2.0, 1.0,
                        255, 200, 0, 80, false, true, 2, false, nil, nil, false)
                    -- E prompt
                    SetTextFont(4)
                    SetTextScale(0.0, 0.35)
                    SetTextColour(255, 255, 255, 240)
                    SetTextCentre(true)
                    BeginTextCommandDisplayText('STRING')
                    AddTextComponentSubstringPlayerName('[E] Join Race: ' .. route.name)
                    EndTextCommandDisplayText(0.5, 0.86)
                    if IsControlJustPressed(0, 38) then  -- E
                        if not lobbyOpen then
                            lobbyOpen = true
                            TriggerServerEvent('eonexis-racing:joinLobby', route.id)
                            notify('Joined race lobby: ' .. route.name .. '\nRace starts in ' .. Config.LobbyWait .. 's (or press E again to start solo)', 'info')
                        end
                    end
                end
            end
        end
    end
end)

-- ── Server events ─────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-racing:start')
AddEventHandler('eonexis-racing:start', function(routeId, countdown)
    lobbyOpen = false
    startRace(routeId, countdown)
end)

RegisterNetEvent('eonexis-racing:finished')
AddEventHandler('eonexis-racing:finished', function(time, tier, reward, position)
    if tier == 'gold' then
        notify(string.format('FINISH — %s\nGold time! +$%d', formatTime(time), reward), 'success')
    elseif tier == 'silver' then
        notify(string.format('FINISH — %s\nSilver time! +$%d', formatTime(time), reward), 'success')
    elseif position then
        notify(string.format('FINISH — %s\nPlace #%d — +$%d', formatTime(time), position, reward), 'success')
    else
        notify(string.format('FINISH — %s\n+$%d', formatTime(time), reward), 'success')
    end
    TriggerServerEvent('eonexis-quests:serverKey', 'race_finished')
end)

RegisterNetEvent('eonexis-racing:leaderboardUpdate')
AddEventHandler('eonexis-racing:leaderboardUpdate', function(data)
    SendNUIMessage({ action='leaderboard', data=data })
end)

-- /leaderboard
RegisterCommand('leaderboard', function()
    TriggerServerEvent('eonexis-racing:requestLeaderboard')
    SendNUIMessage({ action='open' })
    SetNuiFocus(true, true)
end, false)

RegisterNUICallback('close', function(_, cb)
    cb({})
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
end)

TriggerEvent('chat:addSuggestion', '/leaderboard', 'View race leaderboard')
