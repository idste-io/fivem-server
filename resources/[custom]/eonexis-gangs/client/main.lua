-- eonexis-gangs — client

local myGang        = nil
local territoryOwners = {}
local capturing     = nil  -- { id, startTime }
local blips         = {}

local function drawZoneBlip(t, owner)
    if blips[t.id] then RemoveBlip(blips[t.id]) end
    local b = AddBlipForCoord(t.pos.x, t.pos.y, t.pos.z)
    SetBlipSprite(b, 112)
    SetBlipScale(b, 0.9)
    SetBlipAsShortRange(b, true)
    if owner and owner == myGang then
        SetBlipColour(b, 2)   -- green: ours
    elseif owner then
        SetBlipColour(b, 1)   -- red: enemy
    else
        SetBlipColour(b, 4)   -- blue: neutral
    end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(t.name .. (owner and (' [' .. owner .. ']') or ' [Unclaimed]'))
    EndTextCommandSetBlipName(b)
    blips[t.id] = b
end

-- Init from server
RegisterNetEvent('eonexis-gangs:initData')
AddEventHandler('eonexis-gangs:initData', function(gangData, terr)
    myGang = gangData and gangData.name or nil
    territoryOwners = terr or {}
    for _, t in ipairs(Config.Territories) do
        drawZoneBlip(t, territoryOwners[t.id])
    end
end)

RegisterNetEvent('eonexis-gangs:updateData')
AddEventHandler('eonexis-gangs:updateData', function(gangData)
    myGang = gangData and gangData.name or nil
end)

RegisterNetEvent('eonexis-gangs:clearData')
AddEventHandler('eonexis-gangs:clearData', function()
    myGang = nil
end)

RegisterNetEvent('eonexis-gangs:territoryUpdate')
AddEventHandler('eonexis-gangs:territoryUpdate', function(territoryId, gname)
    territoryOwners[territoryId] = gname
    for _, t in ipairs(Config.Territories) do
        if t.id == territoryId then
            drawZoneBlip(t, gname)
            if gname == myGang then
                exports['eonexis-notify']:Notify('Territory', 'Your gang captured ' .. t.name .. '!', 'success', 5000)
            elseif myGang and territoryOwners[territoryId] == myGang then
                exports['eonexis-notify']:Notify('Territory', t.name .. ' was lost to ' .. gname, 'error', 5000)
            end
            break
        end
    end
end)

-- Territory capture zone + prompt
CreateThread(function()
    TriggerNetEvent('eonexis-gangs:requestData')
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local sleep = 500

        for _, t in ipairs(Config.Territories) do
            local dist = #(pos - t.pos)
            if dist < t.radius + 20.0 then
                sleep = 0
                -- Draw zone circle
                DrawMarker(1, t.pos.x, t.pos.y, t.pos.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    t.radius * 2.0, t.radius * 2.0, 0.5,
                    100, 100, 255, 40, false, false, 2, nil, nil, false)

                if dist < t.radius then
                    local owner = territoryOwners[t.id]
                    if not myGang then
                        exports['eonexis-notify']:Notify('Territory', 'Join a gang to capture zones (/gang join)', 'info', 2000)
                    elseif owner == myGang then
                        exports['eonexis-notify']:Notify('Territory', 'Your turf: ' .. t.name, 'success', 2000)
                    else
                        -- Capture progress
                        if not capturing or capturing.id ~= t.id then
                            capturing = { id=t.id, startTime=GetGameTimer() }
                            exports['eonexis-notify']:Notify('Territory', 'Capturing ' .. t.name .. '... stay in zone!', 'warning', Config.CaptureTime * 1000)
                        else
                            local elapsed = (GetGameTimer() - capturing.startTime) / 1000
                            if elapsed >= Config.CaptureTime then
                                TriggerNetEvent('eonexis-gangs:captureTerritory', t.id)
                                capturing = nil
                            end
                        end
                    end
                else
                    if capturing and capturing.id == t.id then capturing = nil end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Gang chat shortcut /gc
RegisterCommand('gc', function(args)
    local msg = table.concat(args, ' ')
    if #msg < 1 then return end
    TriggerNetEvent('eonexis-gangs:chat', msg)
end, false)

TriggerEvent('chat:addSuggestion', '/gang', 'Gang commands', {{ name='subcommand', help='create/join/leave/info/list/stash/deposit/withdraw' }})
TriggerEvent('chat:addSuggestion', '/gc',   'Send a message to your gang', {{ name='message', help='Message' }})
