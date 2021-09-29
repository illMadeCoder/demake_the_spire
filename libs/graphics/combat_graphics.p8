pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- display helpers
function enemy_panel(_enemy, _x, _y, _i)
   local c = is_action_queue_currently(16) and is_selected(enemies, _enemy) and 1 or nil

   panel(_x-1, _y-1, 40, 24, 
      is_selected(combat_select, enemies) and is_selected(enemies, _enemy) and 14 or 2)
   _print(_enemy.name, _x, _y+6, c or 2)
   _print(_enemy.index, _x+36, _y, c or 2)
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
   return selected_field_view == hand and {"hand", 12}
      or selected_field_view == enemy_mods_list_cursor and {get_selected(enemies).name .. " " .. get_selected(enemies).index, 2}
      or selected_field_view == enemies and {get_selected(enemies).name .. " " .. get_selected(enemies).index, 2}
      or selected_field_view == player_mods_list_cursor and {"ironclad", 14}
      or selected_field_view == draw and {"draw", 9}
      or selected_field_view == discard and {"discard", 4}
      or selected_field_view == relics and {"relics", 3}
      or selected_field_view == potions and {"potions", 13}
      or selected_field_view == exhaust and {"exhaust", 5}
      or {"", 0}
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

function focus_sides(_list_cursor, _y, _display_focus, _display_side_left, _display_side_right)
   if not is_object(_list_cursor) or not _display_side_right then
      assert(false)
   end

   -- left side
   for i=1, _list_cursor.cursor-1 do      
      _display_side_left(_list_cursor.list[_list_cursor.cursor-i], _y, i)
   end
   
   -- right side
   for i=_list_cursor.cursor+1, #_list_cursor.list do
      _display_side_right(_list_cursor.list[i], _y, i-_list_cursor.cursor)
   end  

   if get_selected(_list_cursor) then
      _display_focus(get_selected(_list_cursor), 63, _y)
   end   
end

function pile(_x, _y, _text, _c, _list_cursor)
   local c = get_selected(combat_select) == _list_cursor and 14 or _c
   rectfill(_x, _y+6, _x+14, _y+12, c)
   print_centered(_text, _x+8, _y, c)
   local count = #_list_cursor.list
   if count == 0 then
      _print("-", _x+6, _y+7, 0)
   else
      _print(fill_rest_str(tostr(count), "0", 2, true), _x+4, _y+7, 0)
   end
end

function draw_combat()
   -- background
   for i = 0, 15 do
      for j = 0, 15 do	    
         backgrounds[2](i,j)
      end
   end

   -- combat player panel
   local x, y = 8, 100
   local c = (is_selected(combat_select, draw) or
               is_selected(combat_select, discard) or
               is_selected(combat_select, exhaust) or
               is_selected(combat_select, potions) or
               is_selected(combat_select, relics)) and 14

   panel(x, y, 42, 25, get_selected(field_view) == player_mods_list_cursor and 14 or 1)
   print_energy(x+2, y+2, combat_player.energy)
   print_right_just(player.gold .. "\127", x+42, y+2, 9)
   _print("ironclad", x+2, y+8, 14)
   print_health_block(player.health.cur, player.health.max, combat_player.block, x+2, y+14)
   _print(mods_str(combat_player.mods), x+2, y+20, 13)

   local x1, y1 = x+52, y
   panel(x1, 97, 58, 29, c)
   pile(x1+2, 99, "draw", 9, draw)
   pile(x1+22, 99, "disc", 4, discard)
   pile(x1+42, 99, "exha", 5, exhaust)
   pile(x1+2, 113, "pots", 13, potions)
   pile(x1+22, 113, "reli", 3, relics)
   print("map", x1+44, 113, 15)
   rectfill(x1+42, 119, x1+42+14, 113+12, 15)
   print("-", x1+48, 120, 0)

   -- field
   local o = get_field_text_and_c()
   local _str, c = o[1], o[2]
   local _y = 31
   local _x = 63 - #_str*2
   local open_anim_offset_width = 63
   
   if field.field_text != _str then
      field.field_text = _str
      field.frame = 0
   end

   -- field background
   rectfill(0, _y-2, 127, _y+63, 0)
   -- field left
   rectfill(0, _y -2, _x-2, _y+6, c)
   -- -- right
   rectfill(_x+#_str*4, _y-2, 127, _y+6, c)
   -- -- bot
   rectfill(0,_y+63,127,_y+63, c)
   
   for i = 0, 4 do
      rectfill(0,_y-2+i*2,127,_y-2+i*2, 0)
   end

   --background
   for i = 0, 63 do
         for j = 0, 13 do
            pset(i*4+1, _y+8+j*4,
            field.frame <= 10 and
               12 or
               1)
         end
   end
   
   -- title
   _print(_str, _x, _y, c)

   -- z, x button graphics
   if field.frame >= 10 then
      _print(get_field_btnl(), 0, 88, c)
      print_right_just(get_field_btnr(), 125, 88, c)	 
   end
   
   if field.frame >= 18 then
      if get_selected(field_view) == player_mods_list_cursor 
      or get_selected(field_view) == enemy_mods_list_cursor
      or get_selected(field_view) == enemies then
         -- rectfill(63-35, 40-2+1, 63+35, 40+45+1, 0)
         -- rect(63-30, 40-2+1, 63+30, 40+40+1, 14)
         -- print_mods_detailed(player.mods, 63, 40+1, 14)   
         local lc = get_selected(field_view) == player_mods_list_cursor and player_mods_list_cursor or enemy_mods_list_cursor
         -- set the enemy mod list cursor state to show the currently selected enemy
         enemy_mods_list_cursor.list = get_selected(enemies).mods
         if #enemy_mods_list_cursor.list == 1 then
            enemy_mods_list_cursor.cursor = 1
         end
         focus_sides(lc,
                     41,
                     function (_mod, _x, _y)
                        local c = get_field_text_and_c()[2]
                        rectfill(63-35, 40-2+1, 63+35, 40+45+1, 0)
                        rect(63-30, 40-2+1, 63+30, 40+40+1,  (get_selected(field_view) == enemy_mods_list_cursor or get_selected(field_view) == player_mods_list_cursor) and 14 or 2)
                        print_mod_description(_mod, 63, 40+1, (get_selected(field_view) == enemy_mods_list_cursor or get_selected(field_view) == player_mods_list_cursor) and 14 or 2)
                     end,
                     function (_mod, _y, _i)
                        _print(_mod.degree .. "|" .. str_shorten(_mod.name, 6),
                                 0,
                                 _y-3+(_i-1)*6,
                                 13)
                     end,
                     function (_mod, _y, _i)
                        print_right_just(_mod.degree .. "|" .. str_shorten(_mod.name, 6),
                           130,
                           _y-3+(_i-1)*6,
                           13)                    
                     end)

      else
         focus_sides(
            get_selected(field_view),
            41,
            function (_card,_x,_y)
               local c = get_field_text_and_c(_card)[2]
               -- border
               rectfill(_x-35, _y-2, _x+35, _y+45, 0)
               rect(_x-30, _y-2, _x+30, _y+40, 14)

               -- energy
               print_energy(_x-28, 
                              _y, 
                              get_card_cost(_card))

               -- name
               print_centered(get_card_name(_card),
                              _x,
                              _y,
                              14)

               -- description
               print_card_description(_card,
                                 _x,
                                 _y+8,
                                 14)               
            end,
            function (_card, _y, _i)
               _print("{10 " .. get_card_cost(_card) .. "}|" .. get_card_name(_card),
                     0,
                     _y-3+(_i-1)*6,
                     get_card_color(_card))
            end,
            function (_card, _y, _i)
               print_right_just("{10 " .. get_card_cost(_card) .. "}|" .. get_card_name(_card),
                     130,
                     _y-3+(_i-1)*6,
                     get_card_color(_card))
            end
      )
      end   
   end
   -- enemies
   focus_sides(
      enemies,
      3,
      function (_enemy, _x, _y) 
         enemy_panel(_enemy, _x-19, _y, _i)
      end,
      function (_enemy, _y, _i)
         if (_i == 1) then
            enemy_panel(_enemy, 0, _y, _i)
         end
      end,
      function (_enemy, _y, _i)
         if (_i == 1) then
            enemy_panel(_enemy, 88, _y, _i)
         end
      end           
   )
end
