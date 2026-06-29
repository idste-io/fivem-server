Config = {}

Config.Labs = {
    { id='weed_farm',  name='Weed Farm',    pos=vector3(1047.0, -3175.0, 12.0), product='weed',    time=120, alertChance=0.10 },
    { id='meth_lab',   name='Meth Lab',     pos=vector3(1382.0,  3609.0, 38.0), product='meth',    time=180, alertChance=0.25 },
    { id='coke_house', name='Coke Stash',   pos=vector3(57.0,    3694.0, 40.0), product='cocaine', time=150, alertChance=0.20 },
}

Config.Dealers = {
    { pos=vector3(124.0,   -1284.0, 29.3) },
    { pos=vector3(-1393.0,  -592.0, 30.0) },
    { pos=vector3(700.0,    -995.0, 22.4) },
    { pos=vector3(221.0,     387.0, 103.0) },
}

Config.DrugPrices = {
    weed    = { min=300,  max=600  },
    cocaine = { min=800,  max=1500 },
    meth    = { min=1200, max=2000 },
}

Config.MarkerRadius = 3.0
