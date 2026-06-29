Config = {}

Config.CasinoPos   = vector3(897.0, 48.0, 81.0)
Config.SpinCost    = 500    -- cost per wheel spin
Config.SpinCooldown = 3600  -- seconds between spins (1 hour)

-- Wheel segments — server picks one randomly weighted by weight
Config.Prizes = {
    { label='$200',     type='cash',    value=200,   weight=20, colour='#9b59b6' },
    { label='$500',     type='cash',    value=500,   weight=18, colour='#8e44ad' },
    { label='$1,000',   type='cash',    value=1000,  weight=14, colour='#2ecc71' },
    { label='$2,500',   type='cash',    value=2500,  weight=10, colour='#27ae60' },
    { label='$5,000',   type='cash',    value=5000,  weight=7,  colour='#f39c12' },
    { label='$10,000',  type='cash',    value=10000, weight=4,  colour='#e67e22' },
    { label='$25,000',  type='cash',    value=25000, weight=2,  colour='#e74c3c' },
    { label='Car Prize',type='vehicle', value=0,     weight=3,  colour='#3498db' },
    { label='NOTHING',  type='nothing', value=0,     weight=15, colour='#2c3e50' },
    { label='Jackpot!', type='cash',    value=50000, weight=1,  colour='#f1c40f' },
}
