-- eonexis-quests — client

local open      = false
local questData = {}   -- [questId] = { completed=bool, objectives={[objId]=bool} }
local activeLocation = nil  -- location objective being checked
local questBlips = {}  -- minimap blips for active location objectives

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Quest', msg, t or 'info', 6000)
    end
end

-- ── NUI ──────────────────────────────────────────────────────────────────────

local function openLog()
    if open then return end
    open = true
    SetNuiFocus(true, true)
    local payload = {}
    for _, q in ipairs(Config.Quests) do
        local state = questData[q.id] or { completed=false, objectives={} }
        local objs = {}
        for _, obj in ipairs(q.objectives) do
            table.insert(objs, {
                id        = obj.id,
                text      = obj.text,
                completed = state.objectives[obj.id] or false,
            })
        end
        -- Determine availability
        local available = true
        for _, req in ipairs(q.requires) do
            if not (questData[req] and questData[req].completed) then
                available = false; break
            end
        end
        table.insert(payload, {
            id        = q.id,
            title     = q.title,
            desc      = q.desc,
            category  = q.category,
            reward    = q.reward.cash,
            objectives= objs,
            completed = state.completed or false,
            available = available,
        })
    end
    SendNUIMessage({ action='open', quests=payload })
end

local function closeLog()
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action='close' })
end

RegisterNUICallback('close', function(_, cb) cb({}); closeLog() end)

RegisterNUICallback('waypoint', function(data, cb)
    cb({})
    if data.x and data.y then
        SetNewWaypoint(data.x, data.y)
        notify('Waypoint set!', 'info')
    end
end)

-- ── Key binding ───────────────────────────────────────────────────────────────

RegisterKeyMapping('questlog', 'Open Quest Log', 'keyboard', 'q')
RegisterCommand('questlog', function()
    if open then closeLog() else openLog() end
end, false)

TriggerEvent('chat:addSuggestion', '/questlog', 'Open your quest log (or press Q)')

-- ── Server sync ───────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-quests:sync')
AddEventHandler('eonexis-quests:sync', function(data)
    questData = data or {}
    if open then openLog() end  -- refresh UI
    refreshLocationTracking()
end)

RegisterNetEvent('eonexis-quests:objectiveComplete')
AddEventHandler('eonexis-quests:objectiveComplete', function(questId, objId, objText)
    if not questData[questId] then questData[questId] = { completed=false, objectives={} } end
    questData[questId].objectives[objId] = true
    notify(string.format('Objective done: %s', objText), 'success')
    if open then openLog() end
    refreshLocationTracking()
end)

RegisterNetEvent('eonexis-quests:questComplete')
AddEventHandler('eonexis-quests:questComplete', function(questId, questTitle, reward)
    if not questData[questId] then questData[questId] = { completed=false, objectives={} } end
    questData[questId].completed = true
    notify(string.format('Quest complete: "%s"\n+$%d reward!', questTitle, reward), 'success')
    if open then openLog() end
    refreshLocationTracking()
end)

-- ── Location tracking + blips ──────────────────────────────────────────────────

local function clearQuestBlips()
    for _, b in ipairs(questBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    questBlips = {}
end

function refreshLocationTracking()
    clearQuestBlips()
    activeLocation = nil
    for _, q in ipairs(Config.Quests) do
        local state = questData[q.id] or { completed=false, objectives={} }
        if not state.completed then
            -- Check availability
            local available = true
            for _, req in ipairs(q.requires) do
                if not (questData[req] and questData[req].completed) then
                    available = false; break
                end
            end
            if available then
                for _, obj in ipairs(q.objectives) do
                    if obj.trigger == 'location' and not state.objectives[obj.id] then
                        -- Add minimap blip
                        local b = AddBlipForCoord(obj.pos.x, obj.pos.y, obj.pos.z)
                        SetBlipSprite(b, 161); SetBlipColour(b, 2); SetBlipScale(b, 0.75)
                        SetBlipAsShortRange(b, true)
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentSubstringPlayerName('[Quest] ' .. q.title)
                        EndTextCommandSetBlipName(b)
                        table.insert(questBlips, b)

                        -- Set activeLocation to first pending one
                        if not activeLocation then
                            activeLocation = { questId=q.id, objId=obj.id, pos=obj.pos, radius=obj.radius }
                        end
                    end
                end
            end
        end
    end
end

-- Proximity check thread
CreateThread(function()
    while true do
        Wait(1000)
        if activeLocation then
            local ped = PlayerPedId()
            local px, py, pz = table.unpack(GetEntityCoords(ped))
            local lx, ly, lz = activeLocation.pos.x, activeLocation.pos.y, activeLocation.pos.z
            local dist = #(vector3(px,py,pz) - vector3(lx,ly,lz))
            if dist < activeLocation.radius then
                local qId = activeLocation.questId
                local oId = activeLocation.objId
                TriggerServerEvent('eonexis-quests:completeObjective', qId, oId)
                activeLocation = nil
            end
        end
    end
end)

-- ── Event listeners for quest triggers ───────────────────────────────────────

AddEventHandler('eonexis-rules:opened', function()
    TriggerServerEvent('eonexis-quests:serverKey', 'rules_opened')
end)

AddEventHandler('eonexis-economy:balanceChecked', function()
    TriggerServerEvent('eonexis-quests:serverKey', 'balance_checked')
end)

AddEventHandler('eonexis-phone:opened', function()
    TriggerServerEvent('eonexis-quests:serverKey', 'phone_opened')
end)

-- Weapon check — detect when player equips a weapon for the first time
local weaponChecked = false
CreateThread(function()
    Wait(5000)
    while true do
        Wait(2000)
        if not weaponChecked then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= 0xA2719263 then  -- not unarmed
                TriggerServerEvent('eonexis-quests:serverKey', 'has_weapon')
                weaponChecked = true
            end
        end
    end
end)

-- ── Init ─────────────────────────────────────────────────────────────────────

CreateThread(function()
    Wait(4000)
    TriggerServerEvent('eonexis-quests:requestSync')
    Wait(2000)
    -- Show hint if no active quests
    local hasActive = false
    for _, q in ipairs(Config.Quests) do
        local state = questData[q.id]
        if state and not state.completed then hasActive = true; break end
    end
    if not hasActive then
        notify('Press Q to open your Quest Log and start earning!', 'info')
    end
end)
