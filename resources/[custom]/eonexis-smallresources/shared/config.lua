Config = {}

Config.Seatbelt = {
    enabled    = true,
    key        = 'B',        -- toggle key
    ejectSpeed = 30,         -- mph — eject player if no seatbelt above this speed on crash
}

Config.Helmet = {
    enabled     = true,
    autoEquip   = true,      -- auto-equip helmet when entering motorcycle
    fineAmount  = 0,         -- 0 = no fine (needs economy mod)
}

Config.AfkKick = {
    enabled    = true,
    timeoutMs  = 5 * 60 * 1000,  -- 5 minutes
    warnMs     = 4 * 60 * 1000,  -- warn at 4 min
    exempt     = { 'admin' },    -- job names exempt from AFK kick
}

Config.CruiseControl = {
    enabled = true,
    key     = 'X',           -- toggle cruise control while in vehicle
}

Config.SpeedCamera = {
    enabled   = false,       -- enable when economy mod is installed
    limitMph  = 80,
    fineMin   = 100,
    fineMax   = 500,
}
