fx_version 'cerulean'
game 'gta5'

name "nmsh-supermarkets"
description "Fivem ownedable supermarkts"
author "Nmsh"
version "1.0.0"

shared_scripts {
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}

escrow_ignore {
	'shared/main.lua',  -- Only ignore one file
}

lua54 'yes'

dependency '/assetpacks'