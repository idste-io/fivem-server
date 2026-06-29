-- eonexis-spawn — server
-- Sends last-location and home-property spawn options to the client

RegisterNetEvent('eonexis-spawn:requestOptions')
AddEventHandler('eonexis-spawn:requestOptions', function()
    local src  = source
    local opts = {}

    -- Check economy for last location and home
    local ok, data = pcall(function()
        return exports['eonexis-economy']:getPlayerData(src)
    end)
    if not ok or not data then
        TriggerClientEvent('eonexis-spawn:extraOptions', src, opts)
        return
    end

    if data.lastLocation then
        table.insert(opts, {
            type  = 'lastLocation',
            label = 'Last Location',
            desc  = 'Spawn where you last logged off',
            x=data.lastLocation.x, y=data.lastLocation.y,
            z=data.lastLocation.z, h=data.lastLocation.h or 0,
        })
    end

    if data.homeProperty then
        -- Ask properties mod for the spawn coords
        local ok2, homeSpawn, homeLabel = pcall(function()
            return exports['eonexis-properties']:getHomeSpawn(src)
        end)
        if ok2 and homeSpawn then
            table.insert(opts, {
                type  = 'home',
                label = homeLabel or 'My Home',
                desc  = 'Spawn at your property',
                x=homeSpawn.x, y=homeSpawn.y, z=homeSpawn.z, h=homeSpawn.h or 0,
            })
        end
    end

    TriggerClientEvent('eonexis-spawn:extraOptions', src, opts)
end)
