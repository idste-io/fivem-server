-- eonexis-hunger — client

local hunger = Config.StartHunger
local thirst = Config.StartThirst

local function updateUI()
    SendNUIMessage({ action='update', hunger=hunger, thirst=thirst })
end

-- Feed when an inventory item is used (fired by eonexis-inventory server)
RegisterNetEvent('eonexis-hunger:itemUsed')
AddEventHandler('eonexis-hunger:itemUsed', function(itemId)
    local food = Config.FoodItems[itemId]
    if not food then return end
    hunger = math.min(Config.MaxHunger, hunger + (food.hunger or 0))
    thirst = math.min(Config.MaxThirst, thirst + (food.thirst or 0))
    updateUI()
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Eat/Drink',
            string.format('Hunger: %d%%  Thirst: %d%%', math.floor(hunger), math.floor(thirst)),
            'info', 3000)
    end
end)

-- Drain thread
CreateThread(function()
    Wait(3000)  -- wait for HUD to load
    SendNUIMessage({ action='show' })
    updateUI()

    while true do
        Wait(Config.DrainTick)
        hunger = math.max(0, hunger - Config.HungerDrain)
        thirst = math.max(0, thirst - Config.ThirstDrain)
        updateUI()

        -- Health drain when starving or dehydrated
        if hunger < Config.DangerLevel or thirst < Config.DangerLevel then
            local ped = PlayerPedId()
            local hp  = GetEntityHealth(ped)
            if hp > 101 then
                SetEntityHealth(ped, math.max(101, hp - Config.HPDrainRate))
            end
            if exports['eonexis-notify'] then
                local what = (hunger < Config.DangerLevel and thirst < Config.DangerLevel) and 'Starving & dehydrated!'
                          or (hunger < Config.DangerLevel and 'Starving! Eat something.')
                          or 'Dehydrated! Drink something.'
                exports['eonexis-notify']:Notify('Warning', what, 'error', 5000)
            end
        end
    end
end)
