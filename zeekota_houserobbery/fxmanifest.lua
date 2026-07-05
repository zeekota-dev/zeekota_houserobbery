fx_version 'cerulean'
game 'gta5'

author 'ZeeKota'
description 'ZeeKota House Robbery - ESX/QBCore GTA interior house robbery system'
version '1.0.0'

lua54 'yes'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/bridge.lua'
}

client_scripts {
    'client/dispatch.lua',
    'client/interiors.lua',
    'client/peds.lua',
    'client/minigame.lua',
    'client/ui.lua',
    'client/client.lua'
}

server_scripts {
    'server/database.lua',
    'server/framework.lua',
    'server/dispatch.lua',
    'server/rewards.lua',
    'server/server.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/assets/*'
}

dependencies {
    'ox_lib',
    'ox_inventory'
}
