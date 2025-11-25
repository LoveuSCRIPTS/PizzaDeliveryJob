fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Pizza Delivery Job'
author 'Lovu'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target' 
}