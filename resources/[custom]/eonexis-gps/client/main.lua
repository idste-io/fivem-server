-- eonexis-gps — client: add minimap blips for all server POIs

CreateThread(function()
    Wait(3000) -- wait for world to load

    for _, b in ipairs(Config.Blips) do
        local blip = AddBlipForCoord(b.x, b.y, b.z)
        SetBlipSprite(blip, b.sprite)
        SetBlipColour(blip, b.colour)
        SetBlipScale(blip, b.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(b.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- GPS waypoint setter (called from phone NUI via eonexis-phone:setWaypoint)
AddEventHandler('eonexis-gps:setWaypoint', function(x, y)
    SetNewWaypoint(x / 8192.0 + 0.5, y / 8192.0 * -1.0 + 0.5)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('GPS', 'Waypoint set!', 'success', 3000)
    end
end)

-- Export for phone to get GPS blip list
exports('getGPSLocations', function()
    local locs = {}
    for _, b in ipairs(Config.Blips) do
        table.insert(locs, { label=b.label, x=b.x, y=b.y })
    end
    return locs
end)
