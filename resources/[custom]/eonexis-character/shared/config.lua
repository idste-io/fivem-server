Config = {}

-- Cost to change character name after first creation
Config.NameChangeCost = 500

-- Cost to change appearance outfit (base — multiplied by outfit tier)
Config.OutfitChangeCost = {
    basic   = 0,      -- free starter outfit
    casual  = 200,
    smart   = 500,
    luxury  = 1200,
}

-- Monthly reset: day of month (1–28) at midnight UTC
Config.ResetDayOfMonth  = 1
Config.ResetHour        = 0   -- UTC hour

-- On reset, what is preserved (everything else is wiped)
Config.ResetKeeps = {
    money  = true,
    bank   = true,
    homes  = true,   -- purchased properties with type='house'
}

-- Outfit presets available on character creation (name → ped components)
-- Each preset: { label, tier, components = { { componentId, drawableId, textureId }, ... } }
Config.Outfits = {
    { id='basic_m',  label='Basic (Male)',       gender='male',   tier='basic',   price=0    },
    { id='casual_m', label='Casual (Male)',       gender='male',   tier='casual',  price=200  },
    { id='smart_m',  label='Smart Casual (Male)', gender='male',   tier='smart',   price=500  },
    { id='basic_f',  label='Basic (Female)',      gender='female', tier='basic',   price=0    },
    { id='casual_f', label='Casual (Female)',     gender='female', tier='casual',  price=200  },
    { id='smart_f',  label='Smart Casual (Female)',gender='female',tier='smart',   price=500  },
}
