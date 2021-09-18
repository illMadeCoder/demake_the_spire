pico-8 cartridge // http://www.pico-8.com
version 18
__lua__


function new_list_cursor(_list)
   return {
      list = _list or {},
      cursor = 0
   }
end

function set_cursor_none(_list_cursor)   
   _list_cursor.cursor = 0
end

function set_cursor_mid(_list_cursor)
   _list_cursor.cursor = flr(#_list_cursor.list/2)+1
end

function set_cursor_end(_list_cursor)
   _list_cursor.cursor = #_list_cursor.list
end

function set_cursor_to_element(_list_cursor, _element)
   for k,element in pairs(_list_cursor.list) do
      if element == _element then
	 _list_cursor.cursor = k
	 return
      end
   end
end

function rotate_cursor(_list_cursor)
   _list_cursor.cursor = rotate(_list_cursor.cursor, 1, #_list_cursor.list)
end

function inc_cursor(_list_cursor)
   _list_cursor.cursor += 1
   rotate_cursor(_list_cursor)
end

function dec_cursor(_list_cursor)
   _list_cursor.cursor -= 1
   rotate_cursor(_list_cursor)
end

function get_selected(_list_cursor)
   return _list_cursor.cursor == 0 and nil or _list_cursor.list[_list_cursor.cursor]
end

function is_selected(_list_cursor, _item)
   return get_selected(_list_cursor) == _item
end

function is_empty(_list_cursor)
   return #_list_cursor.list == 0
end