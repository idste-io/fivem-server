-- eonexis-character — client

local nuiOpen    = false
local myChar     = nil
local isFirstTime = false

local function notify(msg, t)
    if exports['eonexis-notify'] then
        exports['eonexis-notify']:Notify('Character', msg, t or 'info', 5000)
    end
end

local function closeNUI()
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openNUI(char, outfits)
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'open',
        char     = char,
        outfits  = outfits,
        isNew    = (char == nil),
        nameCost = Config.NameChangeCost,
    })
end

-- ── Receive character from server ─────────────────────────────────────────────

RegisterNetEvent('eonexis-character:receive')
AddEventHandler('eonexis-character:receive', function(char)
    myChar = char
    if not char then
        -- First time — show creator
        isFirstTime = true
        openNUI(nil, Config.Outfits)
    end
end)

-- ── Saved callback ────────────────────────────────────────────────────────────

RegisterNetEvent('eonexis-character:saved')
AddEventHandler('eonexis-character:saved', function(char, isNew)
    myChar = char
    closeNUI()
    if isNew then
        notify('Welcome to Eonexis, ' .. char.name .. '!', 'success')
    end
    -- Apply outfit appearance
    TriggerEvent('eonexis-character:applyOutfit', char.outfit, char.gender)
end)

RegisterNetEvent('eonexis-character:error')
AddEventHandler('eonexis-character:error', function(msg)
    notify(msg, 'error')
end)

-- ── Apply outfit visuals ───────────────────────────────────────────────────────

local OUTFIT_COMPONENTS = {
    -- Male presets
    basic_m  = { ped = 'mp_m_freemode_01', clothes = { {11,0,0},{8,15,0},{6,1,0},{4,0,0},{3,0,0} } },
    casual_m = { ped = 'mp_m_freemode_01', clothes = { {11,20,0},{8,57,0},{6,19,0},{4,47,0},{3,4,0} } },
    smart_m  = { ped = 'mp_m_freemode_01', clothes = { {11,92,0},{8,33,0},{6,24,0},{4,30,0},{3,8,0} } },
    -- Female presets
    basic_f  = { ped = 'mp_f_freemode_01', clothes = { {11,0,0},{8,0,0},{6,0,0},{4,0,0},{3,0,0} } },
    casual_f = { ped = 'mp_f_freemode_01', clothes = { {11,5,0},{8,10,0},{6,5,0},{4,10,0},{3,2,0} } },
    smart_f  = { ped = 'mp_f_freemode_01', clothes = { {11,20,0},{8,25,0},{6,15,0},{4,20,0},{3,5,0} } },
}

AddEventHandler('eonexis-character:applyOutfit', function(outfitId, gender)
    local preset = OUTFIT_COMPONENTS[outfitId]
    if not preset then return end
    local ped = PlayerPedId()
    for _, comp in ipairs(preset.clothes) do
        SetPedComponentVariation(ped, comp[1], comp[2], comp[3], 2)
    end
end)

-- ── NUI callbacks ─────────────────────────────────────────────────────────────

RegisterNUICallback('saveCharacter', function(data, cb)
    cb({})
    TriggerServerEvent('eonexis-character:save', data)
end)

RegisterNUICallback('closeCharacter', function(_, cb)
    cb({})
    if isFirstTime then
        -- Allow skipping: auto-create a default character so the player is never trapped
        isFirstTime = false
        TriggerServerEvent('eonexis-character:save', {
            name   = GetPlayerName(PlayerId()),
            gender = 'male',
            outfit = 'basic_m',
            bio    = '',
        })
    end
    closeNUI()
end)

-- ── Load after spawn is fully done ────────────────────────────────────────────
-- Listen for sessionmanager:playerLoaded (fired by eonexis-spawn after spawn completes)
-- This ensures the spawn chooser NUI is already closed before we open character creator

AddEventHandler('sessionmanager:playerLoaded', function()
    Wait(1000)  -- brief pause after spawn
    TriggerServerEvent('eonexis-character:load')
end)

-- ── /mycharacter command ──────────────────────────────────────────────────────

RegisterCommand('mycharacter', function()
    if nuiOpen then closeNUI() return end
    openNUI(myChar, Config.Outfits)
end, false)
TriggerEvent('chat:addSuggestion', '/mycharacter', 'View or edit your character')

-- ── Export for phone app ──────────────────────────────────────────────────────

exports('getMyCharacter', function()
    return myChar
end)

exports('openCharacterCreator', function()
    if not nuiOpen then
        openNUI(myChar, Config.Outfits)
    end
end)
