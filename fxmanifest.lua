fx_version 'cerulean'
game 'gta5'

description 'SyS-Multicharacter'
version '1.0.0'

shared_scripts {'@qb-core/shared/locale.lua', 'locales/en.lua', 'locales/*.lua', 'config.lua'}
client_script 'client/main.lua'
server_scripts {'@oxmysql/lib/MySQL.lua', '@qb-apartments/config.lua', 'server/main.lua'}

ui_page 'html/index.html'

files {"html/js/*", 'html/assets/*.png', 'html/assets/hover.mp3', 'html/index.html', 'html/css/*'}

dependencies {'qb-core', 'qb-spawn'}

escrow_ignore {'config.lua', 'client/*.lua', 'server/*.lua', 'locales/*.lua', 'README.md'}

lua54 'yes'

dependency '/assetpacks'
dependency '/assetpacks'