-- eonexis-settings — client
-- UI scale (slider 0.5–2.0), toggles, keybinds, Discord link, first-run flow

local KVP_PREFIX = 'eonexis_set_'
local nuiOpen    = false
local settings   = {
    scale   = 1.0,
    toggles = {},
}

-- ── Persistence ─────────────────────────────────────────────────────────────────

local function loadSettings()
    local rawScale = GetResourceKvpString(KVP_PREFIX .. 'scaleV')
    if rawScale and rawScale ~= '' then
        settings.scale = tonumber(rawScale) or 1.0
    end
    for _, t in ipairs(Config.Toggles) do
        local marker = GetResourceKvpString(KVP_PREFIX .. 'tset_' .. t.id)
        if marker == '1' then
            settings.toggles[t.id] = (GetResourceKvpInt(KVP_PREFIX .. 'toggle_' .. t.id) == 1)
        else
            settings.toggles[t.id] = t.default
        end
    end
end

local function saveScale(v)
    settings.scale = v
    SetResourceKvp(KVP_PREFIX .. 'scaleV', tostring(v))
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

-- ── Scale broadcast ──────────────────────────────────────────────────────────────

local function broadcastScale()
    local v = settings.scale
    TriggerEvent('eonexis-ui:scaleChanged', v)
    SendNUIMessage({ action = 'setScale', scale = v })
end

exports('getScale', function() return settings.scale end)
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
    local v = tonumber(data.value)
    if v then
        v = math.max(0.5, math.min(2.0, v))
        saveScale(v)
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
    local url = data.url or Config.LinkURL
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Open in browser', url, 'info', 9000)
    end
end)

RegisterNUICallback('finishFirstRun', function(_, cb)
    cb({})
    markConfigured()
    closeSettings()
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Settings', 'Saved! Reopen anytime with F7.', 'success', 5000)
    end
end)

RegisterNUICallback('close', function(_, cb)
    cb({})
    closeSettings()
end)

-- ── Keybinds ─────────────────────────────────────────────────────────────────────

RegisterCommand('settings', function()
    if nuiOpen then closeSettings() else openSettings(false) end
end, false)
RegisterKeyMapping('settings', 'Open Settings', 'keyboard', 'F7')
TriggerEvent('chat:addSuggestion', '/settings', 'Open your player settings')

-- ── Controller cursor ────────────────────────────────────────────────────────────

local cursorX, cursorY = 0.5, 0.5

CreateThread(function()
    while true do
        local sleep = 200
        if IsNuiFocused() and settings.toggles.controllerCursor ~= false and IsInputDisabled(2) then
            sleep = 0
            local rx = GetDisabledControlNormal(0, 220)
            local ry = GetDisabledControlNormal(0, 221)
            if math.abs(rx) > 0.08 or math.abs(ry) > 0.08 then
                cursorX = math.max(0.0, math.min(1.0, cursorX + rx * 0.012))
                cursorY = math.max(0.0, math.min(1.0, cursorY + ry * 0.012))
                SetCursorLocation(cursorX, cursorY)
                SendNUIMessage({ action = 'controllerCursor', x = cursorX, y = cursorY })
            end
            if IsDisabledControlJustPressed(0, 201) then
                SendNUIMessage({ action = 'controllerClick', x = cursorX, y = cursorY })
            end
            if IsDisabledControlJustPressed(0, 202) then
                SendNUIMessage({ action = 'controllerBack' })
            end
        end
        Wait(sleep)
    end
end)

-- ── Init ─────────────────────────────────────────────────────────────────────────

CreateThread(function()
    loadSettings()
    while not NetworkIsSessionStarted() do Wait(300) end
    Wait(4000)
    broadcastScale()
    if isFirstRun() then
        openSettings(true)
    end
end)

-- Re-apply scale when any NUI requests it
AddEventHandler('eonexis-ui:requestScale', function()
    broadcastScale()
end)

print('[eonexis-settings] loaded — client-side KVP settings, webapp link ready')
