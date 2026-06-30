-- loading-screen — client
-- loadscreen_manual_shutdown 'yes' means the screen NEVER closes unless we call
-- ShutdownLoadingScreenNui(). We call it from three separate paths so it always fires.

local dismissed = false

local function dismiss()
    if dismissed then return end
    dismissed = true
    ShutdownLoadingScreenNui()
    print('[loading-screen] dismissed')
end

-- Path 1: as soon as game type starts (most reliable on vanilla FiveM)
AddEventHandler('onClientGameTypeStart', function()
    Wait(2000)  -- small buffer so spawn NUI can mount
    dismiss()
end)

-- Path 2: once network session is established
CreateThread(function()
    local waited = 0
    while not NetworkIsSessionStarted() do
        Wait(200)
        waited = waited + 200
        if waited > 45000 then break end
    end
    Wait(500)
    dismiss()
end)

-- Path 3: absolute hard fallback — 60 seconds no matter what
CreateThread(function()
    Wait(60000)
    dismiss()
end)

-- Allow other resources or server to force-dismiss
RegisterNetEvent('loading-screen:dismiss')
AddEventHandler('loading-screen:dismiss', dismiss)
exports('dismiss', dismiss)
