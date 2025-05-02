fx_version 'cerulean'
game 'gta5'

author 'Y98'
description 'Y98 by ox lib Payment System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

dependencies {
    'ox_lib',
    'interact'
}

lua54 'yes'