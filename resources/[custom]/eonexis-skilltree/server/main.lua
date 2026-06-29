-- eonexis-skilltree — server

local DATA_FILE = Config.DataFile
local db = {}   -- { [license] = { completed={[id]=true}, taskCount=N } }

local function getLicense(src)
    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
end

local function loadDB()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if raw and #raw > 2 then
        local ok, parsed = pcall(json.decode, raw)
        if ok and parsed then db = parsed end
    end
end

local function saveDB()
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, json.encode(db), -1)
end

local function getRecord(src)
    local lic = getLicense(src)
    if not lic then return nil, nil end
    if not db[lic] then db[lic] = { completed={}, taskCount=0 } end
    return db[lic], lic
end

loadDB()

-- Auto-save every 2 minutes
CreateThread(function()
    while true do Wait(120000); saveDB() end
end)

local function getSkillById(id)
    for _, s in ipairs(Config.Skills) do
        if s.id == id then return s end
    end
end

local function canUnlock(rec, skill)
    for _, req in ipairs(skill.requires) do
        if not rec.completed[req] then return false end
    end
    return true
end

local function completeSkill(src, skillId)
    local rec, lic = getRecord(src)
    if not rec or not lic then return false, 'identity error' end
    if rec.completed[skillId] then return false, 'already completed' end

    local skill = getSkillById(skillId)
    if not skill then return false, 'unknown skill' end
    if not canUnlock(rec, skill) then return false, 'requirements not met' end

    rec.completed[skillId] = true
    saveDB()

    -- Pay reward
    if skill.reward and skill.reward.cash and skill.reward.cash > 0 then
        exports['eonexis-economy']:addMoney(src, skill.reward.cash, 'skill reward: ' .. skillId)
    end

    -- Send updated progress to client
    TriggerClientEvent('eonexis-skilltree:update', src, rec.completed, rec.taskCount or 0)

    print(('[skilltree] %s completed skill: %s (+$%d)'):format(
        GetPlayerName(src), skillId, skill.reward and skill.reward.cash or 0))

    return true, skill
end

-- ── Net events ──────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-skilltree:requestData')
AddEventHandler('eonexis-skilltree:requestData', function()
    local src = source
    local rec = getRecord(src)
    if rec then
        TriggerClientEvent('eonexis-skilltree:update', src, rec.completed, rec.taskCount or 0)
    end
end)

RegisterNetEvent('eonexis-skilltree:complete')
AddEventHandler('eonexis-skilltree:complete', function(skillId)
    local src = source
    local ok, result = completeSkill(src, skillId)
    if ok then
        TriggerClientEvent('eonexis-skilltree:completed', src, result)
    else
        TriggerClientEvent('eonexis-economy:notify', src, 'Skill: ' .. result, 'error')
    end
end)

-- Auto-complete 'welcome' on join — use playerJoining (NOT playerConnecting deferral)
AddEventHandler('playerJoining', function()
    local src = source
    Citizen.SetTimeout(3000, function()   -- 3s delay so identity is ready
        local rec, lic = getRecord(src)
        if rec and not rec.completed['welcome'] then
            completeSkill(src, 'welcome')
        end
    end)
end)

-- Track task count (fired by jobs mod)
AddEventHandler('eonexis-skilltree:taskDone', function()
    local src = source
    local rec = getRecord(src)
    if not rec then return end
    rec.taskCount = (rec.taskCount or 0) + 1
    if rec.taskCount >= 1  and not rec.completed['first_task']      then completeSkill(src, 'first_task') end
    if rec.taskCount >= 5  and not rec.completed['complete_5_tasks'] then completeSkill(src, 'complete_5_tasks') end
    if rec.taskCount >= 10 and not rec.completed['complete_10_tasks'] then completeSkill(src, 'complete_10_tasks') end
    saveDB()
end)

-- License purchased (server-side hook)
AddEventHandler('eonexis-jobs:onLicensePurchased', function(src, licId)
    completeSkill(src, 'buy_license')
    TriggerEvent('eonexis-quests:objectiveDone', src, 'license_purchased')
end)

-- Export: get player completed skills (for other mods to check)
exports('getCompleted', function(src)
    local rec = getRecord(src)
    return rec and rec.completed or {}
end)

-- Export: complete a skill from another mod
exports('completeSkill', function(src, skillId)
    return completeSkill(src, skillId)
end)

AddEventHandler('playerDropped', function() end)
