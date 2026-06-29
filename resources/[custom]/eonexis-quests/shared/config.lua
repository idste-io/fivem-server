Config = {}
Config.DataFile = 'data/quests.json'

--[[
  Quest definition fields:
    id        — unique string
    title     — display name
    desc      — lore description
    category  — 'story' | 'side' | 'criminal'
    requires  — list of quest IDs that must be complete first
    reward    — { cash=N }
    objectives — list of { id, text, trigger }
      trigger types:
        'auto'       — completes instantly when quest starts
        'event'      — fires when game event (eventName) is triggered
        'location'   — fires when player approaches pos within radius
        'server'     — fired by server event (eonexis-quests:objectiveDone)
]]

Config.Quests = {
    -- ══ STORY ══
    {
        id       = 'welcome',
        title    = 'Welcome to Eonexis',
        desc     = 'You\'ve arrived in Los Santos. The city is full of opportunity — and danger. Make it your own.',
        category = 'story',
        requires = {},
        reward   = { cash = 500 },
        objectives = {
            { id='spawn',    text='Arrive in Los Santos',           trigger='auto' },
        },
    },
    {
        id       = 'know_the_rules',
        title    = 'Know the Rules',
        desc     = 'Every city has rules. Eonexis is no different. Check the rules board before you do anything stupid.',
        category = 'story',
        requires = { 'welcome' },
        reward   = { cash = 300 },
        objectives = {
            { id='rules',    text='Open the rules board (F2 or /rules)', trigger='event', eventName='eonexis-rules:opened' },
        },
    },
    {
        id       = 'first_dollar',
        title    = 'First Dollar',
        desc     = 'Money makes the world go round. Get to work and earn your first paycheck.',
        category = 'story',
        requires = { 'know_the_rules' },
        reward   = { cash = 1500 },
        objectives = {
            { id='balance',  text='Check your balance (/balance)',   trigger='event', eventName='eonexis-economy:balanceChecked' },
            { id='job_task', text='Complete a /work job task',       trigger='server', key='job_task_done' },
        },
    },
    {
        id       = 'the_grind',
        title    = 'The Grind',
        desc     = 'One task was just a warmup. The real money comes from putting in the work.',
        category = 'story',
        requires = { 'first_dollar' },
        reward   = { cash = 3000 },
        objectives = {
            { id='tasks5',   text='Complete 5 job tasks total',      trigger='server', key='job_tasks_5' },
            { id='earn10k',  text='Accumulate $10,000 cash',         trigger='server', key='earn_10k' },
        },
    },

    -- ══ SIDE ══
    {
        id       = 'petrolhead',
        title    = 'Petrolhead',
        desc     = 'Every true Los Santos resident needs wheels. Visit the dealership and get yourself something nice.',
        category = 'side',
        requires = {},
        reward   = { cash = 2000 },
        objectives = {
            { id='dealership', text='Visit Premium Deluxe Motorsport',    trigger='location', pos=vector3(-46.0,-1097.0,26.0), radius=30.0 },
            { id='buy_car',    text='Purchase a vehicle',                  trigger='server', key='vehicle_purchased' },
        },
    },
    {
        id       = 'high_roller',
        title    = 'High Roller',
        desc     = 'The Diamond Casino beckons. Try your luck at the Lucky Wheel — fortune favors the bold.',
        category = 'side',
        requires = {},
        reward   = { cash = 1500 },
        objectives = {
            { id='casino',   text='Visit the Diamond Casino',        trigger='location', pos=vector3(897.0,48.0,81.0), radius=40.0 },
            { id='spin',     text='Spin the Lucky Wheel',            trigger='server', key='casino_spun' },
        },
    },
    {
        id       = 'property_dreams',
        title    = 'Property Dreams',
        desc     = 'Rent is for suckers. Buy yourself a piece of Los Santos and call it home.',
        category = 'side',
        requires = { 'first_dollar' },
        reward   = { cash = 5000 },
        objectives = {
            { id='buy_prop', text='Purchase a house or business',    trigger='server', key='property_purchased' },
        },
    },
    {
        id       = 'social_butterfly',
        title    = 'Social Butterfly',
        desc     = 'Los Santos is more fun with friends. Express yourself and share the wealth.',
        category = 'side',
        requires = {},
        reward   = { cash = 1000 },
        objectives = {
            { id='emote',    text='Use an emote (/e wave)',          trigger='server', key='emote_used' },
            { id='pay',      text='Pay another player (/pay)',       trigger='server', key='player_paid' },
        },
    },
    {
        id       = 'daily_dedication',
        title    = 'Daily Dedication',
        desc     = 'Show up every day. The city rewards those who are consistent.',
        category = 'side',
        requires = {},
        reward   = { cash = 2000 },
        objectives = {
            { id='daily1',   text='Claim your daily bonus (/daily)', trigger='server', key='daily_claimed' },
            { id='phone',    text='Open your smartphone (P key)',    trigger='event', eventName='eonexis-phone:opened' },
        },
    },

    -- More story
    {
        id       = 'on_the_road',
        title    = 'On the Road',
        desc     = 'Los Santos is huge. Explore the different districts and get your bearings.',
        category = 'story',
        requires = { 'first_dollar' },
        reward   = { cash = 2000 },
        objectives = {
            { id='visit_vinewood', text='Visit Vinewood Boulevard',   trigger='location', pos=vector3(215.0, 173.0, 105.0), radius=40.0 },
            { id='visit_lsia',     text='Explore LSIA',               trigger='location', pos=vector3(-1034.0,-2737.0,13.0), radius=60.0 },
            { id='visit_port',     text='Check out the port',         trigger='location', pos=vector3(800.0,  -2970.0, 6.0),  radius=60.0 },
        },
    },
    {
        id       = 'licensed_and_loaded',
        title    = 'Licensed and Loaded',
        desc     = 'A real professional earns credentials. Get yourself a job license and level up your career.',
        category = 'story',
        requires = { 'the_grind' },
        reward   = { cash = 4000 },
        objectives = {
            { id='buy_lic',    text='Purchase any job license',        trigger='server', key='license_purchased' },
            { id='use_job',    text='Complete a task with that job',   trigger='server', key='job_task_done' },
        },
    },
    {
        id       = 'man_of_the_house',
        title    = 'Man of the House',
        desc     = 'You\'ve got a place to call home. Now set it as your spawn and make it official.',
        category = 'story',
        requires = { 'property_dreams' },
        reward   = { cash = 3000 },
        objectives = {
            { id='sethome',    text='Set your home as spawn point',   trigger='server', key='home_set' },
            { id='spawn_home', text='Spawn at your home',             trigger='server', key='spawned_home' },
        },
    },

    -- ══ SIDE ══
    {
        id       = 'petrolhead',
        title    = 'Petrolhead',
        desc     = 'Every true Los Santos resident needs wheels. Visit the dealership and get yourself something nice.',
        category = 'side',
        requires = {},
        reward   = { cash = 2000 },
        objectives = {
            { id='dealership', text='Visit Premium Deluxe Motorsport',    trigger='location', pos=vector3(-46.0,-1097.0,26.0), radius=30.0 },
            { id='buy_car',    text='Purchase a vehicle',                  trigger='server', key='vehicle_purchased' },
        },
    },
    {
        id       = 'high_roller',
        title    = 'High Roller',
        desc     = 'The Diamond Casino beckons. Try your luck at the Lucky Wheel — fortune favors the bold.',
        category = 'side',
        requires = {},
        reward   = { cash = 1500 },
        objectives = {
            { id='casino',   text='Visit the Diamond Casino',        trigger='location', pos=vector3(897.0,48.0,81.0), radius=40.0 },
            { id='spin',     text='Spin the Lucky Wheel',            trigger='server', key='casino_spun' },
        },
    },
    {
        id       = 'property_dreams',
        title    = 'Property Dreams',
        desc     = 'Rent is for suckers. Buy yourself a piece of Los Santos and call it home.',
        category = 'side',
        requires = { 'first_dollar' },
        reward   = { cash = 5000 },
        objectives = {
            { id='buy_prop', text='Purchase a house or business',    trigger='server', key='property_purchased' },
        },
    },
    {
        id       = 'social_butterfly',
        title    = 'Social Butterfly',
        desc     = 'Los Santos is more fun with friends. Express yourself and share the wealth.',
        category = 'side',
        requires = {},
        reward   = { cash = 1000 },
        objectives = {
            { id='emote',    text='Use an emote (/e wave)',          trigger='server', key='emote_used' },
            { id='pay',      text='Pay another player (/pay)',       trigger='server', key='player_paid' },
        },
    },
    {
        id       = 'daily_dedication',
        title    = 'Daily Dedication',
        desc     = 'Show up every day. The city rewards those who are consistent.',
        category = 'side',
        requires = {},
        reward   = { cash = 2000 },
        objectives = {
            { id='daily1',   text='Claim your daily bonus (/daily)', trigger='server', key='daily_claimed' },
            { id='phone',    text='Open your smartphone (P key)',    trigger='event', eventName='eonexis-phone:opened' },
        },
    },
    {
        id       = 'fuel_up',
        title    = 'Fill \'Er Up',
        desc     = 'Your car won\'t go far on empty. Find a gas station and fill up.',
        category = 'side',
        requires = { 'petrolhead' },
        reward   = { cash = 800 },
        objectives = {
            { id='gas',   text='Fill up at a gas station',           trigger='server', key='fuel_filled' },
        },
    },
    {
        id       = 'catch_of_the_day',
        title    = 'Catch of the Day',
        desc     = 'The ocean is full of opportunity. Get a fishing license and try your luck.',
        category = 'side',
        requires = {},
        reward   = { cash = 1800 },
        objectives = {
            { id='lic_fish', text='Buy a Fishing License at the pier', trigger='server', key='license_purchased' },
            { id='fish',     text='Complete a fishing task',           trigger='server', key='job_task_done' },
        },
    },
    {
        id       = 'gourmet',
        title    = 'Gourmet',
        desc     = 'Don\'t go hungry in Los Santos. Visit every food joint in the city.',
        category = 'side',
        requires = {},
        reward   = { cash = 1200 },
        objectives = {
            { id='shop1', text='Visit a 24/7 store',                 trigger='location', pos=vector3(-714.9,-909.3,19.2),  radius=25.0 },
            { id='shop2', text='Visit a Burger Shot',                trigger='location', pos=vector3(-1193.0,-897.0,12.0), radius=25.0 },
            { id='shop3', text='Visit a Lucky Plucker',              trigger='location', pos=vector3(26.0,   -136.0,57.0), radius=25.0 },
        },
    },
    {
        id       = 'discord_verified',
        title    = 'Verified Citizen',
        desc     = 'Link your Discord account and unlock server rewards and daily bonuses.',
        category = 'side',
        requires = {},
        reward   = { cash = 2500 },
        objectives = {
            { id='link',   text='Type /link in-game to start',       trigger='server', key='discord_linked' },
        },
    },

    -- ══ CRIMINAL ══
    {
        id       = 'five_finger_discount',
        title    = 'Five Finger Discount',
        desc     = 'The 24/7 always has what you need — and sometimes you just can\'t afford to pay. Arm yourself and take it.',
        category = 'criminal',
        requires = {},
        reward   = { cash = 3000 },
        objectives = {
            { id='getweapon', text='Acquire a weapon',              trigger='server', key='has_weapon' },
            { id='rob_store', text='Rob a convenience store',       trigger='server', key='robbery_success' },
        },
    },
    {
        id       = 'street_legend',
        title    = 'Street Legend',
        desc     = 'Forget the track — real racing happens on the streets of LS. Find a race and show them what you\'ve got.',
        category = 'criminal',
        requires = {},
        reward   = { cash = 2500 },
        objectives = {
            { id='join_race',   text='Join a street race',          trigger='server', key='race_joined' },
            { id='finish_race', text='Finish a street race',        trigger='server', key='race_finished' },
        },
    },
    {
        id       = 'wanted_man',
        title    = 'Wanted Man',
        desc     = 'Every criminal has their first wanted level. Let\'s see if you can shake the cops.',
        category = 'criminal',
        requires = { 'five_finger_discount' },
        reward   = { cash = 4500 },
        objectives = {
            { id='wanted',   text='Get a 2-star wanted level',      trigger='server', key='wanted_2star' },
            { id='escape',   text='Lose the police',                trigger='server', key='wanted_evaded' },
        },
    },
    {
        id       = 'kingpin',
        title    = 'Kingpin',
        desc     = 'You\'ve made your mark on the streets. Now own it — businesses, property, and respect.',
        category = 'criminal',
        requires = { 'wanted_man', 'street_legend' },
        reward   = { cash = 10000 },
        objectives = {
            { id='business', text='Own a business property',        trigger='server', key='business_owned' },
            { id='rich',     text='Have $50,000 in the bank',       trigger='server', key='bank_50k' },
        },
    },
}
