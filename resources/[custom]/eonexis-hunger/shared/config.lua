Config = {}

Config.MaxHunger    = 100
Config.MaxThirst    = 100
Config.HungerDrain  = 1.5   -- per minute
Config.ThirstDrain  = 2.0   -- per minute (thirst drains faster)
Config.DangerLevel  = 20    -- below this %: health drain begins
Config.HPDrainRate  = 2     -- HP lost per drain tick
Config.DrainTick    = 60000 -- ms between drain ticks (1 min)
Config.StartHunger  = 80
Config.StartThirst  = 80

-- Items that restore hunger/thirst (matched against inventory item IDs)
Config.FoodItems = {
    water   = { hunger=0,   thirst=45 },
    coffee  = { hunger=8,   thirst=25 },
    burger  = { hunger=40,  thirst=8  },
    fish    = { hunger=25,  thirst=5  },
}
