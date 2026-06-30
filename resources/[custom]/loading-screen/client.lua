-- loading-screen — client
-- The manifest uses `loadscreen_manual_shutdown 'yes'`, so the loading screen will
-- stay up FOREVER unless we explicitly dismiss it. This dismisses it once the
-- player's session has started, with a hard safety timeout as a fallback.

local dismissed = false

local function dismiss()
    if dismissed then return end
    dismissed = true
    ShutdownLoadingScreenNui()
end

CreateThread(function()
    -- Wait until the network session is actually started
    local waited = 0
    while not NetworkIsSessionStarted() do
        Wait(200)
        waited = waited + 200
        if waited > 60000 then break end  -- safety: never wait more than 60s
    end
    -- Let the spawn selector NUI mount first so there's no black flash
    Wait(500)
    dismiss()
end)

-- Hard fallback: no matter what, dismiss after 90 seconds so nobody is ever stuck
CreateThread(function()
    Wait(90000)
    dismiss()
end)

-- Allow other resources to force-dismiss the loading screen
RegisterNetEvent('loading-screen:dismiss')
AddEventHandler('loading-screen:dismiss', dismiss)
exports('dismiss', dismiss)
