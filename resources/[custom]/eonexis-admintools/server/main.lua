-- eonexis-admintools — server

local bannedLicenses = {}  -- in-memory ban list (resets on server restart; extend with file I/O if needed)

local function isAdmin(src)
    if Config.AllowServerOwner then
        if IsPlayerAceAllowed(src, 'command') then return true end
    end
    local license = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
    for _, a in ipairs(Config.Admins) do
        if a == license then return true end
    end
    return false
end

local function notify(src, msg, t)
    TriggerClientEvent('eonexis-admintools:notify', src, msg, t or 'info')
end

local function findPlayer(idOrName)
    local id = tonumber(idOrName)
    if id and GetPlayerName(id) then return id end
    for _, p in ipairs(GetPlayers()) do
        if GetPlayerName(p):lower():find(tostring(idOrName):lower(), 1, true) then
            return tonumber(p)
        end
    end
    return nil
end

-- /kick <id|name> [reason]
RegisterCommand('kick', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    local reason = table.concat(args, ' ', 2) ~= '' and table.concat(args, ' ', 2) or 'Kicked by admin'
    DropPlayer(target, reason)
    notify(src, 'Kicked ' .. GetPlayerName(target), 'success')
end, true)

-- /ban <id|name> [reason]
RegisterCommand('ban', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    local license = GetPlayerIdentifierByType(target, 'license') or GetPlayerIdentifier(target, 0)
    if license then bannedLicenses[license] = true end
    local reason = table.concat(args, ' ', 2) ~= '' and table.concat(args, ' ', 2) or 'Banned by admin'
    DropPlayer(target, '[BANNED] ' .. reason)
    notify(src, 'Banned ' .. (GetPlayerName(target) or '?'), 'success')
    print('[eonexis-admintools] Banned: ' .. tostring(license) .. ' — ' .. reason)
end, true)

-- Check bans on connect
AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    local license = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
    if license and bannedLicenses[license] then
        deferrals.done('You are banned from this server.')
    else
        deferrals.done()
    end
end)

-- /tp <id|name> — teleport self to player
RegisterCommand('tp', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    TriggerClientEvent('eonexis-admintools:tpTo', src, target)
end, true)

-- /bring <id|name> — bring player to self
RegisterCommand('bring', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    TriggerClientEvent('eonexis-admintools:bringMe', target, src)
    notify(src, 'Bringing ' .. GetPlayerName(target), 'info')
end, true)

-- /freeze <id|name>
RegisterCommand('freeze', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    TriggerClientEvent('eonexis-admintools:freeze', target)
    notify(src, 'Toggled freeze on ' .. GetPlayerName(target), 'info')
end, true)

-- /god — toggle god mode for self
RegisterCommand('god', function(src)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    TriggerClientEvent('eonexis-admintools:toggleGod', src)
end, true)

-- /noclip — toggle noclip for self
RegisterCommand('noclip', function(src)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    TriggerClientEvent('eonexis-admintools:toggleNoclip', src)
end, true)

-- /players — list online players
RegisterCommand('players', function(src)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local list = {}
    for _, p in ipairs(GetPlayers()) do
        table.insert(list, string.format('[%s] %s', p, GetPlayerName(p)))
    end
    notify(src, table.concat(list, ', '), 'info')
end, true)

TriggerEvent('chat:addSuggestion', '/kick',    'Kick a player', {{ name='id/name', help='Player ID or name' }, { name='reason', help='Reason' }})
TriggerEvent('chat:addSuggestion', '/ban',     'Ban a player',  {{ name='id/name', help='Player ID or name' }, { name='reason', help='Reason' }})
TriggerEvent('chat:addSuggestion', '/tp',      'Teleport to player', {{ name='id/name', help='Player ID or name' }})
TriggerEvent('chat:addSuggestion', '/bring',   'Bring player to you', {{ name='id/name', help='Player ID or name' }})
TriggerEvent('chat:addSuggestion', '/freeze',  'Freeze a player', {{ name='id/name', help='Player ID or name' }})
TriggerEvent('chat:addSuggestion', '/god',     'Toggle god mode', {})
TriggerEvent('chat:addSuggestion', '/noclip',  'Toggle noclip',   {})
TriggerEvent('chat:addSuggestion', '/players', 'List online players', {})
