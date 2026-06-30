-- eonexis-skilltree — client

local treeOpen   = false
local completed  = {}
local taskCount  = 0
local questBlips = {}  -- active quest blips on minimap

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Skill Tree', msg, t or 'info', 5000)
    end
end

-- ── Blip management ──────────────────────────────────────────────────────────

local function clearQuestBlips()
    for _, b in ipairs(questBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    questBlips = {}
end

local function refreshQuestBlips()
    clearQuestBlips()
    for _, skill in ipairs(Config.Skills) do
        if skill.blip and not completed[skill.id] and canUnlock(skill) then
            local b = AddBlipForCoord(skill.blip.pos.x, skill.blip.pos.y, skill.blip.pos.z)
            SetBlipSprite(b, skill.blip.sprite or 161)
            SetBlipColour(b, skill.blip.colour or 26)  -- purple = skill quest
            SetBlipScale(b, 0.75)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName('[Quest] ' .. (skill.blip.label or skill.label))
            EndTextCommandSetBlipName(b)
            table.insert(questBlips, b)
        end
    end
end

function canUnlock(skill)
    for _, req in ipairs(skill.requires) do
        if not completed[req] then return false end
    end
    return true
end

-- ── NUI ──────────────────────────────────────────────────────────────────────

local function openTree()
    if treeOpen then return end
    treeOpen = true
    SetNuiFocus(true, true)

    local skillData = {}
    for _, skill in ipairs(Config.Skills) do
        table.insert(skillData, {
            id        = skill.id,
            label     = skill.label,
            desc      = skill.desc,
            tier      = skill.tier,
            reward    = skill.reward,
            unlocks   = skill.unlocks,
            completed = completed[skill.id] or false,
            available = canUnlock(skill),
            requires  = skill.requires,
        })
    end
    SendNUIMessage({ action='open', skills=skillData, taskCount=taskCount })
end

local function closeTree()
    treeOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
end

RegisterNUICallback('close', function(_, cb) cb({}); closeTree() end)

RegisterNUICallback('complete', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-skilltree:complete', data.id)
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    cb({})
    if data.x and data.y then
        SetNewWaypoint(data.x, data.y)
        notify('Waypoint set!', 'info')
    end
end)

-- ── Server events ─────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-skilltree:update')
AddEventHandler('eonexis-skilltree:update', function(comp, tasks)
    completed = comp or {}
    taskCount = tasks or 0
    refreshQuestBlips()
    if treeOpen then
        -- Re-send updated skill list
        local skillData = {}
        for _, skill in ipairs(Config.Skills) do
            table.insert(skillData, {
                id        = skill.id,
                label     = skill.label,
                desc      = skill.desc,
                tier      = skill.tier,
                reward    = skill.reward,
                unlocks   = skill.unlocks,
                completed = completed[skill.id] or false,
                available = canUnlock(skill),
                requires  = skill.requires,
            })
        end
        SendNUIMessage({ action='open', skills=skillData, taskCount=taskCount })
    end
    -- Export quest list for phone
    TriggerEvent('eonexis-skilltree:localUpdate', completed, taskCount)
end)

RegisterNetEvent('eonexis-skilltree:completed')
AddEventHandler('eonexis-skilltree:completed', function(skill)
    completed[skill.id] = true
    refreshQuestBlips()
    notify(string.format('✓ "%s" complete! +$%d\nUnlocked: %s',
        skill.label,
        skill.reward and skill.reward.cash or 0,
        skill.unlocks or ''), 'success')
end)

-- ── Command + key binding ─────────────────────────────────────────────────────

RegisterKeyMapping('skilltree', 'Open Skill Tree', 'keyboard', 'F5')
RegisterCommand('skilltree', function()
    if treeOpen then closeTree() else openTree() end
end, false)

RegisterCommand('resetui', function()
    if treeOpen then
        print('[eonexis-skilltree] /resetui: force-closing skill tree')
        closeTree()
    end
end, false)

TriggerEvent('chat:addSuggestion', '/skilltree', 'Open the Eonexis Skill Tree')
TriggerEvent('chat:addSuggestion', '/resetui', 'Emergency: close all menus if you are stuck')

-- ── Trigger completions from world events ─────────────────────────────────────

-- Detect /rules opened
AddEventHandler('eonexis-rules:opened', function()
    TriggerServerEvent('eonexis-skilltree:complete', 'check_rules')
end)

-- Detect /balance used
AddEventHandler('eonexis-economy:balanceChecked', function()
    TriggerServerEvent('eonexis-skilltree:complete', 'check_balance')
end)

-- Detect phone opened
AddEventHandler('eonexis-phone:opened', function()
    TriggerServerEvent('eonexis-skilltree:complete', 'open_phone')
end)

-- ── Init ─────────────────────────────────────────────────────────────────────

CreateThread(function()
    Wait(3000)
    TriggerServerEvent('eonexis-skilltree:requestData')
    Wait(2000)
    -- Show tutorial hint on first join
    if not completed['check_rules'] then
        notify('New to Eonexis? Press F5 to open your Skill Tree and start your journey!', 'info')
    end
end)

AddEventHandler('eonexis-ui:scaleChanged', function(v)
    SendNUIMessage({ action = 'setScale', scale = v })
end)
