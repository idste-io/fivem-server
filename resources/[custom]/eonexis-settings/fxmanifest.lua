fx_version 'cerulean'
game 'gta5'
name 'eonexis-settings'
description 'Player settings: UI scale, keybinds, controller support, Discord link'
version '1.0.0'
author 'Eonexis'

client_scripts { 'client/*.lua' }
server_scripts { 'server/*.lua' }
shared_scripts  { 'shared/*.lua' }

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
