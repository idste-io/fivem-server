Config = {}

Config.JobCenterPos = vector3(128.0, -1043.0, 29.0)

-- ── License offices ───────────────────────────────────────────────────────────
-- Each license has a physical location with an E-prompt to purchase it
Config.Licenses = {
    {
        id      = 'cdl',
        label   = 'Commercial Driver License',
        cost    = 2500,
        pos     = vector3(-424.0, -597.0, 30.5),  -- DMV, downtown
        heading = 210.0,
        blipSprite = 380, blipColour = 5, blipLabel = 'DMV — CDL Office',
        desc    = 'Required to operate heavy trucks. Purchase at the DMV.',
        requiredBy = { 'trucker' },
    },
    {
        id      = 'fishing_license',
        label   = 'Fishing License',
        cost    = 500,
        pos     = vector3(-764.0, -1538.0, 0.5),  -- Vespucci Canals pier
        heading = 90.0,
        blipSprite = 68, blipColour = 3, blipLabel = 'Harbor Master — Fishing License',
        desc    = 'Required to fish commercially. Available at the pier.',
        requiredBy = { 'fisher' },
    },
    {
        id      = 'security_cert',
        label   = 'Security Guard Certification',
        cost    = 1000,
        pos     = vector3(428.0, -1009.0, 28.5),  -- near police station
        heading = 270.0,
        blipSprite = 436, blipColour = 40, blipLabel = 'Security Training Center',
        desc    = 'Required for security guard work. Train at the security center.',
        requiredBy = { 'guard' },
    },
    {
        id      = 'mechanic_cert',
        label   = 'Mechanic Certification',
        cost    = 1500,
        pos     = vector3(-344.0, -133.5, 39.0),  -- near the garage
        heading = 160.0,
        blipSprite = 446, blipColour = 26, blipLabel = 'Auto-School — Mechanic Cert',
        desc    = 'Required to work as a mechanic. Certify at the auto school.',
        requiredBy = { 'mechanic' },
    },
    {
        id      = 'food_handler',
        label   = 'Food Handler Certificate',
        cost    = 800,
        pos     = vector3(151.0, -1010.0, 29.3),  -- near restaurant district
        heading = 45.0,
        blipSprite = 52, blipColour = 46, blipLabel = 'Health Dept — Food Handler Cert',
        desc    = 'Required for bartender and chef work.',
        requiredBy = { 'bartender', 'chef' },
    },
}

-- ── Jobs ──────────────────────────────────────────────────────────────────────
Config.Jobs = {
    {
        id      = 'taxi',
        label   = 'Taxi Driver',
        icon    = '🚕',
        pay     = { min=100, max=220 },
        desc    = 'Pick up customers around the city and drop them at their destination.',
        vehicle = 'taxi',
        license = nil,   -- no license required; starter job
    },
    {
        id      = 'delivery',
        label   = 'Delivery Driver',
        icon    = '📦',
        pay     = { min=130, max=260 },
        desc    = 'Collect packages from warehouses and deliver them across Los Santos.',
        vehicle = 'boxville2',
        license = nil,
    },
    {
        id      = 'mechanic',
        label   = 'Mechanic',
        icon    = '🔧',
        pay     = { min=200, max=380 },
        desc    = 'Repair vehicles at marked locations around the city.',
        vehicle = nil,
        license = 'mechanic_cert',
    },
    {
        id      = 'trucker',
        label   = 'Truck Driver',
        icon    = '🚛',
        pay     = { min=350, max=700 },
        desc    = 'Long-haul freight between distribution centres. High pay, long drive.',
        vehicle = 'packer',
        license = 'cdl',
    },
    {
        id      = 'fisher',
        label   = 'Fisherman',
        icon    = '🎣',
        pay     = { min=80, max=180 },
        desc    = 'Head to a fishing spot, cast your line, and sell your catch.',
        vehicle = nil,
        license = 'fishing_license',
    },
    {
        id      = 'guard',
        label   = 'Security Guard',
        icon    = '🛡️',
        pay     = { min=150, max=280 },
        desc    = 'Patrol assigned locations and report incidents.',
        vehicle = nil,
        license = 'security_cert',
    },
    {
        id      = 'bartender',
        label   = 'Bartender',
        icon    = '🍺',
        pay     = { min=120, max=250 },
        desc    = 'Serve drinks and keep regulars happy at bars around the city.',
        vehicle = nil,
        license = 'food_handler',
    },
    {
        id      = 'chef',
        label   = 'Chef',
        icon    = '👨‍🍳',
        pay     = { min=160, max=320 },
        desc    = 'Prepare meals at restaurants. Special recipes give bonus pay.',
        vehicle = nil,
        license = 'food_handler',
    },
    {
        id      = 'courier',
        label   = 'Courier',
        icon    = '🏍️',
        pay     = { min=90, max=180 },
        desc    = 'Fast motorcycle deliveries across the city — small packages, quick money.',
        vehicle = 'faggio3',
        license = nil,
    },
}

-- ── Task locations ────────────────────────────────────────────────────────────

Config.TaxiPickups = {
    vector3(-550.0,-196.0, 38.0),
    vector3(213.0, -809.0, 30.0),
    vector3(-1035.0,-2737.0,13.0),
    vector3(379.0, -1622.0, 29.0),
    vector3(-697.0, -14.0,  38.0),
    vector3(1132.0, -982.0, 46.5),
    vector3(-1211.0,-338.0, 37.5),
    vector3(292.0,  -597.0, 43.3),
}
Config.TaxiDropoffs = {
    vector3(-336.0, -83.0,  38.0),
    vector3(912.0, -2139.0, 30.0),
    vector3(-1265.0,-1400.0,34.0),
    vector3(1695.0, 4820.0, 41.0),
    vector3(-1584.0,5070.0, 40.0),
    vector3(-2532.0,2334.0, 33.0),
    vector3(440.0,   -970.0,30.7),
    vector3(181.0,  -927.0, 30.7),
}

Config.DeliveryPickups = {
    vector3(844.0,  -2970.0, 5.9),
    vector3(1167.0, -2093.0, 29.0),
    vector3(-219.0, -2870.0, 6.0),
    vector3(-323.0,  -582.0, 35.0),
    vector3(692.0,  -1987.0, 29.0),
}
Config.DeliveryDropoffs = {
    vector3(-319.0,-1468.0, 31.0),
    vector3(28.0,  -1346.0, 29.0),
    vector3(1213.0,-2689.0, 17.0),
    vector3(-707.0, -910.0, 19.0),
    vector3(-533.0, -1199.0,18.0),
    vector3(1153.0,  2640.0,45.0),
}

Config.MechanicSpots = {
    vector3(516.0,  -1316.0, 29.0),
    vector3(-367.0, -131.0,  39.0),
    vector3(1184.0, -774.0,  57.0),
    vector3(-1147.0,-2000.0, 13.0),
    vector3(153.0,  -1740.0, 29.0),
    vector3(-714.0, -1274.0, 5.0),
}

Config.TruckerPickups  = {
    vector3(844.0,  -2970.0, 5.9),
    vector3(-325.0,  -585.0, 34.7),
    vector3(1166.0, -2096.0, 29.0),
}
Config.TruckerDropoffs = {
    vector3(1167.0, 2648.0,  45.0),
    vector3(-1617.0,5100.0,  40.0),
    vector3(-2023.0,3237.0,  33.0),
    vector3(2576.0, 358.0,   108.0),
}

Config.FishingSpots = {
    vector3(-770.0, -1569.0, 0.5),
    vector3(-2189.0,-373.0,  13.0),
    vector3(3379.0, -4866.0, 0.5),
    vector3(162.0,   6634.0, 1.5),
    vector3(-1080.0,-1563.0, 0.2),
    vector3(4071.0, -4035.0, 0.5),
}

Config.GuardSpots = {
    vector3(428.0,  -1007.0, 29.0),
    vector3(-1593.0, 692.0,  129.0),
    vector3(303.0,   181.0,  104.0),
    vector3(-47.0,  -698.0,  44.0),
    vector3(1130.0, -460.0,  67.0),
    vector3(-1101.0,-240.0,  37.0),
}

Config.BartenderSpots = {
    vector3(108.0,  -1245.0, 29.0),
    vector3(-576.0, -897.0,  23.5),
    vector3(-1671.0, 293.0,  66.5),
    vector3(-1391.0,-610.0,  30.0),
}

Config.ChefSpots = {
    vector3(150.0,  -1011.0, 29.3),
    vector3(-1198.0,-901.0,  12.0),
    vector3(-45.0,   -597.0, 43.3),
}

Config.CourierPickups = {
    vector3(-128.0, -2240.0, 6.0),
    vector3(293.0,  -1445.0, 29.0),
    vector3(-697.0, -917.0,  19.0),
    vector3(439.0,   -970.0, 30.7),
}
Config.CourierDropoffs = {
    vector3(-730.0, -2008.0, 20.0),
    vector3(379.0,  -1622.0, 29.0),
    vector3(1126.0, -1528.0, 35.0),
    vector3(-42.0,   -730.0, 44.0),
}

Config.FishTime    = 12000  -- ms to fish
Config.BartendTime = 10000  -- ms to serve drinks
Config.ChefTime    = 15000  -- ms to cook meal
Config.GuardTime   = 120000 -- ms to patrol (2 min)
