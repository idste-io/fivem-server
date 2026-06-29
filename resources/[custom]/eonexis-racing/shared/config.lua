Config = {}

Config.LobbyWait      = 20     -- seconds to wait for more players before starting
Config.CheckpointRadius = 18.0 -- meters to count a checkpoint as hit
Config.SoloParTimes   = { 60, 90, 120 }  -- par times (s) per route for bonus tiers
Config.Rewards = {
    solo = {
        gold   = 3000,   -- beat gold par time
        silver = 2000,   -- beat silver par time
        bronze = 1000,   -- just finish
    },
    multi = {
        [1] = 4000,      -- 1st place
        [2] = 2000,      -- 2nd
        [3] = 1000,      -- 3rd
    }
}

Config.Routes = {
    {
        id    = 'downtown_sprint',
        name  = 'Downtown Sprint',
        desc  = 'Race through the heart of Los Santos',
        par   = { gold=75, silver=110 },  -- seconds
        start = vector3(432.0, -982.0, 30.7),
        checkpoints = {
            vector3(222.0, -786.0, 31.0),
            vector3(-145.0, -636.0, 37.2),
            vector3(-494.0, -424.0, 34.0),
            vector3(-1065.0, -289.0, 37.0),
        },
    },
    {
        id    = 'vinewood_climb',
        name  = 'Vinewood Climb',
        desc  = 'Blast up into the hills above the city',
        par   = { gold=95, silver=130 },
        start = vector3(102.0, -1047.0, 29.4),
        checkpoints = {
            vector3(345.0, -724.0, 28.5),
            vector3(660.0, -511.0, 82.0),
            vector3(870.0, -300.0, 80.0),
            vector3(1060.0, -120.0, 83.0),
        },
    },
    {
        id    = 'harbor_run',
        name  = 'Harbor Run',
        desc  = 'Tear along the LS waterfront docks',
        par   = { gold=80, silver=115 },
        start = vector3(-180.0, -2368.0, 6.0),
        checkpoints = {
            vector3(-350.0, -2101.0, 6.0),
            vector3(-800.0, -1820.0, 6.0),
            vector3(-1200.0, -1540.0, 3.0),
            vector3(-1600.0, -1200.0, 4.0),
        },
    },
}
