-- eonexis-bounty — client

local bountyMap = {}  -- { [license] = amount }

-- Refresh bounty list every 60s
CreateThread(function()
    while true do
        TriggerServerEvent('eonexis-bounty:requestList')
        Wait(60000)
    end
end)

RegisterNetEvent('eonexis-bounty:receiveList')
AddEventHandler('eonexis-bounty:receiveList', function(list)
    bountyMap = {}
    for _, b in ipairs(list) do
        bountyMap[b.lic] = b.amount
    end
end)

-- When server says a bounty was placed, show it on-screen
RegisterNetEvent('eonexis-bounty:announced')
AddEventHandler('eonexis-bounty:announced', function(targetName, amount)
    exports['eonexis-notify']:Notify('💀 Bounty', ('$%d on %s!'):format(amount, targetName), 'warning', 8000)
end)

-- Someone collected a bounty
RegisterNetEvent('eonexis-bounty:collected')
AddEventHandler('eonexis-bounty:collected', function(killer, target, reward)
    exports['eonexis-notify']:Notify('Bounty Collected', ('%s eliminated %s (+$%d)'):format(killer, target, reward), 'info', 6000)
end)

-- Detect player death and report to server for bounty check
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local isFatal  = args[4]
        if not isFatal then return end
        local ped = PlayerPedId()
        if victim ~= ped then return end
        if attacker == 0 or not IsPedAPlayer(attacker) then return end
        local playerIdx = NetworkGetPlayerIndexFromPed(attacker)
        if playerIdx == -1 then return end
        local attackerServerId = GetPlayerServerId(playerIdx)
        if attackerServerId and attackerServerId > 0 then
            TriggerServerEvent('eonexis-bounty:playerKilled', PlayerId())
        end
    end
end)

TriggerEvent('chat:addSuggestion', '/setbounty', 'Place bounty on player', {{ name='id/name', help='Target' }, { name='amount', help='Amount ($500+)' }})
TriggerEvent('chat:addSuggestion', '/bounties',  'List active bounties', {})
