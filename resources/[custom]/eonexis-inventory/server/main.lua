-- eonexis-inventory — server (backed by eonexis-economy item storage)

local function notify(src, msg, t)
    TriggerClientEvent('eonexis-economy:notify', src, msg, t or 'info')
end

-- /inv — show inventory
RegisterCommand('inv', function(src)
    local inv = exports['eonexis-economy']:getInventory(src)
    local parts = {}
    for item, qty in pairs(inv) do
        table.insert(parts, string.format('%s x%d', item, qty))
    end
    local text = #parts > 0 and table.concat(parts, '  |  ') or 'Empty'
    notify(src, 'Inventory: ' .. text, 'info')
end, false)

-- /useitem <item>
RegisterCommand('useitem', function(src, args)
    local itemId = args[1]
    if not itemId then notify(src, 'Usage: /useitem <item>', 'error'); return end

    local itemDef = nil
    for _, v in ipairs(Config.Items) do
        if v.id == itemId then itemDef = v; break end
    end
    if not itemDef then notify(src, 'Unknown item.', 'error'); return end

    local ok = exports['eonexis-economy']:removeItem(src, itemId, 1)
    if not ok then notify(src, 'You do not have that item.', 'error'); return end

    if itemDef.heal and itemDef.heal > 0 then
        TriggerClientEvent('eonexis-inventory:heal', src, itemDef.heal)
        notify(src, string.format('Used %s — restored %d HP.', itemDef.label, itemDef.heal), 'success')
    else
        notify(src, string.format('Used %s.', itemDef.label), 'info')
    end
    -- Notify hunger mod so it can update hunger/thirst bars
    TriggerClientEvent('eonexis-hunger:itemUsed', src, itemId)
end, false)

TriggerEvent('chat:addSuggestion', '/inv',     'Show your inventory', {})
TriggerEvent('chat:addSuggestion', '/useitem', 'Use an item', {{ name='item', help='Item ID' }})
