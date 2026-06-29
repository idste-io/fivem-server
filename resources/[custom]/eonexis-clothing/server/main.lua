-- eonexis-clothing — server (minimal; clothing is mostly client-side)

RegisterNetEvent('eonexis-clothing:pay')
AddEventHandler('eonexis-clothing:pay', function(amount)
    local src = source
    if amount and amount > 0 then
        exports['eonexis-economy']:removeMoney(src, amount, 'clothing change')
    end
end)

print('[eonexis-clothing] loaded — ' .. #Config.Stores .. ' stores')
