Config = {}

-- Discord + webapp links
Config.WebappURL  = 'https://eonexis.invoxio.work'
Config.DiscordURL = 'https://discord.gg/eonexis'   -- update if invite changes
Config.LinkURL    = 'https://eonexis.invoxio.work/#/link'  -- webapp Discord-link page

-- UI scale presets (multiplier applied to NUI root)
Config.ScalePresets = {
    { id = 'small',  label = 'Small',   value = 0.85 },
    { id = 'normal', label = 'Normal',  value = 1.0  },
    { id = 'large',  label = 'Large',   value = 1.15 },
    { id = 'xl',     label = 'Extra Large', value = 1.3 },
}
Config.DefaultScale = 'normal'

-- Rebindable key actions (RegisterKeyMapping → players rebind in GTA Settings ▸ Key Bindings)
-- command name must be unique server-wide; the chat command is also registered.
Config.Keybinds = {
    { command = 'phone',     label = 'Open Phone',        default = 'P / TAB' },
    { command = 'settings',  label = 'Open Settings',     default = 'F7' },
    { command = 'quests',    label = 'Open Quests',       default = 'F6' },
    { command = 'rules',     label = 'Open Rules',        default = 'F2' },
}

-- Toggleable game options (defaults; stored per-player via KVP)
Config.Toggles = {
    { id = 'showHud',        label = 'Show HUD',              default = true  },
    { id = 'showSpeedo',     label = 'Show Speedometer',      default = true  },
    { id = 'showNameplates', label = 'Show Player Nameplates',default = true  },
    { id = 'controllerCursor', label = 'Controller Cursor (menus)', default = true },
}
