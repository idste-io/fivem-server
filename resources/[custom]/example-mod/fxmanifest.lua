fx_version 'cerulean'
game 'gta5'

name 'example-mod'
description 'Example Eonexis mod — rename this folder and update server.cfg to add it'
version '1.0.0'
author 'Eonexis'

client_scripts {
  'client/*.lua'
}

server_scripts {
  'server/*.lua'
}

shared_scripts {
  'shared/*.lua'
}
