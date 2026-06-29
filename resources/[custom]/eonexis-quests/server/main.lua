-- eonexis-quests — server

local DATA_FILE = Config.DataFile
local db = {}   -- { [license] = { [questId] = { completed=bool, objectives={[id]=bool} } } }

local function getIdentifier(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if license and license ~= '' then return license end
    local steam = GetPlayerIdentifierByType(src, 'steam')
    if steam and steam ~= '' then return steam end
    return GetPlayerIdentifier(src, 0)
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

loadDB()

CreateThread(function()
    while true do Wait(120000); saveDB() end
end)

local function getRecord(src)
    local lic = getIdentifier(src)
    if not lic then return nil, nil end
    if not db[lic] then db[lic] = {} end
    return db[lic], lic
end

local function getQuestById(id)
    for _, q in ipairs(Config.Quests) do
        if q.id == id then return q end
    end
end

local function questAvailable(rec, quest)
    for _, req in ipairs(quest.requires) do
        if not (rec[req] and rec[req].completed) then return false end
    end
    return true
end

local function tryCompleteQuest(src, rec, questId)
    local quest = getQuestById(questId)
    if not quest or (rec[questId] and rec[questId].completed) then return end
    local state = rec[questId] or { completed=false, objectives={} }
    -- Check all objectives done
    for _, obj in ipairs(quest.objectives) do
        if not state.objectives[obj.id] then return end
    end
    state.completed = true
    rec[questId] = state
    saveDB()
    exports['eonexis-economy']:addMoney(src, quest.reward.cash, 'quest reward: ' .. questId)
    TriggerClientEvent('eonexis-quests:questComplete', src, questId, quest.title, quest.reward.cash)
    print(('[quests] %s completed quest: %s (+$%d)'):format(GetPlayerName(src), questId, quest.reward.cash))
    -- Auto-start next quests
    for _, q in ipairs(Config.Quests) do
        if not (rec[q.id] and rec[q.id].started) and questAvailable(rec, q) then
            autoStartQuest(src, rec, q)
        end
    end
end

function autoStartQuest(src, rec, quest)
    if rec[quest.id] and rec[quest.id].started then return end
    if not rec[quest.id] then rec[quest.id] = { completed=false, objectives={}, started=true } end
    rec[quest.id].started = true
    -- Complete auto objectives immediately
    for _, obj in ipairs(quest.objectives) do
        if obj.trigger == 'auto' then
            rec[quest.id].objectives[obj.id] = true
        end
    end
    saveDB()
    -- Check if all done already (e.g., single auto-objective quest)
    tryCompleteQuest(src, rec, quest.id)
end

local function completeObjective(src, questId, objId)
    local rec, lic = getRecord(src)
    if not rec or not lic then return end
    local quest = getQuestById(questId)
    if not quest then return end
    if not questAvailable(rec, quest) then return end
    if rec[questId] and rec[questId].completed then return end
    if not rec[questId] then rec[questId] = { completed=false, objectives={}, started=true } end
    if rec[questId].objectives[objId] then return end

    -- Find the objective
    local objText = objId
    for _, obj in ipairs(quest.objectives) do
        if obj.id == objId then objText = obj.text; break end
    end

    rec[questId].objectives[objId] = true
    saveDB()
    TriggerClientEvent('eonexis-quests:objectiveComplete', src, questId, objId, objText)
    tryCompleteQuest(src, rec, questId)
end

-- ── Net events ───────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-quests:requestSync')
AddEventHandler('eonexis-quests:requestSync', function()
    local src = source
    local rec, lic = getRecord(src)
    if not rec then return end
    -- Auto-start available quests on first sync
    for _, q in ipairs(Config.Quests) do
        if questAvailable(rec, q) then
            autoStartQuest(src, rec, q)
        end
    end
    TriggerClientEvent('eonexis-quests:sync', src, rec)
end)

RegisterNetEvent('eonexis-quests:completeObjective')
AddEventHandler('eonexis-quests:completeObjective', function(questId, objId)
    completeObjective(source, questId, objId)
end)

local jobTaskCounts = {}  -- { [lic] = N } in-memory count for job_tasks_5

-- Server-side key trigger: any mod fires this with a key string
RegisterNetEvent('eonexis-quests:serverKey')
AddEventHandler('eonexis-quests:serverKey', function(key)
    local src = source
    local rec, lic = getRecord(src)
    if not rec or not lic then return end

    -- Track job task count for the_grind quest
    if key == 'job_task_done' then
        jobTaskCounts[lic] = (jobTaskCounts[lic] or 0) + 1
        if jobTaskCounts[lic] >= 5 then
            completeObjective(src, 'the_grind', 'tasks5')
        end
    end

    -- Map keys to quest objectives
    local mapping = {
        rules_opened     = { quest='know_the_rules',   obj='rules'      },
        balance_checked  = { quest='first_dollar',     obj='balance'    },
        job_task_done    = { quest='first_dollar',     obj='job_task'   },
        job_tasks_5      = { quest='the_grind',        obj='tasks5'     },
        earn_10k         = { quest='the_grind',        obj='earn10k'    },
        vehicle_purchased= { quest='petrolhead',       obj='buy_car'    },
        casino_spun      = { quest='high_roller',      obj='spin'       },
        property_purchased={ quest='property_dreams',  obj='buy_prop'   },
        emote_used       = { quest='social_butterfly', obj='emote'      },
        player_paid      = { quest='social_butterfly', obj='pay'        },
        daily_claimed    = { quest='daily_dedication', obj='daily1'     },
        phone_opened     = { quest='daily_dedication', obj='phone'      },
        has_weapon       = { quest='five_finger_discount', obj='getweapon' },
        robbery_success  = { quest='five_finger_discount', obj='rob_store' },
        race_joined      = { quest='street_legend',    obj='join_race'  },
        race_finished    = { quest='street_legend',    obj='finish_race'},
    }
    local m = mapping[key]
    if m then completeObjective(src, m.quest, m.obj) end
end)

-- Server event (fired from other mods directly)
AddEventHandler('eonexis-quests:objectiveDone', function(src, key)
    if type(src) == 'number' then
        -- fired from server: eonexis-quests:objectiveDone, src, key
        TriggerEvent('eonexis-quests:serverKeyLocal', src, key)
    end
end)

AddEventHandler('eonexis-quests:serverKeyLocal', function(src, key)
    local rec, lic = getRecord(src)
    if not rec or not lic then return end
    local mapping = {
        daily_claimed    = { quest='daily_dedication', obj='daily1'     },
        robbery_success  = { quest='five_finger_discount', obj='rob_store' },
        race_joined      = { quest='street_legend',    obj='join_race'  },
        race_finished    = { quest='street_legend',    obj='finish_race'},
        casino_spun      = { quest='high_roller',      obj='spin'       },
        vehicle_purchased= { quest='petrolhead',       obj='buy_car'    },
        property_purchased={ quest='property_dreams',  obj='buy_prop'   },
        emote_used       = { quest='social_butterfly', obj='emote'      },
        player_paid      = { quest='social_butterfly', obj='pay'        },
        job_task_done    = { quest='first_dollar',     obj='job_task'   },
        job_tasks_5      = { quest='the_grind',        obj='tasks5'     },
    }
    local m = mapping[key]
    if m then completeObjective(src, m.quest, m.obj) end
end)

-- Export for other mods to fire objectives
exports('objectiveDone', function(src, key)
    TriggerEvent('eonexis-quests:serverKeyLocal', src, key)
end)

AddEventHandler('playerDropped', function() saveDB() end)
