-- eonexis-admintools — server

local bannedLicenses = {}   -- { [license] = { reason, by, at } }
local persistentAdmins = {}  -- { [license] = playerName }
local BANS_FILE = 'data/bans.json'

local function loadBans()
    local raw = LoadResourceFile(GetCurrentResourceName(), BANS_FILE)
    if raw and #raw > 2 then
        local ok, parsed = pcall(json.decode, raw)
        if ok and parsed then bannedLicenses = parsed end
    end
end

local function saveBans()
    SaveResourceFile(GetCurrentResourceName(), BANS_FILE, json.encode(bannedLicenses), -1)
end

loadBans()

local function loadAdmins()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.AdminDataFile)
    if raw and #raw > 2 then
        local ok, parsed = pcall(json.decode, raw)
        if ok and parsed then persistentAdmins = parsed end
    end
end

local function saveAdmins()
    SaveResourceFile(GetCurrentResourceName(), Config.AdminDataFile, json.encode(persistentAdmins), -1)
end

loadAdmins()

local function getIdentifier(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if license and license ~= '' then return license end
    local steam = GetPlayerIdentifierByType(src, 'steam')
    if steam and steam ~= '' then return steam end
    return GetPlayerIdentifier(src, 0)
end

local function isAdmin(src)
    if Config.AllowServerOwner then
        if IsPlayerAceAllowed(src, 'command') then return true end
    end
    local license = getIdentifier(src)
    if license then
        for _, a in ipairs(Config.Admins) do
            if a == license then return true end
        end
        if persistentAdmins[license] then return true end
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

-- /claimadmin <password> — one-time setup to add yourself as persistent admin
RegisterCommand('claimadmin', function(src, args)
    if args[1] ~= Config.ClaimAdminPassword then
        notify(src, 'Wrong password.', 'error')
        return
    end
    local license = getIdentifier(src)
    if not license then notify(src, 'Could not read your identifier.', 'error'); return end
    if persistentAdmins[license] then
        notify(src, 'You are already a saved admin.', 'info')
        return
    end
    persistentAdmins[license] = GetPlayerName(src)
    saveAdmins()
    notify(src, 'Admin access granted! You now have full admin powers.', 'success')
    print('[eonexis-admintools] Admin claimed by ' .. GetPlayerName(src) .. ' (' .. license .. ')')
end, false)

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
    local license = getIdentifier(target)
    local reason = table.concat(args, ' ', 2) ~= '' and table.concat(args, ' ', 2) or 'Banned by admin'
    if license then
        bannedLicenses[license] = { reason=reason, by=GetPlayerName(src), at=os.date('%Y-%m-%d %H:%M:%S') }
        saveBans()
    end
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
        local ban = bannedLicenses[license]
        local msg = type(ban) == 'table' and ('You are banned: ' .. ban.reason) or 'You are banned from this server.'
        deferrals.done(msg)
    else
        deferrals.done()
    end
end)

-- /tp <id|name>
RegisterCommand('tp', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    TriggerClientEvent('eonexis-admintools:tpTo', src, target)
end, true)

-- /bring <id|name>
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

-- /god
RegisterCommand('god', function(src)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    TriggerClientEvent('eonexis-admintools:toggleGod', src)
end, true)

-- /noclip
RegisterCommand('noclip', function(src)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    TriggerClientEvent('eonexis-admintools:toggleNoclip', src)
end, true)

-- /players
RegisterCommand('players', function(src)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local list = {}
    for _, p in ipairs(GetPlayers()) do
        table.insert(list, string.format('[%s] %s', p, GetPlayerName(p)))
    end
    notify(src, table.concat(list, ', '), 'info')
end, true)

-- /admins
RegisterCommand('admins', function(src)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local list = {}
    for _, name in pairs(persistentAdmins) do table.insert(list, name) end
    notify(src, 'Saved admins: ' .. (#list > 0 and table.concat(list, ', ') or 'none'), 'info')
end, true)

-- /givemoney <id|name> <amount>
RegisterCommand('givemoney', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    local amount = tonumber(args[2])
    if not target or not amount or amount <= 0 then notify(src, 'Usage: /givemoney <id/name> <amount>', 'error'); return end
    local ok = pcall(function()
        exports['eonexis-economy']:addMoney(target, amount, 'admin give: ' .. GetPlayerName(src))
    end)
    if ok then
        notify(src, string.format('Gave $%d to %s.', amount, GetPlayerName(target)), 'success')
        notify(target, string.format('Admin gave you $%d.', amount), 'info')
    else
        notify(src, 'Economy mod not loaded.', 'error')
    end
end, true)

-- /setmoney <id|name> <amount>
RegisterCommand('setmoney', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    local amount = tonumber(args[2])
    if not target or not amount then notify(src, 'Usage: /setmoney <id/name> <amount>', 'error'); return end
    local ok = pcall(function()
        local cur = exports['eonexis-economy']:getMoney(target)
        if cur > amount then
            exports['eonexis-economy']:removeMoney(target, cur - amount, 'admin set')
        else
            exports['eonexis-economy']:addMoney(target, amount - cur, 'admin set')
        end
    end)
    if ok then notify(src, string.format('Set %s cash to $%d.', GetPlayerName(target), amount), 'success') end
end, true)

-- /removemoney <id|name> <amount>
RegisterCommand('removemoney', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    local amount = tonumber(args[2])
    if not target or not amount or amount <= 0 then notify(src, 'Usage: /removemoney <id/name> <amount>', 'error'); return end
    pcall(function() exports['eonexis-economy']:removeMoney(target, amount, 'admin remove') end)
    notify(src, string.format('Removed $%d from %s.', amount, GetPlayerName(target)), 'success')
end, true)

-- /setjob <id|name> <job>
RegisterCommand('setjob', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    local job    = args[2]
    if not target or not job then notify(src, 'Usage: /setjob <id/name> <job>', 'error'); return end
    pcall(function() exports['eonexis-economy']:setJob(target, job) end)
    notify(src, string.format('Set %s job to %s.', GetPlayerName(target), job), 'success')
    notify(target, string.format('Admin set your job to %s.', job), 'info')
end, true)

-- /checkwallet <id|name>
RegisterCommand('checkwallet', function(src, args)
    if not isAdmin(src) then notify(src, 'No permission.', 'error'); return end
    local target = findPlayer(args[1])
    if not target then notify(src, 'Player not found.', 'error'); return end
    local ok, data = pcall(function() return exports['eonexis-economy']:getPlayerData(target) end)
    if ok and data then
        notify(src, string.format('%s — Cash: $%d  Bank: $%d  Job: %s',
            GetPlayerName(target), data.cash, data.bank, data.job), 'info')
    end
end, true)

TriggerEvent('chat:addSuggestion', '/claimadmin',   'Claim admin access with password', {{ name='password', help='Admin password' }})
TriggerEvent('chat:addSuggestion', '/kick',         'Kick a player', {{ name='id/name', help='ID or name' }, { name='reason', help='Reason' }})
TriggerEvent('chat:addSuggestion', '/ban',          'Ban a player',  {{ name='id/name', help='ID or name' }, { name='reason', help='Reason' }})
TriggerEvent('chat:addSuggestion', '/tp',           'Teleport to player', {{ name='id/name', help='ID or name' }})
TriggerEvent('chat:addSuggestion', '/bring',        'Bring player to you', {{ name='id/name', help='ID or name' }})
TriggerEvent('chat:addSuggestion', '/freeze',       'Freeze a player', {{ name='id/name', help='ID or name' }})
TriggerEvent('chat:addSuggestion', '/god',          'Toggle god mode', {})
TriggerEvent('chat:addSuggestion', '/noclip',       'Toggle noclip', {})
TriggerEvent('chat:addSuggestion', '/players',      'List online players', {})
TriggerEvent('chat:addSuggestion', '/admins',       'List saved admins', {})
TriggerEvent('chat:addSuggestion', '/givemoney',    'Give money to player', {{ name='id/name', help='ID or name' }, { name='amount', help='Amount' }})
TriggerEvent('chat:addSuggestion', '/setmoney',     'Set player cash', {{ name='id/name', help='ID or name' }, { name='amount', help='Amount' }})
TriggerEvent('chat:addSuggestion', '/removemoney',  'Remove money from player', {{ name='id/name', help='ID or name' }, { name='amount', help='Amount' }})
TriggerEvent('chat:addSuggestion', '/setjob',       'Set player job', {{ name='id/name', help='ID or name' }, { name='job', help='Job ID' }})
TriggerEvent('chat:addSuggestion', '/checkwallet',  'Check player wallet', {{ name='id/name', help='ID or name' }})
