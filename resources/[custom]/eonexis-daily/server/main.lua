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
    SaveResourceFile(GetCurrentResourceName(), dataPath, json.encode(data), -1)
end

local function getDate()
    local t = os.date('!*t')
    return string.format('%04d-%02d-%02d', t.year, t.month, t.day)
end

local function dateDiff(a, b)
    local function toSec(s)
        local y,m,d = s:match('(%d+)-(%d+)-(%d+)')
        return os.time({ year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=0, min=0, sec=0 })
    end
    return math.floor((toSec(b) - toSec(a)) / 86400)
end

local function getIdentifier(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if license and license ~= '' then return license end
    local steam = GetPlayerIdentifierByType(src, 'steam')
    if steam and steam ~= '' then return steam end
    return GetPlayerIdentifier(src, 0)
end

loadData()

RegisterNetEvent('eonexis-daily:claim')
AddEventHandler('eonexis-daily:claim', function()
    local src = source
    local id = getIdentifier(src)
    if not id then
        TriggerClientEvent('eonexis-daily:result', src, false, 'Could not identify player.', 0, 0)
        return
    end

    local today = getDate()
    local pData = data[id] or { lastDate=nil, streak=0 }

    if pData.lastDate == today then
        TriggerClientEvent('eonexis-daily:result', src, false, 'Already claimed today. Come back tomorrow!', 0, pData.streak)
        return
    end

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
    data[id] = pData
    saveData()

    exports['eonexis-economy']:addMoney(src, reward, 'daily check-in')
    TriggerClientEvent('eonexis-daily:result', src, true, rewardData.label, reward, pData.streak)
    TriggerEvent('eonexis-quests:objectiveDone', src, 'daily_claimed')
end)
