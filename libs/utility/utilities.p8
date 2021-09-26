pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- general utility functions
function is_function(_x)
   return type(_x) == "function"
end

function is_object(_x)
   return type(_x) == "table"
end

-- numeric
function rotate(_x, _min, _max)
   return _x < _min and _max or (_x > _max and _min or _x)
end

function clamp(_x, _min, _max)
   return _x <= _min and _min or (_x >= _max and _max or _x)
end

-- array
function randomize_array_indexes(_array)
   local size = #_array
   local randomized_array = {}

   for i = 1, size do
      add(randomized_array, nil)
   end
   for elem in all(_array) do
      -- choose random index
      local rnd_index = flr(rnd(size)+1)
      -- if random index has already been populated try again
      while randomized_array[rnd_index] != nil do
      	 rnd_index = flr(rnd(size)+1)
      end
      randomized_array[rnd_index] = elem
   end
   
   return randomized_array
end


function peek(_list)
   return _list[#_list]
end

function move_from_to(_from_list, _to_list, _element) 
   del(_from_list, _element)
   add(_to_list, _element)
end

function pop_from_to(_from, _to)
   local element = peek(_from)
   move_from_to(_from, _to, element)
   return element
end