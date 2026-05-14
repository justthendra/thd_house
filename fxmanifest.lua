fx_version 'cerulean'
game 'gta5'

author 'Thendra'
description 'QBCore uyumlu meta anahtarlı ev sistemi.'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

dependencies {
    'qb-core',
    'qb-target',
    'ox_lib'
}