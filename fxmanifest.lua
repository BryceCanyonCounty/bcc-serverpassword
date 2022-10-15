fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'

author 'Bytesizd'
description 'Protect your servers with a password on join!'

server_script {
    'server/config.lua',
    'server/server.lua'
}

client_script {
    'client/client.lua'
}

shared_script {
    'config.lua'
}

files {
    'ui/*',
    'ui/assets/*',
    'ui/assets/fonts/*'
}
    
ui_page 'ui/index.html'

version '1.0.0'