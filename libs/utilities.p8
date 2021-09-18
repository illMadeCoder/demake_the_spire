pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- 1. general utility functions
function noop()
end

function get(_get)
   local v = _get
   while is_function(v) do
      v = v()
   end
   return v
end

-- function eval_binded_function(_binded_function)
--    _binded_function.callback(_binded_function.args)
-- end

-- 1.0 types
--debug_start
function is_num(_x)
   return type(_x) == "number"
end

function is_str(_x)
   return type(_x) == "string"
end

function is_bool(_x)
   return type(_x) == "boolean"
end
--debug_end
function is_function(_x)
   return type(_x) == "function"
end

function is_object(_x)
   return type(_x) == "table"
end

--debug_start
function enum_key(_x, _enum)
   for k,v in pairs(_enum) do
      if _x == v then
	 return k
      end
   end
end
function is_in_enum(_x, _enum)
   return enum_key(_x, _enum) and true or false
end
--debug_end

-- 1.1 object
function shallow_clone(_object)
   assert(_object) --debug
   local ret = {}
   for k,v in pairs(_object) do
      ret[k] = v
   end
   return ret
end


-- string
function shorten_str(_str, _shorten)
   return sub(_str,0,_shorten)
end

-- 1.3 numeric
function lerp(_percent, _min, _max)
   return clamp(_percent*(_max-_min)+_min, _min, _max)
end

function lerp_rotate(_percent, _min, _max)
   return clamp((_percent%1)*(_max-_min)+_min, _min, _max)
end

-- function lerp_both_ways(_percent, _min, _max)
-- end

function rotate(_x, _min, _max)
   return _x < _min and _max or (_x > _max and _min or _x)
end

function clamp(_x, _min, _max)
   return _x <= _min and _min or (_x >= _max and _max or _x)
end

-- 1.4 array
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

-- 1.5 special rects
function rect_bevel(_x, _y, _x1, _y1, _c)
   for y = _y, _y1 do
      for x = _x, _x1 do	 
	 pset(x, y, _c)
      end
   end
end