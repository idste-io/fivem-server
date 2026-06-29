Config = {}

Config.ChannelTime  = 4000    -- ms to hold E to rob (4s)
Config.SuccessRate  = 0.75    -- 75% success chance
Config.MinCash      = 600
Config.MaxCash      = 2200
Config.StoreCooldown = 15 * 60  -- seconds between robberies at same store
Config.EscapeRadius = 120.0    -- must be this far from store to "escape" (flavor only)

Config.Stores = {
    { id='vespu24',  name='Vespucci Blvd 24/7',  pos=vector3(-714.9, -909.3, 19.2),  area='Vespucci Blvd'   },
    { id='mirror24', name='Mirror Park 24/7',     pos=vector3(1161.0, -322.0, 69.2),  area='Mirror Park'      },
    { id='davis24',  name='Davis 24/7',           pos=vector3(24.5,  -1346.6, 29.5),  area='Davis'            },
    { id='southls',  name='South LS 24/7',        pos=vector3(-47.6, -1757.4, 29.4),  area='South Los Santos' },
    { id='sandy24',  name='Sandy Shores 24/7',    pos=vector3(1729.3,  3724.1, 34.2), area='Sandy Shores'     },
}
