Config = {}

-- Job Center location — LSIA area
Config.JobCenterPos = vector3(128.0, -1043.0, 29.0)

Config.Jobs = {
    {
        id      = 'taxi',
        label   = 'Taxi Driver',
        icon    = '🚕',
        pay     = { min=80, max=180 },
        desc    = 'Pick up customers around the city and drop them at their destination.',
        vehicle = 'taxi',
        uniform  = false,
    },
    {
        id      = 'delivery',
        label   = 'Delivery Driver',
        icon    = '📦',
        pay     = { min=120, max=220 },
        desc    = 'Collect packages from warehouses and deliver them across Los Santos.',
        vehicle = 'boxville2',
        uniform  = false,
    },
    {
        id      = 'mechanic',
        label   = 'Mechanic',
        icon    = '🔧',
        pay     = { min=150, max=300 },
        desc    = 'Repair vehicles at marked locations around the city.',
        vehicle = nil,
        uniform  = false,
    },
    {
        id      = 'trucker',
        label   = 'Truck Driver',
        icon    = '🚛',
        pay     = { min=300, max=600 },
        desc    = 'Long-haul freight between distribution centres. High pay, long drive.',
        vehicle = 'packer',
        uniform  = false,
    },
    {
        id      = 'fisher',
        label   = 'Fisherman',
        icon    = '🎣',
        pay     = { min=60, max=140 },
        desc    = 'Head to a fishing spot, cast your line, and sell your catch.',
        vehicle = nil,
        uniform  = false,
    },
    {
        id      = 'guard',
        label   = 'Security Guard',
        icon    = '🛡️',
        pay     = { min=100, max=200 },
        desc    = 'Patrol assigned locations and report incidents.',
        vehicle = nil,
        uniform  = false,
    },
}

-- Task locations per job
Config.TaxiPickups = {
    vector3(-550.0,-196.0, 38.0),
    vector3(213.0,  -809.0, 30.0),
    vector3(-1035.0,-2737.0,13.0),
    vector3(379.0, -1622.0, 29.0),
    vector3(-697.0,  -14.0, 38.0),
}
Config.TaxiDropoffs = {
    vector3(-336.0, -83.0,  38.0),
    vector3(912.0, -2139.0, 30.0),
    vector3(-1265.0,-1400.0,34.0),
    vector3(1695.0, 4820.0, 41.0),
    vector3(-1584.0, 5070.0,40.0),
}
Config.DeliveryPickups = {
    vector3(844.0,  -2970.0, 5.9),
    vector3(1167.0, -2093.0, 29.0),
    vector3(-219.0, -2870.0, 6.0),
}
Config.DeliveryDropoffs = {
    vector3(-319.0, -1468.0, 31.0),
    vector3(28.0,   -1346.0, 29.0),
    vector3(1213.0, -2689.0, 17.0),
    vector3(-707.0, -910.0,  19.0),
}
Config.MechanicSpots = {
    vector3(516.0,  -1316.0, 29.0),
    vector3(-367.0, -131.0,  39.0),
    vector3(1184.0, -774.0,  57.0),
    vector3(-1147.0,-2000.0, 13.0),
}
Config.TruckerPickups  = {
    vector3(844.0,  -2970.0, 5.9),
}
Config.TruckerDropoffs = {
    vector3(1167.0, 2648.0, 45.0),
    vector3(-1617.0, 5100.0,40.0),
}
Config.FishingSpots = {
    vector3(-770.0, -1569.0, 0.5),
    vector3(-2189.0,-373.0, 13.0),
    vector3(3379.0, -4866.0, 0.5),
    vector3(162.0,  6634.0, 1.5),
}
Config.GuardSpots = {
    vector3(428.0,  -1007.0, 29.0),
    vector3(-1593.0, 692.0,  129.0),
    vector3(303.0,   181.0,  104.0),
}

Config.FishTime = 15000  -- ms to "fish" before catching
