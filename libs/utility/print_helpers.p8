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
   damage = "\133",
   strength = "s"
}

function_map_just = {}
function_map_just[enum_just.left] = _print
function_map_just[enum_just.center] = print_centered
function_map_just[enum_just.right] = print_right_just

function _print(_str, _x, _y, _c, _is_selected, _underline)
   local c =_is_selected == true and 14 or _c
   print(_str, _x, _y, c)
end

function print_centered(_str, _x, _y, _c, _is_selected, _underline)
   _print(_str, _x - #_str*2, _y, _c, _is_selected, _underline)
end

function split(_str, _split) 
   local ret = {}
   local cur = ""
   for i = 1, #_str do
      local char = sub(_str, i, i)
      if char == _split then
         add(ret, cur)
         cur = ""
      else
         cur = cur .. char 
      end
   end
   if cur != "" then
      add(ret, cur)
   end
   return ret
end

function str_wrapped(_str, _w) 
   local words = split(_str, " ")
   local lines = {}
   local line = ""

   for word in all(words) do
      -- if word length + line length + pre-space(1) > width then it can not fit the line
      if #word + #line + 1 > _w then
         add(lines, line)         
         line = word         
      elseif #word + #line + 1 == _w then
         add(lines, line .. " " .. word)
         line = ""
      else
         line = line == "" 
            and word 
            or (line .. " " .. word)
      end
   end

   if #line > 0 then
      add(lines, line)
   end

   return lines
end

function print_card_description(_card, _x, _y, _c)
   local description = get_card_description(_card)
   local print_strs = {}
   if type(description) == "string" then
      print_strs = str_wrapped(description, 14)      
   else
      for i,desc in ipairs(description) do
         local strs = str_wrapped(desc, 14)
         for str in all(strs) do 
            add(print_strs, str)
         end
      end
   end
   for i,str in ipairs(print_strs) do
      print_centered(str, _x, _y+(i-1)*6, _c)
   end
end

function print_right_just(_str, _x, _y, _c, _is_selected, _underline)
   _print(_str, _x - #_str*4, _y, _c, _is_selected, _underline)
end

function print_left_just(_str, _x, _y, _c, _is_selected, _underline)
   _print(_str, _x, _y, _c, _is_selected, _underline)
end

function print_energy(_x, _y, _energy)
   _print(_energy, _x, _y, 10)
   _print(icons_map.energy, _x+#(_energy .. "")*4-1, _y, 10)
end

function mods_str(_mods) 
   local s = ''
   for k,v in pairs(_mods) do 
      if v > 0 then
         local display_str_k = icons_map[k] or k
         s = s .. v .. display_str_k
      end
   end
   return fill_rest_str(s,"~",10)
end

function repeat_char(_char, _c)
   local r = ''
   for i = 1, _c do
      r = r .. _char
   end
   return r
end

function fill_rest_str(_str, _char, _count, _fill_left)
   local repeated_chars = repeat_char(_char, _count-#_str)
   return _fill_left and repeated_chars .. _str or _str .. repeated_chars 
end

function print_health(_x, _y, _health_cur, _health_max)
   local str = _health_cur .. "/" .. _health_max
   _print(str, _x, _y, 8)
   _print(icons_map.health, _x+#str*4-1, _y, 8)
end

function print_block(_x, _y, _block)
   _block = fill_rest_str(tostr(_block), '0', 2, true)
   _print(_block, _x, _y, 6)
   _print(icons_map.block, _x+#(_block .. "")*4-1, _y, 6)
end

function print_health_block(_health_cur, _health_max, _block, _x, _y, _c)
   print_health(_x, _y, _health_cur, _health_max, _c or 8)
   print_block(_x+27, _y, _block, _c or 6)   
end

function get_enemy_intent_str(_enemy)
   assert(_enemy.get_intent(_enemy)) --debug
   local r = ""
   local intent = _enemy.get_intent(_enemy)
   for k,v in pairs(intent) do      
      local k_display_str = icons_map[k] or k 
      if k == "damage" then
         v += _enemy.mods.strength
      end
      r = r .. v .. k_display_str
   end
   return r
end