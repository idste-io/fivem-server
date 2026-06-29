Config = {}

-- Dealership location — Premium Deluxe Motorsport, Pillbox Hill
Config.DealershipPos = vector3(-46.4, -1097.0, 26.4)
Config.DealershipSpawn = vector3(-40.0, -1087.0, 26.4)  -- where bought car appears

-- Garage location — player retrieves owned vehicles here
Config.GaragePos   = vector3(-351.0, -133.0, 39.0)  -- near parking lot in Rockford
Config.GarageSpawn = vector3(-345.0, -127.0, 39.0)

Config.SellValue   = 0.55   -- 55% resale value

Config.Vehicles = {
    -- Economy
    { model='asea',       label='Declasse Asea',          price=8000,   category='Economy',    desc='Budget saloon, reliable starter car.' },
    { model='premier',    label='Declasse Premier',        price=12000,  category='Economy',    desc='Comfortable family sedan.' },
    { model='surge',      label='Dinka Surge',             price=18000,  category='Economy',    desc='Compact electric city car.' },
    -- Sports
    { model='sultan',     label='Karin Sultan',            price=35000,  category='Sports',     desc='Turbocharged rally-tuned beast.' },
    { model='jester3',    label='Dinka Jester Classic',    price=62000,  category='Sports',     desc='Japanese sports icon.' },
    { model='comet5',     label='Pfister Comet S2',        price=98000,  category='Sports',     desc='German engineering at its finest.' },
    { model='schlagen',   label='Pfister Schlagen GT',     price=165000, category='Sports',     desc='Agile GT with incredible handling.' },
    -- Supercars
    { model='t20',        label='Progen T20',              price=220000, category='Supercar',   desc='Iconic mid-engine supercar.' },
    { model='adder',      label='Truffade Adder',          price=390000, category='Supercar',   desc='The fastest production car in LS.' },
    { model='zentorno',   label='Pegassi Zentorno',        price=275000, category='Supercar',   desc='Italian hypercar with killer looks.' },
    -- SUVs
    { model='rebla',      label='Obey Rebla GTS',          price=42000,  category='SUV',        desc='Luxury SUV for city and off-road.' },
    { model='granger',    label='Declasse Granger',        price=28000,  category='SUV',        desc='Full-size American pickup.' },
    -- Motorcycles
    { model='bati',       label='Dinka Bati 801',          price=15000,  category='Motorcycle', desc='Agile sportbike for the brave.' },
    { model='hakuchou',   label='Shitzu Hakuchou',         price=22000,  category='Motorcycle', desc='Superbike straight from Japan.' },
    -- Vans / Utility
    { model='rumpo',      label='Bravado Rumpo Custom',    price=20000,  category='Van',        desc='Custom van for those who haul.' },
    { model='boxville2',  label='Brute Boxville',          price=14000,  category='Van',        desc='Delivery van for side jobs.' },
}
