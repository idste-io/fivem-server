-- eonexis-weather — client

RegisterNetEvent('eonexis-weather:setWeather')
AddEventHandler('eonexis-weather:setWeather', function(weather, transitionSecs)
    if transitionSecs and transitionSecs > 0 then
        SetWeatherTypeOverTime(weather, transitionSecs)
    else
        SetWeatherTypePersist(weather)
        SetWeatherTypeNow(weather)
        SetWeatherTypeNowPersist(weather)
    end
end)

RegisterNetEvent('eonexis-weather:setTime')
AddEventHandler('eonexis-weather:setTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    TriggerServerEvent('eonexis-weather:requestSync')
end)
