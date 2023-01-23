fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'

author 'Bytesizd'
description 'Protect your servers with a password on join!'

server_script {
    'config.lua',
    'server/server.lua'
}

dependency 'bcc-deferralcards'


version '2.0.0'