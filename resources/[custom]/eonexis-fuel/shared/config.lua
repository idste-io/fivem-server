Config = {}

Config.MaxFuel        = 100.0   -- tank capacity
Config.StartFuel      = 80.0    -- fuel on first spawn (%)
Config.DrainRate      = 0.08    -- % per second while driving (roughly ~20min full tank)
Config.IdleDrainRate  = 0.01    -- % per second while engine idle but stationary
Config.LowFuelWarn    = 15.0    -- warn player below this %
Config.RefuelRate     = 8.0     -- % per second at a gas pump
Config.RefuelRadius   = 5.0     -- metres from pump to refuel
Config.ShowHUD        = true    -- show fuel bar on screen

-- Approximate coords of gas station pumps in Los Santos (add more as needed)
Config.GasStations = {
    vector3(49.2,  -1780.1, 29.4),   -- Davis Ave
    vector3(1207.0, -1402.0, 35.2),  -- El Burro Heights
    vector3(265.0,  -1261.2, 29.0),  -- Innocence Blvd
    vector3(-711.0, -935.0,  19.2),  -- La Mesa
    vector3(-56.1,  -1557.0, 34.9),  -- Elgin Ave
    vector3(1543.9, 3005.2,  40.7),  -- Sandy Shores
    vector3(2539.0, 2594.0,  37.9),  -- Grand Senora
    vector3(-2555.3,-363.9,  27.2),  -- Great Ocean Hwy
    vector3(172.0,  6624.0,  31.9),  -- Paleto Bay
}
