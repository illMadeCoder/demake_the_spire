pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
enum_just = {
   left = 1,
   center = 2,
   right = 3
}

icons_map = {
   energy = "\134",
   health = "\135",
   block = "\143",
   z_button = "\142",
   x_button = "\151",
   evil_eye = "\136",
   star = "\146",
   damage = "\133"
}

function_map_just = {}
function_map_just[enum_just.left] = _print
function_map_just[enum_just.center] = print_centered
function_map_just[enum_just.right] = print_right_just

function _print(_str, _x, _y, _c, _is_selected, _underline)
   local c =_is_selected == true and display_colors.player_color or _c
   print(_str, _x, _y, c)
end

function print_centered(_str, _x, _y, _c, _is_selected, _underline)
   _print(_str, _x - #_str*2, _y, _c, _is_selected, _underline)
end

function print_right_just(_str, _x, _y, _c, _is_selected, _underline)
   _print(_str, _x - #_str*4, _y, _c, _is_selected, _underline)
end

function print_health(_x, _y, _health_cur, _health_max)
   local str = _health_cur .. "/" .. _health_max
   _print(str, _x, _y, enum_colors.red)
   _print(icons_map.health, _x+#str*4-1, _y, enum_colors.red)
end

function print_block(_x, _y, _block)
   _print(_block, _x, _y, enum_colors.grey)
   _print(icons_map.block, _x+#(_block .. "")*4-1, _y, enum_colors.grey)
end

function print_energy(_x, _y, _energy)
   _print(_energy, _x, _y, enum_colors.yellow)
   _print(icons_map.energy, _x+#(_energy .. "")*4-1, _y, enum_colors.yellow)
end

function mods_str(_mods) 
   local s = ''
   for k,v in pairs(_mods) do 
      if v > 0 then
         s = s .. k .. v
      end
   end
   return fill_rest_str(s,"~",9)
end

function repeat_char(_char, _c)
   local r = ''
   for i = 1, _c do
      r = r .. _char
   end
   return r
end

function fill_rest_str(_str, _char, _c)
   return _str .. repeat_char(_char, 9-#_str)   
end

function filler_str()
   return repeat_char("~", 9)
end

function print_health_block(_health_cur, _health_max, _block, _x, _y)
   print_health(_x, _y, _health_cur, _health_max, enum_colors.red)
   print_block(_x+27, _y, _block, enum_colors.grey)   
end