Config = {}

Config.Workbenches = {
    { id='workshop_ls',    name='LS Workshop',    pos=vector3(609.0,  2760.0, 42.1) },
    { id='workshop_south', name='South LS Shop',  pos=vector3(116.0, -1918.0, 21.1) },
    { id='workshop_sandy', name='Sandy Workshop', pos=vector3(1984.0, 3774.0, 33.0) },
}

Config.MarkerRadius = 2.5

Config.Recipes = {
    { id='bandage',   label='Bandage',        icon='🩹', ingredients={ {item='medical_supplies', qty=2} },                                    result={item='bandage',   qty=2}, time=10 },
    { id='medkit',    label='Med Kit',         icon='🏥', ingredients={ {item='bandage', qty=3}, {item='medical_supplies', qty=1} },           result={item='medkit',    qty=1}, time=25 },
    { id='lockpick',  label='Lockpick',        icon='🔑', ingredients={ {item='metal_scrap', qty=3}, {item='tools', qty=1} },                  result={item='lockpick',  qty=1}, time=20 },
    { id='drill',     label='Drill',           icon='🔩', ingredients={ {item='metal_scrap', qty=5}, {item='tools', qty=2} },                  result={item='drill',     qty=1}, time=30 },
    { id='molotov',   label='Molotov',         icon='🔥', ingredients={ {item='fuel_can', qty=1}, {item='cloth', qty=2} },                    result={item='molotov',   qty=1}, time=15 },
    { id='armor_vest', label='Armor Vest',     icon='🛡️', ingredients={ {item='metal_scrap', qty=4}, {item='cloth', qty=3} },                 result={item='armor_vest', qty=1}, time=35 },
    { id='drug_kit',  label='Drug Supplies',   icon='💊', ingredients={ {item='medical_supplies', qty=3}, {item='tools', qty=1} },             result={item='drug_kit',  qty=2}, time=20 },
}
