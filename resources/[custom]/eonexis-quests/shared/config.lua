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
}
