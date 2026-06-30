Config = {}
Config.MaxCarSpeed     = 120.0   -- m/s (~430 kph) — higher allows supercars
Config.MaxPedSpeed     = 12.0    -- m/s on foot (~43 kph)
Config.TeleportThresh  = 300.0   -- metres in one tick = suspicious
Config.CheckInterval   = 2000    -- ms between position checks
Config.AutoKick        = false   -- false = log only; true = kick on detection
Config.LogToConsole    = true

-- Notify Discord admin channel via bot HTTP API
Config.NotifyDiscord   = true
Config.BotHttpPort     = 3001
Config.BotSecret       = 'bBZRalUXXicn65H1nWb-_UNVHUTD4TjK'
