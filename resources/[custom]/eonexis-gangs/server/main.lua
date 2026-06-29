-- eonexis-gangs — server

local DATA_FILE = 'data/gangs.json'
local gangs = {}       -- { [gangName] = { name, leader, members={license,...}, stash=0, territories={...} } }
local playerGang = {}  -- { [license] = gangName }
local territoryOwner = {}  -- { [territoryId] = gangName }

local function loadDB()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if raw and #raw > 2 then
        local ok, parsed = pcall(json.decode, raw)
        if ok and parsed then
            gangs = parsed.gangs or {}
            territoryOwner = parsed.territoryOwner or {}
            -- Rebuild playerGang index
            for name, g in pairs(gangs) do
                for _, lic in ipairs(g.members) do
                    playerGang[lic] = name
                end
            end
        end
    end
end

local function saveDB()
    local ok, encoded = pcall(json.encode, { gangs=gangs, territoryOwner=territoryOwner })
    if ok then SaveResourceFile(GetCurrentResourceName(), DATA_FILE, encoded, -1) end
end

loadDB()

local function getLicense(src)
    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
end

local function notify(src, msg, t)
    exports['eonexis-notify']:Notify(GetPlayerName(src), msg, t or 'info', 5000)
end

local function getPlayerGang(src)
    return playerGang[getLicense(src)]
end

-- ── Commands ────────────────────────────────────────────────────────────────

RegisterCommand('gang', function(src, args)
    local sub = args[1] and args[1]:lower()

    if sub == 'create' then
        local name = args[2]
        if not name or #name < 2 or #name > 20 then
            notify(src, 'Usage: /gang create <name> (2-20 chars)', 'error'); return
        end
        if getPlayerGang(src) then
            notify(src, 'Leave your current gang first.', 'error'); return
        end
        if gangs[name] then
            notify(src, 'A gang with that name already exists.', 'error'); return
        end
        if not exports['eonexis-economy']:removeMoney(src, Config.CreateCost, 'gang creation') then
            notify(src, ('Need $%d to create a gang.'):format(Config.CreateCost), 'error'); return
        end
        local lic = getLicense(src)
        gangs[name] = { name=name, leader=lic, members={lic}, stash=0, territories={} }
        playerGang[lic] = name
        saveDB()
        notify(src, ('🤝 Gang "%s" created! You are the leader.'):format(name), 'success')
        TriggerClientEvent('eonexis-gangs:updateData', src, gangs[name])

    elseif sub == 'join' then
        local name = args[2]
        if not name or not gangs[name] then
            notify(src, 'Gang not found.', 'error'); return
        end
        if getPlayerGang(src) then
            notify(src, 'Leave your current gang first.', 'error'); return
        end
        if #gangs[name].members >= Config.MaxMembers then
            notify(src, 'That gang is full.', 'error'); return
        end
        local lic = getLicense(src)
        table.insert(gangs[name].members, lic)
        playerGang[lic] = name
        saveDB()
        notify(src, ('Joined gang "%s".'):format(name), 'success')
        -- Notify online gang members
        for _, pid in ipairs(GetPlayers()) do
            local p = tonumber(pid)
            if playerGang[getLicense(p)] == name and p ~= src then
                notify(p, (GetPlayerName(src) .. ' joined your gang!'), 'info')
            end
        end
        TriggerClientEvent('eonexis-gangs:updateData', src, gangs[name])

    elseif sub == 'leave' then
        local gname = getPlayerGang(src)
        if not gname then notify(src, 'You are not in a gang.', 'error'); return end
        local lic = getLicense(src)
        local g = gangs[gname]
        if g.leader == lic and #g.members > 1 then
            notify(src, 'Transfer leadership first (/gang promote <name>).', 'error'); return
        end
        for i, l in ipairs(g.members) do
            if l == lic then table.remove(g.members, i); break end
        end
        playerGang[lic] = nil
        if #g.members == 0 then
            gangs[gname] = nil  -- disband empty gang
        end
        saveDB()
        notify(src, 'Left the gang.', 'info')
        TriggerClientEvent('eonexis-gangs:clearData', src)

    elseif sub == 'info' then
        local gname = args[2] or getPlayerGang(src)
        if not gname or not gangs[gname] then
            notify(src, 'Usage: /gang info [name]', 'error'); return
        end
        local g = gangs[gname]
        notify(src, ('Gang: %s | Members: %d/%d | Stash: $%d'):format(
            g.name, #g.members, Config.MaxMembers, g.stash), 'info')

    elseif sub == 'promote' then
        local target = findOnlineMember(src, args[2])
        if not target then notify(src, 'Player not found in your gang.', 'error'); return end
        local gname = getPlayerGang(src)
        local g = gangs[gname]
        if g.leader ~= getLicense(src) then notify(src, 'Leader only.', 'error'); return end
        g.leader = getLicense(target)
        saveDB()
        notify(src, 'Leadership transferred.', 'success')
        notify(target, ('You are now leader of %s!'):format(gname), 'success')

    elseif sub == 'stash' then
        -- Show stash balance
        local gname = getPlayerGang(src)
        if not gname then notify(src, 'Not in a gang.', 'error'); return end
        notify(src, ('Gang stash: $%d'):format(gangs[gname].stash), 'info')

    elseif sub == 'deposit' then
        local amount = tonumber(args[2])
        if not amount or amount <= 0 then notify(src, 'Usage: /gang deposit <amount>', 'error'); return end
        local gname = getPlayerGang(src)
        if not gname then notify(src, 'Not in a gang.', 'error'); return end
        if not exports['eonexis-economy']:removeMoney(src, amount, 'gang deposit') then
            notify(src, 'Not enough cash.', 'error'); return
        end
        gangs[gname].stash = (gangs[gname].stash or 0) + amount
        saveDB()
        notify(src, ('Deposited $%d to gang stash.'):format(amount), 'success')

    elseif sub == 'withdraw' then
        local amount = tonumber(args[2])
        if not amount or amount <= 0 then notify(src, 'Usage: /gang withdraw <amount>', 'error'); return end
        local gname = getPlayerGang(src)
        if not gname then notify(src, 'Not in a gang.', 'error'); return end
        local g = gangs[gname]
        if g.leader ~= getLicense(src) then notify(src, 'Leader only.', 'error'); return end
        if (g.stash or 0) < amount then notify(src, 'Not enough in stash.', 'error'); return end
        g.stash = g.stash - amount
        exports['eonexis-economy']:addMoney(src, amount, 'gang withdrawal')
        saveDB()
        notify(src, ('Withdrew $%d from gang stash.'):format(amount), 'success')

    elseif sub == 'list' then
        local list = {}
        for name, g in pairs(gangs) do
            table.insert(list, ('%s (%d members)'):format(name, #g.members))
        end
        notify(src, #list > 0 and table.concat(list, ' | ') or 'No gangs yet.', 'info')

    else
        notify(src, 'Usage: /gang <create|join|leave|info|list|stash|deposit|withdraw|promote>', 'info')
    end
end, false)

function findOnlineMember(src, nameOrId)
    local gname = getPlayerGang(src)
    if not gname then return nil end
    for _, pid in ipairs(GetPlayers()) do
        local p = tonumber(pid)
        if playerGang[getLicense(p)] == gname and p ~= src then
            local pname = GetPlayerName(p)
            if tostring(p) == tostring(nameOrId) or pname:lower():find(tostring(nameOrId):lower(), 1, true) then
                return p
            end
        end
    end
end

-- Gang chat
RegisterNetEvent('eonexis-gangs:chat')
AddEventHandler('eonexis-gangs:chat', function(msg)
    local src = source
    local gname = getPlayerGang(src)
    if not gname then return end
    local formatted = ('[GANG] [%s] %s'):format(GetPlayerName(src), msg)
    for _, pid in ipairs(GetPlayers()) do
        local p = tonumber(pid)
        if playerGang[getLicense(p)] == gname then
            TriggerClientEvent('chat:addMessage', p, { color={255, 100, 100}, multiline=true, args={'', formatted} })
        end
    end
end)

-- Territory capture
RegisterNetEvent('eonexis-gangs:captureTerritory')
AddEventHandler('eonexis-gangs:captureTerritory', function(territoryId)
    local src = source
    local gname = getPlayerGang(src)
    if not gname then
        notify(src, 'Join a gang to capture territory.', 'error'); return
    end
    if territoryOwner[territoryId] == gname then
        notify(src, 'Your gang already owns this territory.', 'info'); return
    end
    local prev = territoryOwner[territoryId]
    territoryOwner[territoryId] = gname
    saveDB()
    -- Broadcast to all players
    TriggerClientEvent('eonexis-gangs:territoryUpdate', -1, territoryId, gname)
    notify(src, ('Territory captured for %s!'):format(gname), 'success')
    if prev then
        -- Notify losing gang members
        for _, pid in ipairs(GetPlayers()) do
            local p = tonumber(pid)
            if playerGang[getLicense(p)] == prev then
                notify(p, ('Your territory was captured by %s!'):format(gname), 'warning')
            end
        end
    end
    print(('[gangs] %s captured %s for gang %s'):format(GetPlayerName(src), territoryId, gname))
end)

-- Passive income tick
CreateThread(function()
    while true do
        Wait(Config.IncomeInterval * 1000)
        for territoryId, gname in pairs(territoryOwner) do
            if gangs[gname] then
                -- Find territory income
                for _, t in ipairs(Config.Territories) do
                    if t.id == territoryId then
                        gangs[gname].stash = (gangs[gname].stash or 0) + t.income
                        -- Notify online members
                        for _, pid in ipairs(GetPlayers()) do
                            local p = tonumber(pid)
                            if playerGang[getLicense(p)] == gname then
                                notify(p, ('Gang earned $%d from %s territory.'):format(t.income, t.name), 'success')
                            end
                        end
                        break
                    end
                end
            end
        end
        saveDB()
    end
end)

-- Send player their gang data on connect
RegisterNetEvent('eonexis-gangs:requestData')
AddEventHandler('eonexis-gangs:requestData', function()
    local src = source
    local gname = getPlayerGang(src)
    TriggerClientEvent('eonexis-gangs:initData', src, gname and gangs[gname] or nil, territoryOwner)
end)

-- Exports
exports('getPlayerGang', function(src) return getPlayerGang(src) end)
exports('isInGang', function(src) return getPlayerGang(src) ~= nil end)

AddEventHandler('playerDropped', function()
    -- playerGang stays populated (license-based), no cleanup needed
end)

print('[eonexis-gangs] loaded — ' .. (function()
    local c = 0; for _ in pairs(gangs) do c=c+1 end; return c
end)() .. ' gangs, ' .. #Config.Territories .. ' territories')
