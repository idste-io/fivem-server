Config = {}

-- type: 'house' | 'business'
-- businessIncome: $ per 5 minutes (businesses only)
-- spawn: where player spawns when using this as home
Config.Properties = {
    -- ── Houses ──────────────────────────────────────────────────────────────────
    {
        id       = 'grove_house',
        label    = 'Grove Street House',
        type     = 'house',
        price    = 25000,
        blipPos  = vector3(108.0,  -1958.0, 21.2),
        spawn    = { x=108.5,  y=-1957.0, z=21.2,  h=190.0 },
        icon     = '🏠',
        desc     = 'Modest house in South LS. Great starter home.',
    },
    {
        id       = 'vinewood_bungalow',
        label    = 'Vinewood Bungalow',
        type     = 'house',
        price    = 95000,
        blipPos  = vector3(-654.0, 566.0,  131.0),
        spawn    = { x=-653.0, y=567.0,  z=131.0, h=340.0 },
        icon     = '🏡',
        desc     = 'Quiet hillside bungalow overlooking the city.',
    },
    {
        id       = 'sandy_trailer',
        label    = 'Sandy Shores Trailer',
        type     = 'house',
        price    = 12000,
        blipPos  = vector3(1969.0, 3792.0, 32.5),
        spawn    = { x=1969.5, y=3793.0, z=32.5, h=90.0  },
        icon     = '🏕️',
        desc     = 'Desert life out east. Cheap but cosy.',
    },
    {
        id       = 'beachside_apt',
        label    = 'Del Perro Apartment',
        type     = 'house',
        price    = 60000,
        blipPos  = vector3(-1447.0,-541.0, 34.0),
        spawn    = { x=-1446.0,y=-540.0, z=34.0, h=270.0 },
        icon     = '🏢',
        desc     = 'Beachside apartment with ocean views.',
    },
    {
        id       = 'rockford_mansion',
        label    = 'Rockford Hills Mansion',
        type     = 'house',
        price    = 450000,
        blipPos  = vector3(-863.0, 177.0,  73.0),
        spawn    = { x=-862.0, y=178.0,  z=73.0, h=130.0 },
        icon     = '🏰',
        desc     = 'Luxury mansion in the most exclusive neighbourhood.',
    },
    {
        id       = 'paleto_cottage',
        label    = 'Paleto Bay Cottage',
        type     = 'house',
        price    = 20000,
        blipPos  = vector3(-105.0, 6466.0, 31.6),
        spawn    = { x=-104.0, y=6467.0, z=31.6, h=45.0  },
        icon     = '🏘️',
        desc     = 'Peaceful coastal cottage up north.',
    },

    -- ── Businesses ───────────────────────────────────────────────────────────────
    {
        id             = 'corner_shop',
        label          = 'Corner Shop',
        type           = 'business',
        price          = 45000,
        blipPos        = vector3(28.0,  -1346.0, 29.0),
        spawn          = { x=29.0,  y=-1345.0, z=29.0, h=90.0 },
        icon           = '🏪',
        desc           = 'Small convenience store in South LS.',
        businessIncome = 250,   -- $250 every 5 min while logged in
    },
    {
        id             = 'car_wash',
        label          = 'Car Wash',
        type           = 'business',
        price          = 80000,
        blipPos        = vector3(-697.0,-933.0,  19.2),
        spawn          = { x=-696.0,y=-932.0, z=19.2, h=200.0 },
        icon           = '🚗',
        desc           = 'Popular car wash in Rockford Hills.',
        businessIncome = 400,
    },
    {
        id             = 'auto_shop',
        label          = 'Auto Repair Shop',
        type           = 'business',
        price          = 120000,
        blipPos        = vector3(516.0, -1316.0, 29.0),
        spawn          = { x=517.0, y=-1315.0, z=29.0, h=0.0   },
        icon           = '🔧',
        desc           = 'Busy mechanic shop near LSIA.',
        businessIncome = 600,
    },
    {
        id             = 'nightclub',
        label          = 'Eonexis Nightclub',
        type           = 'business',
        price          = 750000,
        blipPos        = vector3(-1603.0,-3005.0,13.9),
        spawn          = { x=-1602.0,y=-3004.0,z=13.9, h=135.0 },
        icon           = '🎶',
        desc           = 'High-end nightclub. Best earner on the block.',
        businessIncome = 1500,
    },
}

Config.MarkerType   = 1      -- cylinder marker
Config.MarkerRadius = 2.0    -- metres to trigger marker interaction
Config.IncomeInterval = 300000  -- 5 minutes in ms
