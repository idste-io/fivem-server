Config = {}

Config.BaseReward    = 500     -- base daily reward
Config.StreakBonus   = 250     -- extra per day of streak
Config.MaxStreakDays = 7       -- streak resets after 7 days (weekly cycle)
Config.DataFile      = 'data/daily.json'

-- Reward table: day 1-7
Config.DayRewards = {
    [1] = { cash=500,  label='Day 1 — Welcome Back!' },
    [2] = { cash=750,  label='Day 2 — Keeping it up!' },
    [3] = { cash=1000, label='Day 3 — Streak going!' },
    [4] = { cash=1250, label='Day 4 — Nice streak!' },
    [5] = { cash=1500, label='Day 5 — Half way!' },
    [6] = { cash=1750, label='Day 6 — Almost there!' },
    [7] = { cash=2500, label='Day 7 — PERFECT WEEK! Bonus!', bonus=true },
}
