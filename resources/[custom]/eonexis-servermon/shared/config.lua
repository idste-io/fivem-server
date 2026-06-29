Config = {}

-- How often to scan logs (seconds)
Config.ScanInterval = 120

-- Only report errors newer than this many seconds
Config.LookbackWindow = 130

-- Discord webhook for error reports (set in VPS env or use eonexis-discord-notify)
Config.WebhookUrl = ''  -- leave empty to use the notify mod's webhook

-- Minimum severity to report: 'error', 'warning', 'all'
Config.MinSeverity = 'error'

-- Patterns that indicate errors in logs
Config.ErrorPatterns = {
    'SCRIPT ERROR',
    'SCRIPT WARNING',
    'Error loading',
    'Failed to load',
    'Error running',
    'Execution of native',
    'citizen/ error',
    'Unhandled exception',
}

-- Patterns to ignore (spam suppression)
Config.IgnorePatterns = {
    'setDataHandler',  -- known non-critical
    'heartbeat',
    'txAdmin',
}
