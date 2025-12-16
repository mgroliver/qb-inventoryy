fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'qb-inventory'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_script 'client/main.lua'

ui_page {
	'html/ui.html'
}

files {
	'html/ui.html',
	'html/css/style.css',
	'html/js/app.js',
	'html/images/*.png',
	'html/images/*.jpg',
	'html/ammo_images/*.png',
	'html/attachment_images/*.png',
	'html/*.ttf',
	'html/*.otf',
	--'html/weapon_info.ogg',
	'html/assets/*.*',
	'html/sounds/*.mp3',
	'html/sounds/*.ogg',
	'html/sounds/*.wav'
}

dependency 'qb-weapons'