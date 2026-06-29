-- eonexis-police — server

local cuffed     = {}   -- { [src] = true }
local jailed     = {}   -- { [src] = { until=os.time() } }
local wantedLvl  = {}   -- { [license] = { stars, lastCrime } }
local onDuty     = {}   -- { [src] = true }

local function getLicense(src)
    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
end

local function notify(src, msg, t)
    exports['eonexis-notify']:Notify(GetPlayerName(src), msg, t or 'info', 5000)
end

local function isPolice(src)
    return exports['eonexis-economy']:getJob(src) == Config.Job
end

local function findPlayer(idOrName)
    local id = tonumber(idOrName)
    if id and GetPlayerName(id) then return id end
    for _, p in ipairs(GetPlayers()) do
        if GetPlayerName(p):lower():find(tostring(idOrName):lower(), 1, true) then
            return tonumber(p)
        end
    end
end

-- ── Duty toggle ──────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-police:setDuty')
AddEventHandler('eonexis-police:setDuty', function(active)
    local src = source
    if not isPolice(src) then return end
    if active then
        onDuty[src] = true
        TriggerClientEvent('eonexis-police:dutyOn', src)
        notify(src, '🚔 On duty. /cuff /jail /911 available.', 'success')
    else
        onDuty[src] = nil
        TriggerClientEvent('eonexis-police:dutyOff', src)
        notify(src, 'Off duty.', 'info')
    end
    -- Broadcast officer list update
    TriggerClientEvent('eonexis-police:officerUpdate', -1, getOnDutyList())
end)

function getOnDutyList()
    local list = {}
    for src in pairs(onDuty) do
        if GetPlayerName(src) then
            table.insert(list, { id=src, name=GetPlayerName(src) })
        end
    end
    return list
end

-- /duty — go on/off duty
RegisterCommand('duty', function(src)
    if not isPolice(src) then notify(src, 'Police only.', 'error'); return end
    if onDuty[src] then
        TriggerNetEvent('eonexis-police:setDuty', false)
    else
        TriggerEvent('eonexis-police:setDuty', false)  -- handled via event with correct source
    end
    onDuty[src] = not onDuty[src]
    if onDuty[src] then
        TriggerClientEvent('eonexis-police:dutyOn', src)
        notify(src, '🚔 On duty.', 'success')
    else
        TriggerClientEvent('eonexis-police:dutyOff', src)
        notify(src, 'Off duty.', 'info')
    end
    TriggerClientEvent('eonexis-police:officerUpdate', -1, getOnDutyList())
end, false)

-- ── Cuff ─────────────────────────────────────────────────────────────────────

RegisterCommand('cuff', function(src, args)
    if not isPolice(src) then notify(src, 'Police only.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    if cuffed[target] then
        -- Uncuff
        cuffed[target] = nil
        TriggerClientEvent('eonexis-police:uncuffed', target)
        notify(src, 'Uncuffed ' .. GetPlayerName(target), 'info')
        notify(target, 'You have been uncuffed.', 'info')
    else
        cuffed[target] = true
        TriggerClientEvent('eonexis-police:cuffed', target, src)
        notify(src, 'Cuffed ' .. GetPlayerName(target), 'success')
        notify(target, ('You have been cuffed by %s.'):format(GetPlayerName(src)), 'warning')
    end
end, false)

-- /uncuff <id>
RegisterCommand('uncuff', function(src, args)
    if not isPolice(src) then notify(src, 'Police only.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    cuffed[target] = nil
    TriggerClientEvent('eonexis-police:uncuffed', target)
    notify(src, 'Uncuffed ' .. GetPlayerName(target), 'info')
    notify(target, 'Released from cuffs.', 'info')
end, false)

-- ── Jail ─────────────────────────────────────────────────────────────────────

RegisterCommand('jail', function(src, args)
    if not isPolice(src) then notify(src, 'Police only.', 'error'); return end
    local target = findPlayer(args[1])
    local mins   = tonumber(args[2]) or 5
    if not target then notify(src, 'Player not found.', 'error'); return end
    mins = math.max(1, math.min(mins, 60))
    cuffed[target] = nil  -- uncuff if cuffed
    jailed[target] = { until_t = os.time() + mins * 60 }
    wantedLvl[getLicense(target)] = nil  -- clear wanted
    TriggerClientEvent('eonexis-police:jailed', target, Config.JailPos, Config.JailHeading, mins)
    TriggerClientEvent('eonexis-police:clearWanted', target)
    notify(src, ('Jailed %s for %d minutes.'):format(GetPlayerName(target), mins), 'success')
    notify(target, ('You have been jailed for %d minutes.'):format(mins), 'error')
    print(('[police] %s jailed %s for %dm'):format(GetPlayerName(src), GetPlayerName(target), mins))
end, false)

-- /unjail <id>
RegisterCommand('unjail', function(src, args)
    if not isPolice(src) then notify(src, 'Police only.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    jailed[target] = nil
    TriggerClientEvent('eonexis-police:released', target)
    notify(src, 'Released ' .. GetPlayerName(target), 'info')
    notify(target, 'You have been released from jail.', 'success')
end, false)

-- ── 911 calls ─────────────────────────────────────────────────────────────────

RegisterCommand('911', function(src, args)
    local msg = table.concat(args, ' ')
    if #msg < 3 then notify(src, 'Usage: /911 <message>', 'error'); return end
    local name = GetPlayerName(src)
    -- Notify all online police
    local notified = 0
    for pid in pairs(onDuty) do
        notify(pid, ('🚨 911 from %s: %s'):format(name, msg), 'warning')
        notified = notified + 1
    end
    if notified == 0 then
        notify(src, '911 call sent. No officers currently on duty.', 'info')
    else
        notify(src, ('911 call sent to %d officer(s).'):format(notified), 'success')
    end
    print(('[police] 911 from %s: %s'):format(name, msg))
end, false)

-- ── Police radio ─────────────────────────────────────────────────────────────

RegisterCommand('radio', function(src, args)
    if not isPolice(src) then notify(src, 'Police only.', 'error'); return end
    local msg = table.concat(args, ' ')
    if #msg < 1 then notify(src, 'Usage: /radio <message>', 'error'); return end
    local formatted = ('[RADIO] [%s] %s'):format(GetPlayerName(src), msg)
    for pid in pairs(onDuty) do
        TriggerClientEvent('chat:addMessage', pid, {
            color = {100, 180, 255}, multiline = true, args = {'', formatted}
        })
    end
end, false)

-- ── Wanted level ─────────────────────────────────────────────────────────────

AddEventHandler('eonexis-police:addWanted', function(src, stars)
    local lic = getLicense(src)
    local w = wantedLvl[lic] or { stars=0, lastCrime=0 }
    w.stars = math.min(5, (w.stars or 0) + stars)
    w.lastCrime = os.time()
    wantedLvl[lic] = w
    TriggerClientEvent('eonexis-police:updateWanted', src, w.stars)
    -- Alert all on-duty officers of high-level wanted
    if w.stars >= 3 then
        for pid in pairs(onDuty) do
            notify(pid, ('🚨 %s — Wanted Level %d!'):format(GetPlayerName(src), w.stars), 'warning')
        end
    end
end)

-- Decay wanted level
CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        for lic, w in pairs(wantedLvl) do
            if w.stars > 0 and (now - w.lastCrime) >= Config.WantedDecay then
                w.stars = math.max(0, w.stars - 1)
                w.lastCrime = now
                -- Find player online to update their HUD
                for _, pid in ipairs(GetPlayers()) do
                    local p = tonumber(pid)
                    if getLicense(p) == lic then
                        TriggerClientEvent('eonexis-police:updateWanted', p, w.stars)
                        break
                    end
                end
                if w.stars == 0 then wantedLvl[lic] = nil end
            end
        end
    end
end)

-- ── Exports ──────────────────────────────────────────────────────────────────

exports('isCuffed', function(src) return cuffed[src] == true end)
exports('isJailed', function(src) return jailed[src] ~= nil end)
exports('getWanted', function(src) local w = wantedLvl[getLicense(src)]; return w and w.stars or 0 end)
exports('isPoliceOnDuty', function(src) return onDuty[src] == true end)
exports('getOfficers', getOnDutyList)

AddEventHandler('playerDropped', function()
    local src = source
    cuffed[src] = nil
    jailed[src] = nil
    onDuty[src] = nil
    TriggerClientEvent('eonexis-police:officerUpdate', -1, getOnDutyList())
end)

TriggerEvent('chat:addSuggestion', '/duty',   'Toggle police duty status', {})
TriggerEvent('chat:addSuggestion', '/cuff',   'Cuff/uncuff a player', {{ name='id/name', help='Target' }})
TriggerEvent('chat:addSuggestion', '/uncuff', 'Uncuff a player', {{ name='id/name', help='Target' }})
TriggerEvent('chat:addSuggestion', '/jail',   'Jail a player', {{ name='id/name', help='Target' }, { name='minutes', help='Duration' }})
TriggerEvent('chat:addSuggestion', '/unjail', 'Release from jail', {{ name='id/name', help='Target' }})
TriggerEvent('chat:addSuggestion', '/911',    'Call the police', {{ name='message', help='Emergency message' }})
TriggerEvent('chat:addSuggestion', '/radio',  'Police radio (officers only)', {{ name='message', help='Message' }})

print('[eonexis-police] loaded — ' .. #Config.Stations .. ' stations, jail at Bolingbroke')
