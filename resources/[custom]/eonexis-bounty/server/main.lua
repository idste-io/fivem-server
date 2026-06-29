-- eonexis-bounty — server

local bounties = {}  -- { [targetLicense] = { placer, amount, expires, targetName } }

local function getLicense(src)
    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
end

local function notify(src, msg, t)
    exports['eonexis-notify']:Notify(GetPlayerName(src), msg, t or 'info', 5000)
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

-- /setbounty <id|name> <amount>
RegisterCommand('setbounty', function(src, args)
    local target = findPlayer(args[1])
    local amount = tonumber(args[2])
    if not target or not amount or amount < Config.MinBounty then
        notify(src, ('Usage: /setbounty <id/name> <amount> (min $%d)'):format(Config.MinBounty), 'error'); return
    end
    if amount > Config.MaxBounty then
        notify(src, ('Max bounty is $%d.'):format(Config.MaxBounty), 'error'); return
    end
    if target == src then
        notify(src, "Can't bounty yourself.", 'error'); return
    end

    local tLic = getLicense(target)
    local existing = bounties[tLic]

    if not exports['eonexis-economy']:removeMoney(src, amount, 'bounty placed') then
        notify(src, 'Not enough cash.', 'error'); return
    end

    if existing then
        -- Top up existing bounty
        existing.amount = existing.amount + amount
        existing.expires = os.time() + Config.BountyDuration
        notify(src, ('Added $%d to bounty on %s. Total: $%d.'):format(amount, GetPlayerName(target), existing.amount), 'success')
    else
        bounties[tLic] = {
            placer = getLicense(src),
            amount = amount,
            expires = os.time() + Config.BountyDuration,
            targetName = GetPlayerName(target),
        }
        notify(src, ('$%d bounty placed on %s!'):format(amount, GetPlayerName(target)), 'success')
    end

    -- Announce to all
    TriggerClientEvent('eonexis-bounty:announced', -1, GetPlayerName(target), bounties[tLic].amount)
    print(('[bounty] %s placed $%d bounty on %s'):format(GetPlayerName(src), amount, GetPlayerName(target)))
end, false)

-- /bounties — list active bounties
RegisterCommand('bounties', function(src)
    local now = os.time()
    local list = {}
    for lic, b in pairs(bounties) do
        if b.expires > now then
            table.insert(list, ('%-20s $%d'):format(b.targetName, b.amount))
        end
    end
    if #list == 0 then
        notify(src, 'No active bounties.', 'info')
    else
        notify(src, 'Active Bounties:\n' .. table.concat(list, '\n'), 'info')
    end
end, false)

-- Player killed — check if target had a bounty
AddEventHandler('playerDied', function()
    -- Not a reliable native event; use eonexis-police:playerKilled instead
end)

RegisterNetEvent('eonexis-bounty:playerKilled')
AddEventHandler('eonexis-bounty:playerKilled', function(killedSrc)
    local killer = source
    local tLic = getLicense(killedSrc)
    local b = bounties[tLic]
    if not b then return end
    if b.expires < os.time() then bounties[tLic] = nil; return end

    local reward = b.amount
    bounties[tLic] = nil
    exports['eonexis-economy']:addMoney(killer, reward, 'bounty collected')
    notify(killer, ('💰 Bounty collected! +$%d'):format(reward), 'success')
    TriggerClientEvent('eonexis-bounty:collected', -1, GetPlayerName(killer), GetPlayerName(killedSrc), reward)
    print(('[bounty] %s collected $%d bounty on %s'):format(GetPlayerName(killer), reward, GetPlayerName(killedSrc)))
end)

-- Expire old bounties periodically
CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        for lic, b in pairs(bounties) do
            if b.expires <= now then bounties[lic] = nil end
        end
    end
end)

-- Send bounty list to client on request
RegisterNetEvent('eonexis-bounty:requestList')
AddEventHandler('eonexis-bounty:requestList', function()
    local now = os.time()
    local list = {}
    for lic, b in pairs(bounties) do
        if b.expires > now then
            table.insert(list, { lic=lic, name=b.targetName, amount=b.amount, expires=b.expires })
        end
    end
    TriggerClientEvent('eonexis-bounty:receiveList', source, list)
end)

exports('hasBounty', function(src)
    local b = bounties[getLicense(src)]
    return b ~= nil and b.expires > os.time()
end)

exports('getBountyAmount', function(src)
    local b = bounties[getLicense(src)]
    if b and b.expires > os.time() then return b.amount end
    return 0
end)

TriggerEvent('chat:addSuggestion', '/setbounty', 'Place a bounty on a player', {{ name='id/name', help='Target' }, { name='amount', help='Amount' }})
TriggerEvent('chat:addSuggestion', '/bounties',  'List all active bounties', {})
