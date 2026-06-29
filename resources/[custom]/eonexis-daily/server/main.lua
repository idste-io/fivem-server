-- eonexis-daily — server

local dataPath = Config.DataFile
local data = {}

local function loadData()
    local raw = LoadResourceFile(GetCurrentResourceName(), dataPath)
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and parsed then data = parsed end
    end
end

local function saveData()
    local dir = dataPath:match('(.+)/[^/]+$')
    SaveResourceFile(GetCurrentResourceName(), dataPath, json.encode(data), -1)
end

local function getDate()
    -- Returns YYYY-MM-DD in UTC
    local t = os.date('!*t')
    return string.format('%04d-%02d-%02d', t.year, t.month, t.day)
end

local function dateDiff(a, b)
    -- Returns difference in days between two YYYY-MM-DD strings (b - a)
    local function toSec(s)
        local y,m,d = s:match('(%d+)-(%d+)-(%d+)')
        return os.time({ year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=0, min=0, sec=0 })
    end
    return math.floor((toSec(b) - toSec(a)) / 86400)
end

loadData()

AddEventHandler('playerConnecting', function(name, _, deferrals)
    deferrals.defer()
    Wait(0)

    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local steamId = nil
    for _, id in ipairs(identifiers) do
        if id:sub(1,6) == 'steam:' then steamId = id; break end
    end
    if not steamId then
        for _, id in ipairs(identifiers) do
            if id:sub(1,3) == 'ip:' then steamId = id; break end
        end
    end

    if steamId and not data[steamId] then
        data[steamId] = { lastDate=nil, streak=0 }
    end

    deferrals.done()
end)

RegisterNetEvent('eonexis-daily:claim')
AddEventHandler('eonexis-daily:claim', function()
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local steamId = nil
    for _, id in ipairs(identifiers) do
        if id:sub(1,6) == 'steam:' then steamId = id; break end
    end
    if not steamId then
        for _, id in ipairs(identifiers) do
            if id:sub(1,3) == 'ip:' then steamId = id; break end
        end
    end
    if not steamId then
        TriggerClientEvent('eonexis-daily:result', src, false, 'Could not identify player.', 0, 0)
        return
    end

    local today = getDate()
    local pData = data[steamId] or { lastDate=nil, streak=0 }

    if pData.lastDate == today then
        TriggerClientEvent('eonexis-daily:result', src, false, 'Already claimed today. Come back tomorrow!', 0, pData.streak)
        return
    end

    -- Update streak
    if pData.lastDate then
        local diff = dateDiff(pData.lastDate, today)
        if diff == 1 then
            pData.streak = math.min(pData.streak + 1, Config.MaxStreakDays)
        elseif diff > 1 then
            pData.streak = 1
        end
    else
        pData.streak = 1
    end

    local rewardData = Config.DayRewards[pData.streak] or Config.DayRewards[1]
    local reward = rewardData.cash

    pData.lastDate = today
    data[steamId] = pData
    saveData()

    exports['eonexis-economy']:addMoney(src, reward, 'daily check-in')
    TriggerClientEvent('eonexis-daily:result', src, true, rewardData.label, reward, pData.streak)
end)
