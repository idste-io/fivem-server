fx_version 'cerulean'
game 'gta5'

name 'eonexis-spawn'
description 'Eonexis spawn selector — pick spawn point on join, Eonexis branded'
version '1.0.0'
author 'Eonexis'

client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
shared_scripts { 'shared/config.lua' }
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }
dependency 'spawnmanager'
