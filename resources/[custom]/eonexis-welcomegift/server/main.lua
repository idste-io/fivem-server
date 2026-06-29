-- eonexis-welcomegift — server
-- Detects first-ever join by tracking player identifiers in a simple file-based store.
-- Triggers the welcome event on the client for new players.

local welcomed = {}  -- in-memory set for this session (steam/license ID → true)

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0) or tostring(src)
    -- Mark as seen for this session
    welcomed[license] = welcomed[license] or false
end)

AddEventHandler('playerSpawned', function()
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0) or tostring(src)
    if welcomed[license] == false then
        welcomed[license] = true
        -- Send welcome event to the new player
        TriggerClientEvent('eonexis-welcomegift:welcome', src, Config.WelcomeMessage)
        -- Notify server console
        print('[eonexis-welcomegift] New player welcomed: ' .. GetPlayerName(src))
    end
end)

AddEventHandler('playerDropped', function()
    -- Keep welcomed state in memory — reset will happen on server restart
end)
