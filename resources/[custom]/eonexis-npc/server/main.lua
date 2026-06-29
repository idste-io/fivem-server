-- Tracks which player is on which job for NPC coordination
local playerJobs = {}

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        for _, src in ipairs(GetPlayers()) do
            local job = exports['eonexis-economy']:getPlayerJob(tonumber(src))
            playerJobs[tonumber(src)] = job
        end
    end
end)

-- Keep playerJobs in sync
RegisterNetEvent('eonexis-npc:jobChanged')
AddEventHandler('eonexis-npc:jobChanged', function(job)
    playerJobs[source] = job
    TriggerClientEvent('eonexis-npc:refreshNPCs', -1, playerJobs)
end)

AddEventHandler('playerDropped', function()
    playerJobs[source] = nil
    TriggerClientEvent('eonexis-npc:refreshNPCs', -1, playerJobs)
end)

-- Broadcast current job map to a player on request
RegisterNetEvent('eonexis-npc:requestState')
AddEventHandler('eonexis-npc:requestState', function()
    TriggerClientEvent('eonexis-npc:refreshNPCs', source, playerJobs)
end)

-- Check if any real police player is on duty
exports('hasRealPolice', function()
    for _, src in ipairs(GetPlayers()) do
        if exports['eonexis-police']:isPoliceOnDuty(tonumber(src)) then
            return true
        end
    end
    return false
end)

-- Sync interval: broadcast state every 60s
CreateThread(function()
    while true do
        Wait(60000)
        TriggerClientEvent('eonexis-npc:refreshNPCs', -1, playerJobs)
    end
end)
