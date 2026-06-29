-- eonexis-weather — server: drives weather cycle + syncs time to all clients

local cycleIdx  = 1
local startTick = GetGameTimer()
local cycleMs   = Config.CycleMinutes * 60 * 1000
local svrHour   = 12
local svrMin    = 0

local function currentWeather()
    return Config.WeatherCycle[cycleIdx] or 'CLEAR'
end

local function advanceCycle()
    local idx = math.floor((GetGameTimer() - startTick) / cycleMs) % #Config.WeatherCycle + 1
    if idx ~= cycleIdx then
        cycleIdx = idx
        TriggerClientEvent('eonexis-weather:setWeather', -1, currentWeather(), Config.TransitionTime)
        print('[eonexis-weather] → ' .. currentWeather())
    end
end

-- Tick time forward
CreateThread(function()
    while true do
        Wait(1000)
        svrMin = svrMin + Config.TimeScale
        if svrMin >= 60 then svrMin = svrMin - 60; svrHour = (svrHour + 1) % 24 end
        advanceCycle()
    end
end)

-- Periodic time broadcast every 30s
CreateThread(function()
    while true do
        Wait(30000)
        TriggerClientEvent('eonexis-weather:setTime', -1, svrHour, svrMin)
    end
end)

-- Sync new joiners after 3s
AddEventHandler('playerConnecting', function()
    local src = source
    CreateThread(function()
        Wait(3000)
        TriggerClientEvent('eonexis-weather:setWeather', src, currentWeather(), 0)
        TriggerClientEvent('eonexis-weather:setTime',    src, svrHour, svrMin)
    end)
end)

RegisterNetEvent('eonexis-weather:requestSync')
AddEventHandler('eonexis-weather:requestSync', function()
    local src = source
    TriggerClientEvent('eonexis-weather:setWeather', src, currentWeather(), 0)
    TriggerClientEvent('eonexis-weather:setTime',    src, svrHour, svrMin)
end)
