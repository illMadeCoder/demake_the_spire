pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- display helpers
function enemy_panel(_enemy, _x, _y, _i)
   local c = is_action_queue_currently(16) and is_selected(enemies, _enemy) and 1 or nil

   panel(_x-2, _y-2, 42, 25, is_selected(combat_select, enemies) and is_selected(enemies, _enemy) and 14)
   _print(_enemy.name, _x, _y+6, c or 2)
   _print(_enemy.index, _x+36, _y, c or 5)
   print_health_block(_enemy.health, _enemy.max_health, _enemy.block, _x, _y+12, c)
   _print(get_enemy_intent_str(_enemy), _x, _y, c or 9)
   _print(mods_str(_enemy.mods), _x, _y+18, c or 13)
end

function panel(_x, _y, _width, _height, _c)
   rectfill(_x-1, _y-1, _x+_width+1, _y+_height+1, _c or 1)
   rectfill(_x, _y, _x+_width, _y+_height, 0)
end

function get_card_color(_card)
   local is_selected_card_from_hand = is_selected(hand, _card)
   return (is_selected_card_from_hand and is_action_queue_currently(13)) and 4 or
      (is_selected_card_from_hand and is_action_queue_currently(6)) and 9 or
      (not can_play_card(_card) and 5) or 
      (is_selected_card_from_hand and 14) or
      7
end

function get_field_text_and_c()
   local selected_field_view = get_selected(field_view)
   return selected_field_view == hand and {"hand", 14}
      or selected_field_view == enemies and {"enemies", 2}
      or selected_field_view == player and {"player", 14}
      or selected_field_view == draw and {"draw", 9}
      or selected_field_view == discard and {"discard", 4}
      or selected_field_view == relics and {"relics", 3}
      or selected_field_view == potions and {"potions", 13}
      or selected_field_view == exhaust and {"exhaust", 2}
      or {"", 0}
end

 function get_field_c() -- remove
   local selected_field_view = get_selected(field_view)
   return selected_field_view == hand and
      (get_selected(combat_select) == enemies
	  and 2
	  or 14)
      or selected_field_view == draw and 9
      or selected_field_view == discard and 4
      or selected_field_view == relics and 3
      or selected_field_view == potions and 13
      or selected_field_view == exhaust and 2
      or 0
end

function get_field_btnl()
   return icons_map.z_button .. (get_selected(combat_select) == hand
				    and "play card"
				    or is_action_queue_currently(11)
				    and "select enemy"
				    or "~~~~~")
end

function get_field_btnr()
   return icons_map.x_button .. (get_selected(combat_select) == hand
				 and "end turn"
             or is_action_queue_currently(11)
             and "cancel" 
				 or "~~~~~")
end

function field(_state)
   local o = get_field_text_and_c()
   local _str, c = o[1], o[2]
   local _y = 31
   local _x = 63 - #_str*2
   local open_anim_offset_width = 63
   
   if _state.field_text != _str then
      _state.field_text = _str
      _state.frame = 0
   end

   -- background
   rectfill(0, _y-2, 127, _y+63, 0)
   -- left
   rectfill(61 - open_anim_offset_width - #_str*2, _y -2, _x-2, _y+6, c)
   -- right
   rectfill(_x+#_str*4, _y -2, 63 + open_anim_offset_width + #_str*2, _y+6, c)
   -- bot
   rectfill(63 - open_anim_offset_width - #_str*2,
         _y+63,
         63 + open_anim_offset_width + #_str*2 - 2,
         _y+63, c)
   
   for i = 0, 4 do
      rectfill(0,
         _y-2+i*2,
         127,
         _y-2+i*2, 0)
   end

   for i = 0, 63 do
         for j = 0, 13 do
            pset(i*4+1, _y+8+j*4,
            _state.frame <= 10 and
               12 or
               1)
         end
   end

   _print(_str, _x, _y, c)
   
   if _state.frame >= 10 then
      _print(get_field_btnl(), 0, 88, 12)
      print_right_just(get_field_btnr(), 125, 88, 12)	 
   end
   
   if _state.frame >= 18 then
      if _str == "enemies" then
         focus_sides(_state.focus_sides_enemies)
      else
         focus_sides(_state.focus_sides_cards)
      end   
   end
end

function focus_sides(_focus_sides)
   local list_cursor,            
         _y,
         _display_focus, 
         _display_side_left, 
         _display_side_right =
      _focus_sides.get_list_cursor(), 
      _focus_sides.y,
      _focus_sides.display_focus, 
      _focus_sides.display_side_left, 
      _focus_sides.display_side_right

   if not is_object(list_cursor) or not _display_side_right then
      return
   end

   -- left side
   for i=1, list_cursor.cursor-1 do
      _display_side_left(list_cursor.list[list_cursor.cursor-i], _y, i)
   end
   
   -- right side
   for i=list_cursor.cursor+1, #list_cursor.list do
      _display_side_right(list_cursor.list[i], _y, i-list_cursor.cursor)
   end  

   if get_selected(list_cursor) then
      _display_focus(get_selected(list_cursor), 63, _y)
   end

end

function background()
   for i = 0, 15 do
      for j = 0, 15 do	    
         backgrounds[2](i,j)
      end
   end
end

function combat_player_panel()
   local x, y = 8, 102
   local c = (is_selected(combat_select, draw) or
               is_selected(combat_select, discard) or
               is_selected(combat_select, exhaust) or
               is_selected(combat_select, potions) or
               is_selected(combat_select, relics)) and 14

   panel(x-2, y-2, 42, 25, c)
   print_energy(x, y, player.energy)
   _print("ironclad", x, y+6, 14)
   print_health_block(player.health.cur, player.health.max, player.block, x, y+12)
   _print(mods_str({}), x, y+18, 13)

   panel(53, 97, 72, 29,c)
   pile(63, 99, "draw", 9, draw)
   pile(82, 99, "disc", 4, discard)
   pile(101, 99, "exha", 2, exhaust)
   pile(70, 113, "pots", 13, potions)
   pile(90, 113, "reli", 3, relics)
end

function pile(_x, _y, _text, _c, _list_cursor)
   local c = get_selected(combat_select) == _list_cursor and 14 or _c
   rectfill(_x, _y+6, _x+14, _y+12, c)
   _print(_text, _x, _y, c)
   _print(#_list_cursor.list, _x+6, _y+7, 0)
end

graphic_type_objects = {
   -- 1 background
   { 
      background
   },
   -- 2 combat player panel
   {
      combat_player_panel
   },
   -- 3 field
   {
      function (_state)   
         field(_state)
      end,
      function (_args)
         return {
         focus_sides_cards = 
                  {
                  get_list_cursor = function ()
                  return get_selected(field_view)
                  end,
                  y = 41,
                  display_focus = function (_card,_x,_y)
                  local c = get_card_color(_card)
                  -- border
                  rectfill(_x-35, _y-2, _x+35, _y+45, 0)
                  rect(_x-30, _y-2, _x+30, _y+40, c)

                  -- energy
                  print_energy(_x-28, 
                                 _y, 
                                 get_card_cost(_card))

                  -- name
                  print_centered(get_card_name(_card),
                                 _x,
                                 _y,
                                 c)

                  -- description
                  print_card_description(_card,
                                    _x,
                                    _y+8,
                                    c)
                  
                     end,
                     display_side_left = function (_card, _y, _i)
                        _print(get_card_name(_card),
                              0,
                              _y-3+(_i-1)*6,
                              get_card_color(_card))
                     end,
                     display_side_right = function (_card, _y, _i)
                        print_right_just(get_card_name(_card),
                              128,
                              _y-3+(_i-1)*6,
                              get_card_color(_card))
                     end
                  }
      ,
      focus_sides_enemies =
                  {
                  get_list_cursor = function ()
                  return get_selected(field_view)
                  end,
                  y = 41,
                  display_focus = function (_enemy,_x,_y)
                     -- border
                     rectfill(_x-35, _y-2, _x+35, _y+45, 0)
                     rect(_x-30, _y-2, _x+30, _y+40, c)
                     
                     print_centered(_enemy.name, _x, _y, 2)
                  end,
                  display_side_left = function (_enemy, _y, _i)
                  end,
                  display_side_right = function (_enemy, _y, _i)
                  end
                  }	   
         }
      end
   },
   -- 4  enemies
   {
      function (_state)
         focus_sides({
            get_list_cursor = function ()
               return enemies
            end,
            y = 3,
            display_focus = function (_enemy, _x, _y) 
               enemy_panel(_enemy, _x-19, _y, _i)
            end,
            display_side_left = function (_enemy, _y, _i)
               if (_i == 1) then
                  enemy_panel(_enemy, 0, _y, _i)
               end
            end,
            display_side_right = function (_enemy, _y, _i)
               if (_i == 1) then
                  enemy_panel(_enemy, 88, _y, _i)
               end
            end,
         })
      end
   } 
}

function new_graphic(_graphic_id, _args)   
   local type_object = graphic_type_objects[_graphic_id]   
   local ret = {
      callback = type_object[1],
      state = (type_object[2] and type_object[2](_args)) or _args or {},
      show = true
   }
   ret.state.frame = 0
   return ret
end
