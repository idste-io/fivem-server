Config = {}

Config.CreateCost  = 10000
Config.MaxMembers  = 10
Config.CaptureTime = 60    -- seconds standing in zone to capture it
Config.IncomeInterval = 300  -- seconds between passive income ticks

Config.Territories = {
    { id='grove_st',  name='Grove Street',   pos=vector3(87.0,    -1962.0, 21.1), radius=80.0,  income=500 },
    { id='downtown',  name='Downtown',       pos=vector3(252.0,   -580.0,  43.9), radius=100.0, income=750 },
    { id='vespucci',  name='Vespucci Beach', pos=vector3(-1200.0,-1576.0,  3.0),  radius=80.0,  income=600 },
    { id='sandy',     name='Sandy Shores',   pos=vector3(1879.0,  3748.0,  33.0), radius=100.0, income=400 },
    { id='paleto',    name='Paleto Bay',     pos=vector3(-255.0,  6272.0,  32.0), radius=80.0,  income=450 },
}

-- Blip colours (per-territory when captured, to show ownership)
Config.BlipColors = { 1, 2, 3, 4, 5, 17, 25, 38, 40, 46 }
