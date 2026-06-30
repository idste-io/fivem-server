-- eonexis-settings — client
-- Player settings: UI scale (first-run chooser + editable), keybinds, controller
-- cursor support for NUIs, Discord link button, game toggles. Persisted via KVP.

local KVP_PREFIX = 'eonexis_set_'
local nuiOpen    = false
local settings   = {
    scale   = Config.DefaultScale,
    toggles = {},
}

-- ── Persistence (client-side KVP) ──────────────────────────────────────────────

local function loadSettings()
    local rawScale = GetResourceKvpString(KVP_PREFIX .. 'scale')
    if rawScale and rawScale ~= '' then settings.scale = rawScale end
    for _, t in ipairs(Config.Toggles) do
        local v = GetResourceKvpInt(KVP_PREFIX .. 'toggle_' .. t.id)
        -- KVP returns 0 if unset; distinguish via a "set" marker
        local marker = GetResourceKvpString(KVP_PREFIX .. 'tset_' .. t.id)
        if marker == '1' then
            settings.toggles[t.id] = (v == 1)
        else
            settings.toggles[t.id] = t.default
        end
    end
end

local function saveScale(scaleId)
    settings.scale = scaleId
    SetResourceKvp(KVP_PREFIX .. 'scale', scaleId)
end

local function saveToggle(id, val)
    settings.toggles[id] = val
    SetResourceKvpInt(KVP_PREFIX .. 'toggle_' .. id, val and 1 or 0)
    SetResourceKvp(KVP_PREFIX .. 'tset_' .. id, '1')
end

local function isFirstRun()
    return GetResourceKvpString(KVP_PREFIX .. 'configured') ~= '1'
end

local function markConfigured()
    SetResourceKvp(KVP_PREFIX .. 'configured', '1')
end

-- ── Scale helpers ───────────────────────────────────────────────────────────────

local function scaleValue(id)
    for _, p in ipairs(Config.ScalePresets) do
        if p.id == id then return p.value end
    end
    return 1.0
end

-- Broadcast scale to all NUIs that opt in (and our own)
local function broadcastScale()
    local v = scaleValue(settings.scale)
    TriggerEvent('eonexis-ui:scaleChanged', v)
    SendNUIMessage({ action = 'setScale', scale = v })
end

exports('getScale', function() return scaleValue(settings.scale) end)
exports('getToggle', function(id) return settings.toggles[id] end)

-- ── NUI open/close ───────────────────────────────────────────────────────────────

local function openSettings(firstRun)
    if nuiOpen then return end
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action      = 'open',
        firstRun    = firstRun or false,
        scale       = settings.scale,
        scaleValue  = scaleValue(settings.scale),
        presets     = Config.ScalePresets,
        keybinds    = Config.Keybinds,
        toggles     = Config.Toggles,
        toggleState = settings.toggles,
        webapp      = Config.WebappURL,
        discord     = Config.DiscordURL,
        linkUrl     = Config.LinkURL,
    })
end

local function closeSettings()
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ── NUI callbacks ────────────────────────────────────────────────────────────────

RegisterNUICallback('setScale', function(data, cb)
    cb({})
    if data.scale then
        saveScale(data.scale)
        broadcastScale()
    end
end)

RegisterNUICallback('setToggle', function(data, cb)
    cb({})
    if data.id ~= nil then
        saveToggle(data.id, data.value and true or false)
        TriggerEvent('eonexis-settings:toggleChanged', data.id, data.value and true or false)
    end
end)

RegisterNUICallback('openLink', function(data, cb)
    cb({})
    -- Show the URL as a notification so the player can open it (NUI cannot open browsers)
    local url = data.url or Config.LinkURL
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Open in browser', url, 'info', 9000)
    end
    print('[eonexis-settings] Link requested: ' .. url)
end)

RegisterNUICallback('finishFirstRun', function(_, cb)
    cb({})
    markConfigured()
    closeSettings()
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Settings', 'Saved! Reopen anytime with F7 or /settings.', 'success', 5000)
    end
end)

RegisterNUICallback('close', function(_, cb)
    cb({})
    closeSettings()
end)

-- ── Keybinds (rebindable in GTA Settings ▸ Key Bindings) ──────────────────────────

-- /settings + key
RegisterCommand('settings', function()
    if nuiOpen then closeSettings() else openSettings(false) end
end, false)
RegisterKeyMapping('settings', 'Open Settings', 'keyboard', 'F7')
TriggerEvent('chat:addSuggestion', '/settings', 'Open your player settings')

-- ── Controller cursor for NUIs ────────────────────────────────────────────────────
-- When any NUI has focus and the controller-cursor option is on, move the mouse
-- cursor with the right stick and let LB/RB scroll. Works on any NUI page.

local cursorX, cursorY = 0.5, 0.5

CreateThread(function()
    while true do
        local sleep = 200
        if IsNuiFocused() and settings.toggles.controllerCursor ~= false and IsInputDisabled(2) then
            -- IsInputDisabled(2) is true when using a controller
            sleep = 0
            local rx = GetDisabledControlNormal(0, 220) -- right stick X
            local ry = GetDisabledControlNormal(0, 221) -- right stick Y
            if math.abs(rx) > 0.08 or math.abs(ry) > 0.08 then
                cursorX = math.max(0.0, math.min(1.0, cursorX + rx * 0.012))
                cursorY = math.max(0.0, math.min(1.0, cursorY + ry * 0.012))
                SetCursorLocation(cursorX, cursorY)
                -- Drive the visual cursor in whichever NUI is listening
                SendNUIMessage({ action = 'controllerCursor', x = cursorX, y = cursorY })
            end
            -- A button (201) = left click into NUI at cursor
            if IsDisabledControlJustPressed(0, 201) then
                SendNUIMessage({ action = 'controllerClick', x = cursorX, y = cursorY })
            end
            -- B button (202) = back/close
            if IsDisabledControlJustPressed(0, 202) then
                SendNUIMessage({ action = 'controllerBack' })
            end
        end
        Wait(sleep)
    end
end)

-- ── First-run + init ──────────────────────────────────────────────────────────────

CreateThread(function()
    loadSettings()
    -- wait for session
    while not NetworkIsSessionStarted() do Wait(300) end
    Wait(4000)  -- let spawn/character finish first
    broadcastScale()
    if isFirstRun() then
        openSettings(true)
    end
end)

-- Re-apply scale whenever a NUI (re)opens and asks for it
RegisterNetEvent('eonexis-ui:requestScale')
AddEventHandler('eonexis-ui:requestScale', function()
    broadcastScale()
end)
