Config = {}

Config.Job = 'police'

Config.Stations = {
    { pos=vector3(457.0,  -987.0,  30.7), name='Mission Row PD'  },
    { pos=vector3(-1108.0, -847.0, 19.3), name='Vespucci PD'     },
    { pos=vector3(372.0,   817.0,  187.1), name='Vinewood PD'    },
}

Config.JailPos     = vector3(1649.0, 2570.0, 45.5)  -- Bolingbroke
Config.JailHeading = 90.0

Config.PoliceVehicle = 'police'
Config.PoliceWeapon  = 'WEAPON_PISTOL'

Config.CuffRange   = 3.5   -- max distance to cuff a player
Config.WantedDecay = 180   -- seconds of clean behavior before wanted level drops

-- Crime events that add wanted stars (triggered by other mods)
Config.Crimes = {
    robbery_attempt = 2,
    robbery_success = 3,
    heist_start     = 3,
    drug_deal       = 2,
    drug_alert      = 2,
    murder          = 4,
}
