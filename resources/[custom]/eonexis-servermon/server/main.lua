-- eonexis-servermon — server
-- Reads FiveM server logs, extracts errors, posts to Discord via webhook

local lastSeen  = {}  -- dedup: hash → true
local startTime = os.time()

local function getWebhook()
    if Config.WebhookUrl and Config.WebhookUrl ~= '' then
        return Config.WebhookUrl
    end
    -- Fall back to eonexis-discord-notify webhook
    local ok, url = pcall(function()
        return exports['eonexis-discord-notify']:getWebhookUrl()
    end)
    return (ok and url) or nil
end

local function containsIgnore(line)
    for _, p in ipairs(Config.IgnorePatterns) do
        if line:find(p, 1, true) then return true end
    end
    return false
end

local function containsError(line)
    for _, p in ipairs(Config.ErrorPatterns) do
        if line:find(p, 1, true) then return true end
    end
    return false
end

local function hash(s)
    local h = 0
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 2147483647 end
    return tostring(h)
end

local function postToDiscord(errors)
    local webhook = getWebhook()
    if not webhook or webhook == '' then
        print('[servermon] No webhook configured — skipping Discord post')
        return
    end

    local lines = {}
    for i, e in ipairs(errors) do
        if i > 10 then
            table.insert(lines, string.format('…and %d more errors', #errors - 10))
            break
        end
        -- Truncate each line
        local line = e:sub(1, 200)
        table.insert(lines, '`' .. line .. '`')
    end

    local body = json.encode({
        username   = 'Eonexis Monitor',
        avatar_url = '',
        embeds = {{
            title       = '⚠️ Server Errors Detected',
            description = table.concat(lines, '\n'),
            color       = 16744272,  -- orange
            footer      = { text = 'eonexis-servermon | ' .. os.date('%H:%M UTC') },
        }}
    })

    PerformHttpRequest(webhook, function(status)
        if status ~= 204 and status ~= 200 then
            print('[servermon] Webhook post failed: ' .. tostring(status))
        end
    end, 'POST', body, { ['Content-Type'] = 'application/json' })
end

local function scanLogs()
    -- Read last 200 lines of journalctl output for fivem
    -- FiveM exposes GetConvar but not log file path; use os.execute via citizen
    -- We trigger a shell command and read output
    local tmpFile = '/tmp/eonexis_servermon_scan.txt'
    os.execute(string.format(
        'journalctl -u fivem --no-pager -n 200 --output=cat > %s 2>/dev/null',
        tmpFile
    ))

    local f = io.open(tmpFile, 'r')
    if not f then return end
    local content = f:read('*a')
    f:close()
    os.remove(tmpFile)

    local errors = {}
    for line in content:gmatch('[^\n]+') do
        if containsError(line) and not containsIgnore(line) then
            local h = hash(line)
            if not lastSeen[h] then
                lastSeen[h] = true
                table.insert(errors, line)
            end
        end
    end

    if #errors > 0 then
        print(string.format('[servermon] Found %d new error(s)', #errors))
        postToDiscord(errors)
    end

    -- Prune dedup cache if it gets large
    local count = 0
    for _ in pairs(lastSeen) do count = count + 1 end
    if count > 500 then lastSeen = {} end
end

-- Wait 30s for server to stabilize, then scan on interval
CreateThread(function()
    Wait(30000)
    while true do
        local ok, err = pcall(scanLogs)
        if not ok then
            print('[servermon] Scan error: ' .. tostring(err))
        end
        Wait(Config.ScanInterval * 1000)
    end
end)

-- Also expose a manual scan command (server console only)
RegisterCommand('scanerrors', function(src)
    if src ~= 0 then return end
    print('[servermon] Manual scan triggered')
    lastSeen = {}  -- clear dedup so we see everything fresh
    local ok, err = pcall(scanLogs)
    if not ok then print('[servermon] Scan error: ' .. tostring(err)) end
end, true)
