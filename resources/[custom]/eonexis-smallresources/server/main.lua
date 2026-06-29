-- eonexis-smallresources — server

RegisterNetEvent('eonexis-smallresources:afkKick')
AddEventHandler('eonexis-smallresources:afkKick', function()
    local src = source
    -- Exempt players whose job is in the exempt list
    local ok, job = pcall(function() return exports['eonexis-economy']:getJob(src) end)
    if ok and job then
        for _, exempt in ipairs(Config.AfkKick.exempt) do
            if job == exempt then return end
        end
    end
    local name = GetPlayerName(src)
    DropPlayer(src, 'Kicked for AFK inactivity (5 minutes idle).')
    print(('[smallresources] AFK kicked: %s (%d)'):format(name, src))
end)
