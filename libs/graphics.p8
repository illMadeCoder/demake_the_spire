pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- 7 display
function enemy_panel(_enemy, _x, _y, _i)
   local c = display_colors.enemy_color

   local enemy_dead_col = is_action_queue_currently(enum_actions.kill_enemy) and enum_colors.dark_blue or nil

   panel(_x-2, _y-2, 42, 25, is_selected(combat_select, enemies) and is_selected(enemies, _enemy) and enum_colors.pink)
   _print(_enemy.name, _x, _y+6, enemy_dead_col or c)
   _print(_enemy.index, _x+36, _y, 5)
   print_health_block(_enemy.health, _enemy.max_health, _enemy.block, _x, _y+12)
   _print(get_enemy_intent_str(_enemy), _x, _y, enemy_dead_col or display_colors.intent_color)
   _print(mods_str(_enemy.mods), _x, _y+18, enemy_dead_col or display_colors.mods_color)
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

-- 7.1 display variables
display_colors = {
   player_color = enum_colors.pink,
   enemy_color = enum_colors.dark_purple,
   card_color = enum_colors.white,
   health_color = enum_colors.red,
   block_color = enum_colors.grey,
   intent_color = enum_colors.orange,
   energy_color = enum_colors.yellow,
   mods_color = enum_colors.purple,
   relics_color = enum_colors.dark_green,
   potions_color = enum_colors.purple,
   draw_color = enum_colors.orange,
   discard_color = enum_colors.dark_orange,
   exhaust_color = enum_colors.dark_purple
}

-- 7.2 display helpers
function panel(_x, _y, _width, _height, _c)
   rectfill(_x-1, _y-1, _x+_width+1, _y+_height+1, _c or enum_colors.dark_blue)
   rect_bevel(_x, _y, _x+_width, _y+_height, enum_colors.black)
end

function get_card_color(_card)
   return (is_selected_card_from_hand(_card) and is_action_queue_currently(enum_actions.discard_card)) and enum_colors.dark_orange or
      (is_selected_card_from_hand(_card) and is_action_queue_currently(enum_actions.single_draw_to_hand)) and enum_colors.orange or
      (not can_play_card(_card) and 5) or 
      (is_selected_card_from_hand(_card) and display_colors.player_color) or
      display_colors.card_color
end

function get_field_text()
   local selected_field_view = get_selected(field_view)
   return is_action_queue_currently(enum_actions.display_event) and "combat"
      or selected_field_view == hand and "hand"
      or selected_field_view == draw and "draw"
      or selected_field_view == discard and "discard"
      or selected_field_view == relics and "relics"
      or selected_field_view == potions and "potions"
      or selected_field_view == exhaust and "exhaust"
      or ""
end

function get_field_c()
   local selected_field_view = get_selected(field_view)
   return is_action_queue_currently(enum_actions.display_event) and enum_colors.blue
      or selected_field_view == hand and
      (get_selected(combat_select) == enemies
	  and enum_colors.dark_purple
	  or display_colors.player_color)
      or selected_field_view == draw and display_colors.draw_color
      or selected_field_view == discard and display_colors.discard_color
      or selected_field_view == relics and display_colors.relics_color
      or selected_field_view == potions and display_colors.potions_color
      or selected_field_view == exhaust and display_colors.exhaust_color
      or 0
end

function get_field_btnl()
   return icons_map.z_button .. (get_selected(combat_select) == hand
				    and "play card"
				    or is_action_queue_currently(enum_actions.select_from_enemies)
				    and "select enemy"
				    or "~~~~~")
end

function get_field_btnr()
   return icons_map.x_button .. (get_selected(combat_select) == hand
				 and "end turn"
             or is_action_queue_currently(enum_actions.select_from_enemies)
             and "cancel" 
				 or "~~~~~")
end

enum_graphics = {
   field = 1,
   enemies = 2,
   focus_sides = 3,
   background = 4,
   combat_player_panel = 5,
   pile = 6
}

graphic_typeobjects = {}

graphic_typeobjects[enum_graphics.background] = {
   callback = function (_state)
      for i = 0, 15 do
	 for j = 0, 15 do
	    local background = enum_backgrounds.weaving
	    if is_function(function_map_backgrounds[background]) then
	       function_map_backgrounds[background](i,j)
	    else
	       function_map_backgrounds[background].draw(i,
							 j,
							 function_map_backgrounds[background].args)
	    end
	 end
      end
   end,
   state = function (_args)
      return _args
   end
}

graphic_typeobjects[enum_graphics.field] = {
   callback = function (_state)      
      local c, str = get_field_c()
      local _str = get_field_text()
      local _y = 31
      local _x = 63 - #_str*2
      local open_anim_offset_width = 63
      
      if _state.field_text != _str then
      _state.field_text = _str
      _state.frame = 0
      end

      -- background
      rectfill(0,
	       _y-2,
	       127,
	       _y+63, enum_colors.black)
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
         _y-2+i*2, enum_colors.black)
      end

      for i = 0, 63 do
      	 for j = 0, 13 do
      	    pset(i*4+1, _y+8+j*4,
		 _state.frame <= 10 and
		    enum_colors.blue or
		    enum_colors.dark_blue)
      	 end
      end

      _print(_str, _x, _y, c)
      
      if _state.frame >= 10 then
	      _print(get_field_btnl(), 0, 88, enum_colors.blue)
	      print_right_just(get_field_btnr(), 125, 88, enum_colors.blue)	 
      end
      
      if _state.frame >= 18 then
	 if _str != "combat" then
	    draw_graphic(_state.focus_sides)
	 else
	    print_centered("place holder for combat text", 63, _y+28, c) -- remove
	 end   
      end
   end,
   state = function (_args)
      -- expects
      return {
	 anim_state = 1,
	 focus_sides = new_graphic(enum_graphics.focus_sides,
				   {
				   get_list_cursor = function ()
					 return get_selected(field_view)
				   end,
				   y = 41,
				   display_focus = function (_card,_x,_y)
               local c = get_card_color(_card)
                -- border
                rectfill(_x-35, _y-2, _x+35, _y+45, enum_colors.black)
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
	 )
      }
   end
}

graphic_typeobjects[enum_graphics.combat_player_panel] = {
   callback = function (_combat_player_panel)
      local x, y = 8, 102
            local c = (is_selected(combat_select, draw) or
	       is_selected(combat_select, discard) or
	       is_selected(combat_select, exhaust) or
          is_selected(combat_select, potions) or
          is_selected(combat_select, relics)) and enum_colors.pink
      panel(x-2, y-2, 42, 25, c)
      print_energy(x, y, player.energy)
      _print("ironclad", x, y+6, enum_colors.pink)
      _print("\137", 41, y, enum_colors.pink)
      print_health_block(player.health.cur, player.health.max, player.block, x, y+12)
      _print(filler_str(), x, y+18, enum_colors.purple)

      panel(53, 97, 72, 29,c)

   end,
   state = function (_args)
      return _args
   end
}

graphic_typeobjects[enum_graphics.pile] = {
   callback = function (_pile)
      local c = _pile.is_selected() and enum_colors.pink or _pile.c
      rectfill(_pile.x, _pile.y+6, _pile.x+14, _pile.y+12, c)
      _print(get(_pile.text), _pile.x, _pile.y, c)
      _print(#_pile.get_pile(), _pile.x+6, _pile.y+7, 0)
   end,
   state = function(_args)
   --    display_type = enum_display_types.display_pile,
   --    text = _str,
   --    get_pile = _get_pile,
   --    x = _x,
   --    y = _y,
   --    c = _c,
   --    c2 = _c2,
      --    is_selected = _is_selected
      
       return _args
   end
}

graphic_typeobjects[enum_graphics.focus_sides] = {
   callback = function (_focus_sides)
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
         _display_side_left(list_cursor.list[i], _y, i)
      end
      
      -- right side
      for i=list_cursor.cursor+1, #list_cursor.list do
         _display_side_right(list_cursor.list[i], _y, i-list_cursor.cursor)
      end  

      if get_selected(list_cursor) then
	      _display_focus(get_selected(list_cursor), 63, _y)
      end

   end,
   state = function(_args)
      return _args
   end
}

function new_graphic(_graphic_id, _args)
   assert(graphic_typeobjects[_graphic_id], _graphic_id)
   local typeobject = graphic_typeobjects[_graphic_id]
   local ret = {
      callback = typeobject.callback,
      state = typeobject.state(_args) or {},
      show = true
   }
   ret.state.frame = 0
   return ret
end
