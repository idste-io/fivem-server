-- eonexis-robbery — client

local robbing    = false
local cooldowns  = {}  -- [storeId] = gameTimer when cooldown expires

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Robbery', msg, t or 'info', 5000)
    end
end

local function isArmed()
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    return weapon ~= 0xA2719263  -- not unarmed
end

local function getNearbyStore()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    for _, store in ipairs(Config.Stores) do
        local dist = #(pos - store.pos)
        if dist < 12.0 then return store end
    end
    return nil
end

-- Draw progress bar
local function showProgressBar(label, duration)
    local startTime = GetGameTimer()
    CreateThread(function()
        while true do
            local elapsed = GetGameTimer() - startTime
            local pct = math.min(elapsed / duration, 1.0)
            -- Background bar
            DrawRect(0.5, 0.925, 0.32, 0.028, 10, 10, 20, 200)
            -- Fill
            DrawRect(0.5 - 0.16 + (pct * 0.32 * 0.5), 0.925, 0.32 * pct, 0.028, 147, 82, 219, 255)
            -- Label
            SetTextFont(4)
            SetTextScale(0.0, 0.32)
            SetTextColour(255, 255, 255, 230)
            SetTextCentre(true)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(label)
            EndTextCommandDisplayText(0.5, 0.908)
            if pct >= 1.0 then break end
            Wait(0)
        end
    end)
    Wait(duration)
end

-- Show E prompt
local function drawPrompt(text)
    SetTextFont(4)
    SetTextScale(0.0, 0.35)
    SetTextColour(255, 255, 255, 240)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName('[E] ' .. text)
    EndTextCommandDisplayText(0.5, 0.86)
end

-- Main loop
CreateThread(function()
    while true do
        Wait(0)
        if not robbing then
            local store = getNearbyStore()
            if store then
                local now = GetGameTimer()
                local cdExpiry = cooldowns[store.id] or 0
                if now < cdExpiry then
                    local remaining = math.ceil((cdExpiry - now) / 1000)
                    drawPrompt(string.format('Police still patrolling... (%ds)', remaining))
                elseif not isArmed() then
                    drawPrompt('Arm yourself first to rob this store')
                else
                    drawPrompt('ROB ' .. store.name)
                    if IsControlJustPressed(0, 38) then  -- E key
                        robbing = true
                        CreateThread(function()
                            -- Channel the robbery
                            showProgressBar('Holding up the clerk...', Config.ChannelTime)
                            TriggerServerEvent('eonexis-robbery:attempt', store.id)
                        end)
                    end
                end
            end
        end
    end
end)

-- Server result
RegisterNetEvent('eonexis-robbery:result')
AddEventHandler('eonexis-robbery:result', function(success, storeId, cash, cooldownSec)
    robbing = false
    if success then
        cooldowns[storeId] = GetGameTimer() + (cooldownSec * 1000)
        notify(string.format('Got away with $%d!\nCops called — stay low for a while.', cash), 'success')
        -- Fire quest event
        TriggerServerEvent('eonexis-quests:serverKey', 'robbery_success')
        TriggerServerEvent('eonexis-quests:serverKey', 'has_weapon')
    else
        cooldowns[storeId] = GetGameTimer() + (cooldownSec * 1000)
        local ped = PlayerPedId()
        SetEntityHealth(ped, math.max(GetEntityHealth(ped) - 30, 100))
        notify('The clerk fought back! You took some damage.', 'error')
    end
end)

RegisterNetEvent('eonexis-robbery:cancelled')
AddEventHandler('eonexis-robbery:cancelled', function(reason)
    robbing = false
    notify(reason, 'error')
end)

-- Police alert broadcast
RegisterNetEvent('eonexis-robbery:alert')
AddEventHandler('eonexis-robbery:alert', function(area, perp)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Police Alert', string.format('[%s] 24/7 robbery reported in %s!', perp, area), 'warning', 8000)
    end
end)

-- Map blips for stores
CreateThread(function()
    Wait(1000)
    for _, store in ipairs(Config.Stores) do
        local b = AddBlipForCoord(store.pos.x, store.pos.y, store.pos.z)
        SetBlipSprite(b, 52)    -- 24/7 sprite
        SetBlipColour(b, 1)     -- red
        SetBlipScale(b, 0.7)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(store.name)
        EndTextCommandSetBlipName(b)
    end
end)
