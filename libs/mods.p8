pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
enum_mods = {
   weakness = 1
}

function_map_mods = {}
function_map_mods[enum_mods.weakness] = function (_damage)
   return _flr(_damage/2)
end