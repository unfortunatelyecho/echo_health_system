fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'ECHO'
description 'Advanced Health & Survival System - Organs, Mental Health, Addiction'
version '2.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/organs.lua',
    'server/mental_health.lua',
    'server/addiction.lua'
}

client_scripts {
    'client/main.lua',
    'client/organs.lua',
    'client/mental_health.lua',
    'client/addiction.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'oxmysql'
}