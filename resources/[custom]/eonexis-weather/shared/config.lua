Config = {}

-- Weather cycle list — plays in order, loops
Config.WeatherCycle = {
    'CLEAR', 'CLEAR', 'EXTRASUNNY',
    'CLOUDS', 'OVERCAST',
    'RAIN', 'THUNDER',
    'FOGGY', 'CLEAR',
}
Config.CycleMinutes   = 10   -- real minutes each weather type lasts
Config.TransitionTime = 45   -- seconds to blend between weather types
Config.TimeScale      = 2    -- 1 real second = 2 in-game minutes (day/night cycle speed)
