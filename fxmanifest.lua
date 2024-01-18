fx_version 'cerulean'
game 'gta5'
author '_elvano'
lua54 'yes'

shared_script {
    "config.lua"
}

client_scripts {
    "client.lua"
}

server_scripts {
    "server.lua",
    '@oxmysql/lib/MySQL.lua',
}

escrow_ignore {
    'config.lua',
}