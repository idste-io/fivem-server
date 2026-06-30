fx_version 'cerulean'
game 'gta5'

name 'loading-screen'
description 'Eonexis loading screen'
version '1.0.0'
author 'Eonexis'

loadscreen 'html/index.html'
-- No manual_shutdown: FiveM auto-dismisses once the session starts.
-- client.lua still calls ShutdownLoadingScreenNui as a safety net.
loadscreen_manual_shutdown 'yes'

client_script 'client.lua'

file 'html/index.html'
file 'html/style.css'
file 'html/script.js'
