Config = {}

-- FiveM control IDs for Xbox controller:
-- DPAD_UP=172, DPAD_DOWN=173, DPAD_LEFT=174, DPAD_RIGHT=175
-- LB=200, RB=201, LT=204, RT=205, X/Square=76, Y/Triangle=246
-- START=199, BACK/SELECT=196, LS=98, RS=99
-- A/Cross=38 (same as E), B/Circle=194 (same as Backspace)

-- Dpad actions (hold LB to switch to emote mode)
Config.DpadNormal = {
    UP    = 'work',         -- DPAD UP → /work (get task)
    DOWN  = 'balance',      -- DPAD DOWN → /balance
    LEFT  = 'jobcenter',    -- DPAD LEFT → open job center
    RIGHT = 'garage',       -- DPAD RIGHT → open garage (when near)
}

Config.DpadEmote = {
    UP    = 'wave',
    DOWN  = 'sit',
    LEFT  = 'dance',
    RIGHT = 'thumbsup',
}

-- Quick emotes on LB+face buttons (without dpad)
Config.FaceEmotes = {
    X        = 'clap',      -- LB + X
    Y        = 'salute',    -- LB + Y  (Xbox Y / PS Triangle)
}
