brew install lua luarocks mjolnir

mkdir ~/.luarocks
echo 'rocks_servers = { "http://rocks.moonscript.org" }' >> ~/.luarocks/config.lua

luarocks install mjolnir.fnutils
luarocks install mjolnir.geometry
luarocks install mjolnir.screen
luarocks install mjolnir.keycodes
luarocks install mjolnir.cmsj.appfinder
luarocks install mjolnir.cmsj.caffeinate
luarocks install mjolnir._asm.watcher.screen
luarocks install mjolnir._asm.notify
luarocks install mjolnir._asm.modal_hotkey
luarocks install mjolnir._asm.hydra
luarocks install mjolnir.alert

