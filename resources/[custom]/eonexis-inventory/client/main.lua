-- eonexis-inventory — client

RegisterNetEvent('eonexis-inventory:heal')
AddEventHandler('eonexis-inventory:heal', function(amount)
    local ped = PlayerPedId()
    local hp  = GetEntityHealth(ped)
    SetEntityHealth(ped, math.min(200, hp + amount))
end)
