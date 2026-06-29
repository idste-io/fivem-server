-- eonexis-banking — client

local cooldowns = {}
local inHeist   = false
local heistBank = nil
local markers   = {}
local blips     = {}

-- Draw markers and blips for all banks
CreateThread(function()
    for _, bank in ipairs(Config.Banks) do
        local b = AddBlipForCoord(bank.pos.x, bank.pos.y, bank.pos.z)
        SetBlipSprite(b, 207)   -- bank icon
        SetBlipColour(b, 3)
        SetBlipScale(b, 0.8)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Bank — ' .. bank.name)
        EndTextCommandSetBlipName(b)
        blips[bank.id] = b
    end
end)

-- Main thread: markers + proximity check
CreateThread(function()
    TriggerNetEvent('eonexis-banking:requestCooldowns')
    while true do
        local ped   = PlayerPedId()
        local pos   = GetEntityCoords(ped)
        local sleep = 500

        for _, bank in ipairs(Config.Banks) do
            local dist = #(pos - bank.pos)
            if dist < 30.0 then
                sleep = 0
                local now = os.time()
                local onCd = cooldowns[bank.id] and now < cooldowns[bank.id]

                DrawMarker(1, bank.pos.x, bank.pos.y, bank.pos.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    onCd and 255 or 255,
                    onCd and 80  or 50,
                    onCd and 80  or 200,
                    120, false, true, 2, nil, nil, false)

                if dist < Config.MarkerRadius then
                    if onCd then
                        local remain = cooldowns[bank.id] - now
                        exports['eonexis-notify']:Notify('Bank', ('Vault locked — cooldown %ds'):format(remain), 'info', 2500)
                    elseif not inHeist then
                        exports['eonexis-notify']:Notify('Bank', 'Press [E] to rob the vault', 'info', 2000)
                        if IsControlJustPressed(0, 38) then  -- E
                            startHeist(bank)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function startHeist(bank)
    if inHeist then return end
    inHeist  = true
    heistBank = bank.id
    TriggerNetEvent('eonexis-banking:startHeist', bank.id)
end

-- Server approved heist start
RegisterNetEvent('eonexis-banking:begin')
AddEventHandler('eonexis-banking:begin', function(bankId, duration)
    if heistBank ~= bankId then return end
    -- Progress bar countdown
    local elapsed = 0
    local interval = 1000
    exports['eonexis-notify']:Notify('Bank Heist', 'Draining vault... stay close!', 'warning', duration * 1000)

    CreateThread(function()
        local startTime = GetGameTimer()
        while true do
            Wait(interval)
            elapsed = (GetGameTimer() - startTime) / 1000
            if elapsed >= duration then
                TriggerNetEvent('eonexis-banking:heistDone', heistBank)
                inHeist  = false
                heistBank = nil
                return
            end
            local ped = PlayerPedId()
            local bk = getBank(bankId)
            if bk then
                local dist = #(GetEntityCoords(ped) - bk.pos)
                if dist > 20.0 then
                    -- Left the zone, abort
                    TriggerNetEvent('eonexis-banking:heistAbort', bankId)
                    exports['eonexis-notify']:Notify('Bank Heist', 'Vault breach cancelled — you fled!', 'error', 4000)
                    inHeist  = false
                    heistBank = nil
                    return
                end
            end
        end
    end)
end)

function getBank(id)
    for _, b in ipairs(Config.Banks) do
        if b.id == id then return b end
    end
end

-- Server sends updated cooldowns
RegisterNetEvent('eonexis-banking:setCooldowns')
AddEventHandler('eonexis-banking:setCooldowns', function(cd)
    cooldowns = cd
end)

-- Global alert when someone starts a heist
RegisterNetEvent('eonexis-banking:heistAlert')
AddEventHandler('eonexis-banking:heistAlert', function(bankName, robber)
    exports['eonexis-notify']:Notify('🚨 Police Alert', (robber .. ' is robbing %s!'):format(bankName), 'error', 8000)
end)
