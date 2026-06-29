Config = {}

Config.Banks = {
    { id='fleeca_downtown',  name='Fleeca Downtown',   pos=vector3(149.7,  -1044.0, 29.3),  pay={min=8000,  max=18000} },
    { id='fleeca_rockford',  name='Fleeca Rockford',   pos=vector3(-350.3,  -49.6,  49.0),  pay={min=8000,  max=18000} },
    { id='pacific_standard', name='Pacific Standard',  pos=vector3(247.2,   225.5,  106.0), pay={min=15000, max=30000} },
}

Config.HeistDuration  = 45    -- seconds to drain vault
Config.Cooldown       = 1800  -- 30 min cooldown per bank after any attempt
Config.MarkerRadius   = 3.0   -- how close to marker to trigger prompt
Config.AlertRadius    = 400.0 -- world units for police alert broadcast
