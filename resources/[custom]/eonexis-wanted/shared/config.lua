Config = {}

-- Each crime type awards this many "star points" (10 points = 1 star; max 50 = 5 stars)
Config.CrimePoints = {
    assault         = 5,   -- 0.5 star
    carjacking      = 8,
    theft           = 6,
    shooting        = 12,  -- 1.2 stars
    killing_npc     = 15,
    killing_police  = 25,  -- 2.5 stars
    robbery         = 18,
    drug_dealing    = 10,
    trespassing     = 3,
    vehicleramming  = 7,
}

-- Star points decay per second when not seen by police
Config.DecayPerSecond = 0.5  -- 10 pts (1 star) decays in 20s after 30s LoS break

-- Seconds out-of-LoS before decay starts
Config.DecayDelay = 30

-- Response per star level (whole stars)
Config.Response = {
    [1] = { cops = 1, helicopter = false, swat = false, fib = false, military = false },
    [2] = { cops = 2, helicopter = true,  swat = false, fib = false, military = false },
    [3] = { cops = 3, helicopter = true,  swat = true,  fib = false, military = false },
    [4] = { cops = 4, helicopter = true,  swat = true,  fib = true,  military = false },
    [5] = { cops = 6, helicopter = true,  swat = true,  fib = true,  military = true  },
}

-- Loot table for killing hostile NPCs (cops, SWAT, FIB, military)
-- rarity: common=60%, uncommon=25%, rare=12%, epic=3%
Config.LootTable = {
    common = {
        { item = 'pistol_ammo',   amount = { 12, 24 }, cash = 0   },
        { item = 'smg_ammo',      amount = { 6, 12 },  cash = 0   },
        { item = 'armor_frag',    amount = { 1, 1 },   cash = 0   },
        { item = 'cash',          amount = { 0, 0 },   cash = 200 },
    },
    uncommon = {
        { item = 'pistol',        amount = { 1, 1 },   cash = 0   },
        { item = 'smg',           amount = { 1, 1 },   cash = 0   },
        { item = 'shotgun_ammo',  amount = { 6, 12 },  cash = 0   },
        { item = 'cash',          amount = { 0, 0 },   cash = 500 },
    },
    rare = {
        { item = 'carbine_rifle', amount = { 1, 1 },   cash = 0    },
        { item = 'assault_rifle', amount = { 1, 1 },   cash = 0    },
        { item = 'body_armor',    amount = { 1, 1 },   cash = 0    },
        { item = 'cash',          amount = { 0, 0 },   cash = 1200 },
    },
    epic = {
        { item = 'sniper_rifle',  amount = { 1, 1 },   cash = 0    },
        { item = 'rpg',           amount = { 1, 1 },   cash = 0    },
        { item = 'minigun',       amount = { 1, 1 },   cash = 0    },
        { item = 'cash',          amount = { 0, 0 },   cash = 5000 },
    },
}

-- Loot rarity weights (must sum to 100)
Config.RarityWeights = { common = 60, uncommon = 25, rare = 12, epic = 3 }

-- Weapon hashes for cop peds (so we can detect kills of cops)
Config.CopModels = {
    's_m_y_cop_01', 's_m_y_swat_01', 's_m_y_ranger_01',
    's_f_y_cop_01', 'u_m_y_fibsec_01', 's_m_m_fibsec_01',
    's_m_y_armymech_01', 's_m_y_marine_01', 's_m_y_marine_02',
}
