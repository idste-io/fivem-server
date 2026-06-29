-- eonexis-economy — server
-- Central persistent data store for all player progress.
-- Data stored in data/players.json relative to this resource.
-- Other mods call exports to read/write player data.

local DATA_FILE = 'data/players.json'
local db = {}  -- in-memory: { [license] = playerRecord }

local function defaultRecord(name)
    return {
        name             = name or 'Unknown',
        cash             = Config.StartingCash,
        bank             = Config.StartingBank,
        job              = 'unemployed',
        ownedProperties  = {},
        ownedVehicles    = {},
        lastLocation     = nil,
        homeProperty     = nil,
        inventory        = {},
        joinCount        = 0,
    }
end

local function getLicense(src)
    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
end

-- ── Persistence ────────────────────────────────────────────────────────────────

local function loadDB()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if raw and #raw > 2 then
        local ok, parsed = pcall(json.decode, raw)
        if ok and parsed then db = parsed; return end
    end
    db = {}
    print('[eonexis-economy] No save file — starting fresh')
end

local function saveDB()
    local ok, encoded = pcall(json.encode, db)
    if ok then
        SaveResourceFile(GetCurrentResourceName(), DATA_FILE, encoded, -1)
    end
end

loadDB()

-- Auto-save
CreateThread(function()
    while true do
        Wait(Config.SaveInterval)
        saveDB()
    end
end)

-- ── Player session ──────────────────────────────────────────────────────────────

local function getRecord(src)
    local lic = getLicense(src)
    if not lic then return nil, nil end
    if not db[lic] then
        db[lic] = defaultRecord(GetPlayerName(src))
    end
    return db[lic], lic
end

AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    local lic = getLicense(src)
    if lic then
        if not db[lic] then db[lic] = defaultRecord(name) end
        db[lic].joinCount = (db[lic].joinCount or 0) + 1
        db[lic].name = name
    end
    deferrals.done()
end)

AddEventHandler('playerDropped', function()
    local rec = getRecord(source)
    if rec then saveDB() end
end)

-- Send player their data on spawn
RegisterNetEvent('eonexis-economy:requestData')
AddEventHandler('eonexis-economy:requestData', function()
    local src = source
    local rec = getRecord(src)
    if rec then
        TriggerClientEvent('eonexis-economy:receiveData', src, {
            cash  = rec.cash,
            bank  = rec.bank,
            job   = rec.job,
        })
    end
end)

-- ── Server Exports ──────────────────────────────────────────────────────────────

exports('getMoney', function(src)
    local rec = getRecord(src)
    return rec and rec.cash or 0
end)

exports('getBank', function(src)
    local rec = getRecord(src)
    return rec and rec.bank or 0
end)

exports('hasMoney', function(src, amount)
    local rec = getRecord(src)
    return rec and rec.cash >= amount
end)

exports('addMoney', function(src, amount, reason)
    local rec = getRecord(src)
    if not rec then return false end
    rec.cash = rec.cash + amount
    TriggerClientEvent('eonexis-economy:updateCash', src, rec.cash)
    if reason then print(('[economy] +$%d to %s — %s'):format(amount, GetPlayerName(src), reason)) end
    return true
end)

exports('removeMoney', function(src, amount, reason)
    local rec = getRecord(src)
    if not rec or rec.cash < amount then return false end
    rec.cash = rec.cash - amount
    TriggerClientEvent('eonexis-economy:updateCash', src, rec.cash)
    if reason then print(('[economy] -$%d from %s — %s'):format(amount, GetPlayerName(src), reason)) end
    return true
end)

exports('addBank', function(src, amount)
    local rec = getRecord(src)
    if not rec then return false end
    rec.bank = rec.bank + amount
    TriggerClientEvent('eonexis-economy:updateBank', src, rec.bank)
    return true
end)

exports('removeBank', function(src, amount)
    local rec = getRecord(src)
    if not rec or rec.bank < amount then return false end
    rec.bank = rec.bank - amount
    TriggerClientEvent('eonexis-economy:updateBank', src, rec.bank)
    return true
end)

exports('getJob', function(src)
    local rec = getRecord(src)
    return rec and rec.job or 'unemployed'
end)

exports('setJob', function(src, job)
    local rec = getRecord(src)
    if not rec then return end
    rec.job = job
    TriggerClientEvent('eonexis-economy:updateJob', src, job)
end)

exports('getPlayerData', function(src)
    local rec = getRecord(src)
    if not rec then return nil end
    return {
        cash            = rec.cash,
        bank            = rec.bank,
        job             = rec.job,
        ownedProperties = rec.ownedProperties,
        ownedVehicles   = rec.ownedVehicles,
        lastLocation    = rec.lastLocation,
        homeProperty    = rec.homeProperty,
        inventory       = rec.inventory,
    }
end)

exports('setLastLocation', function(src, coords)
    local rec = getRecord(src)
    if not rec then return end
    rec.lastLocation = { x = coords.x, y = coords.y, z = coords.z, h = coords.w or 0.0 }
end)

exports('setHome', function(src, propId)
    local rec = getRecord(src)
    if not rec then return end
    rec.homeProperty = propId
end)

exports('getHome', function(src)
    local rec = getRecord(src)
    return rec and rec.homeProperty or nil
end)

exports('addProperty', function(src, propId)
    local rec = getRecord(src)
    if not rec then return false end
    for _, v in ipairs(rec.ownedProperties) do
        if v == propId then return false end  -- already owned
    end
    table.insert(rec.ownedProperties, propId)
    return true
end)

exports('removeProperty', function(src, propId)
    local rec = getRecord(src)
    if not rec then return end
    for i, v in ipairs(rec.ownedProperties) do
        if v == propId then table.remove(rec.ownedProperties, i); return end
    end
end)

exports('ownsProperty', function(src, propId)
    local rec = getRecord(src)
    if not rec then return false end
    for _, v in ipairs(rec.ownedProperties) do
        if v == propId then return true end
    end
    return false
end)

exports('addVehicle', function(src, model)
    local rec = getRecord(src)
    if not rec then return false end
    table.insert(rec.ownedVehicles, model)
    return true
end)

exports('removeVehicle', function(src, model)
    local rec = getRecord(src)
    if not rec then return end
    for i, v in ipairs(rec.ownedVehicles) do
        if v == model then table.remove(rec.ownedVehicles, i); return end
    end
end)

exports('getOwnedVehicles', function(src)
    local rec = getRecord(src)
    return rec and rec.ownedVehicles or {}
end)

exports('addItem', function(src, item, qty)
    local rec = getRecord(src)
    if not rec then return end
    rec.inventory[item] = (rec.inventory[item] or 0) + (qty or 1)
end)

exports('removeItem', function(src, item, qty)
    local rec = getRecord(src)
    if not rec then return false end
    local have = rec.inventory[item] or 0
    qty = qty or 1
    if have < qty then return false end
    rec.inventory[item] = have - qty
    if rec.inventory[item] <= 0 then rec.inventory[item] = nil end
    return true
end)

exports('getInventory', function(src)
    local rec = getRecord(src)
    return rec and rec.inventory or {}
end)

-- ── Commands ────────────────────────────────────────────────────────────────────

RegisterCommand('balance', function(src)
    local rec = getRecord(src)
    if not rec then return end
    TriggerClientEvent('eonexis-economy:showBalance', src, rec.cash, rec.bank)
end, false)

RegisterCommand('deposit', function(src, args)
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        TriggerClientEvent('eonexis-economy:notify', src, 'Usage: /deposit <amount>', 'error')
        return
    end
    local rec = getRecord(src)
    if not rec or rec.cash < amount then
        TriggerClientEvent('eonexis-economy:notify', src, 'Not enough cash.', 'error')
        return
    end
    rec.cash = rec.cash - amount
    rec.bank = rec.bank + amount
    TriggerClientEvent('eonexis-economy:updateCash', src, rec.cash)
    TriggerClientEvent('eonexis-economy:updateBank', src, rec.bank)
    TriggerClientEvent('eonexis-economy:notify', src, ('Deposited %s%d into bank.'):format(Config.CurrencySymbol, amount), 'success')
end, false)

RegisterCommand('withdraw', function(src, args)
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        TriggerClientEvent('eonexis-economy:notify', src, 'Usage: /withdraw <amount>', 'error')
        return
    end
    local rec = getRecord(src)
    if not rec or rec.bank < amount then
        TriggerClientEvent('eonexis-economy:notify', src, 'Not enough in bank.', 'error')
        return
    end
    rec.bank = rec.bank - amount
    rec.cash = rec.cash + amount
    TriggerClientEvent('eonexis-economy:updateCash', src, rec.cash)
    TriggerClientEvent('eonexis-economy:updateBank', src, rec.bank)
    TriggerClientEvent('eonexis-economy:notify', src, ('Withdrew %s%d from bank.'):format(Config.CurrencySymbol, amount), 'success')
end, false)

RegisterCommand('pay', function(src, args)
    local targetId = tonumber(args[1])
    local amount   = tonumber(args[2])
    if not targetId or not amount or amount <= 0 then
        TriggerClientEvent('eonexis-economy:notify', src, 'Usage: /pay <id> <amount>', 'error')
        return
    end
    if not GetPlayerName(targetId) then
        TriggerClientEvent('eonexis-economy:notify', src, 'Player not found.', 'error')
        return
    end
    local fromRec = getRecord(src)
    if not fromRec or fromRec.cash < amount then
        TriggerClientEvent('eonexis-economy:notify', src, 'Not enough cash.', 'error')
        return
    end
    fromRec.cash = fromRec.cash - amount
    TriggerClientEvent('eonexis-economy:updateCash', src, fromRec.cash)
    exports['eonexis-economy']:addMoney(targetId, amount, 'player payment')
    TriggerClientEvent('eonexis-economy:notify', src,
        ('Paid %s%d to %s.'):format(Config.CurrencySymbol, amount, GetPlayerName(targetId)), 'success')
    TriggerClientEvent('eonexis-economy:notify', targetId,
        ('Received %s%d from %s.'):format(Config.CurrencySymbol, amount, GetPlayerName(src)), 'info')
end, false)

-- Save location every 30s for last-location spawn
CreateThread(function()
    while true do
        Wait(30000)
        for _, pid in ipairs(GetPlayers()) do
            local src = tonumber(pid)
            TriggerClientEvent('eonexis-economy:requestLocation', src)
        end
    end
end)

RegisterNetEvent('eonexis-economy:saveLocation')
AddEventHandler('eonexis-economy:saveLocation', function(x, y, z, h)
    local rec = getRecord(source)
    if rec then
        rec.lastLocation = { x = x, y = y, z = z, h = h }
    end
end)

TriggerEvent('chat:addSuggestion', '/balance',  'Show your cash and bank balance', {})
TriggerEvent('chat:addSuggestion', '/deposit',  'Deposit cash to bank', {{ name='amount', help='Amount' }})
TriggerEvent('chat:addSuggestion', '/withdraw', 'Withdraw from bank', {{ name='amount', help='Amount' }})
TriggerEvent('chat:addSuggestion', '/pay',      'Pay another player', {{ name='id', help='Player ID' }, { name='amount', help='Amount' }})
