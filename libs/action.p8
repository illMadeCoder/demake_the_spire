pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- 5. the action object
-- a list of actions who take the form
-- {
--   callback :: frame -> args -> bool,
--   frame :: integer,
--   args :: object
-- }

-- an action is this game_state's way of representing discrete behavior that
-- require x frames or some other condition to fully execute and occassionally
-- multiple ordered steps. The callback boolean's result of truth
-- indicate the end of an action's execution

-- action utility functions
function peek_pile(_card_pile)
   return _card_pile[#_card_pile]
end
      
function move_card_from_a_to_b(_card, _card_pile_a, _card_pile_b)
   assert(_card_pile_a) --debug
   assert(_card_pile_b) --debug
   del(_card_pile_a, _card)
   add(_card_pile_b, _card)
end

function pop_card_from_a_to_b(_card_pile_a, _card_pile_b)
   local card = peek_pile(_card_pile_a)
   move_card_from_a_to_b(card, _card_pile_a, _card_pile_b)
   return card
end

-- returns a damage, block tuple
function damage_block_calc(_damage, _block)
   local damage_dealt = clamp(_damage - _block, 0, 999)   
   _block = clamp(_block - _damage, 0, 999)
   return damage_dealt, _block
end

-- 5.2
enum_actions = {
   combat_start = 1,
    player_turn_start = 2,
    player_turn_end = 3,
    full_hand_to_discard = 4,
    full_draw_to_hand = 5,
    single_draw_to_hand = 6,
    full_discard_to_draw = 7,
    randomize_draw = 8,
    single_discard_to_draw = 9,
    player_turn_main = 10,
    select_from_enemies = 11,
    invoke_card = 12,
    discard_card = 13,
    add_to_discard_pile = 14,
    attack_enemy = 15,
    kill_enemy = 16,
    apply_selected = 17,
    block = 18,
    enemies_turn_start = 19,
    enemies_actions = 20,
    enemy_action = 21,
    enemies_turn_end = 22,
    attack_player = 23,
    enemy_block = 24,
    enemy_apply = 25,
    delay = 26,
    toggle_speed_mode = 27,
    display_event = 28,
    spend_energy = 29,
    attack_all_enemies = 30,
    enemy_turn_start = 31
}

function_map_actions = {}

-- 5.2.1 combat action callback
function_map_actions[enum_actions.combat_start] = function (_frame, _args)
   -- initialize deck
   init_draw_pile()
   reset_enemies_cursor()

   add_to_action_queue(enum_actions.player_turn_start)
   -- delay draw sequence
   add_to_action_queue(enum_actions.delay, 18)
   
   add_to_graphic_buffer(enum_graphics.background)
   add_to_graphic_buffer(enum_graphics.combat_player_panel)
   add_to_graphic_buffer(enum_graphics.pile,
			 {
			    x = 63,
			    y = 99,
			    get_pile = get_draw,
			    text = "draw",
			    is_selected = function ()
			       return get_selected(combat_select) == draw
			    end,
			    c = enum_colors.orange
			 }
   )
   add_to_graphic_buffer(enum_graphics.pile,
			 {
			    x = 82,
			    y = 99,
			    get_pile = get_discard,
			    text = "disc",
			    is_selected = function ()
			       return get_selected(combat_select) == discard
			    end,
			    c = enum_colors.dark_orange
			 }
   )
   add_to_graphic_buffer(enum_graphics.pile,
			 {
			    x = 101,
			    y = 99,
			    get_pile = get_exhaust,
			    text = "exha",
			    is_selected = function ()
			       return get_selected(combat_select) == exhaust
			    end,
			    c = enum_colors.dark_purple
			 }
   )

   add_to_graphic_buffer(enum_graphics.pile,
			 {
			    x = 70,
			    y = 113,
			    get_pile = get_potions,
			    text = "pots",
			    is_selected = function ()
			       return get_selected(combat_select) == potions
			    end,
			    c = enum_colors.purple
			 }
   )   

   add_to_graphic_buffer(enum_graphics.pile,
			 {
			    x = 90,
			    y = 113,
			    get_pile = get_relics,
			    text = "reli",
			    is_selected = function ()
			       return get_selected(combat_select) == relics
			    end,
			    c = enum_colors.dark_green
			 }
   )      
   
   add_to_graphic_buffer(enum_graphics.field)
   
   add_to_graphic_buffer(enum_graphics.focus_sides,
			 {
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
			 }
   )
  
   return true
end

-- 5.2.1.1 player actions
function_map_actions[enum_actions.player_turn_start] = function (_frame, _args)
   set_cursor_to_element(field_view, hand)
   turn = enum_turns.player
   player.energy = player.energy_init   
   add_to_action_queue(enum_actions.full_draw_to_hand)
   return true
end

function_map_actions[enum_actions.player_turn_end] = function (_frame, _args)
   if _frame == 10 then
      add_to_action_queue(enum_actions.full_hand_to_discard)
      add_to_action_queue(enum_actions.enemies_turn_start)
      return true
   end
end

-- 5.2.1.2 card control

-- hand to discard
function_map_actions[enum_actions.full_hand_to_discard] = function (_frame, _args)
   for i=1, #get_hand() do
      immediate_add_action_queue(enum_actions.discard_card, get_hand()[i])
   end
   return true
end
-- draw to hand
function_map_actions[enum_actions.full_draw_to_hand] = function (_frame, _args)
   for i=1, player.draw_power do
      add_to_action_queue(enum_actions.single_draw_to_hand)
   end   
   add_to_action_queue(enum_actions.player_turn_main)
   return true
end

function_map_actions[enum_actions.single_draw_to_hand] = function (_frame, _args)   
   if _frame == 1 and is_draw_empty() and not is_discard_empty() then
      interrupt_action_queue(enum_actions.full_discard_to_draw)   
   end

   if _frame == 2 and not is_draw_empty() then
      pop_draw_to_hand()
      set_hand_cursor_to_end()
   end

   if _frame == 10 then
      return true
   end
end

-- discard to draw
function_map_actions[enum_actions.full_discard_to_draw] = function ()
   immediate_add_action_queue(enum_actions.randomize_draw)
   for i=1, #get_discard() do
      immediate_add_action_queue(enum_actions.single_discard_to_draw)
   end
   return true
end

function_map_actions[enum_actions.randomize_draw] = function ()
   randomize_draw_pile()
   return true
end

function_map_actions[enum_actions.single_discard_to_draw] = function (_frame)
   if _frame == (speed_mode and 1 or 3) then
      pop_discard_to_draw()
      return true
   end
end

-- field control   
function_map_actions[enum_actions.player_turn_main] = function (_frame, _args)
   if _frame == 0  then
      if not _args then      
         reset_all_cursors()
      else
         set_cursor_to_element(combat_select, hand)
         set_cursor_to_element(field_view, hand)    
      end
   end
   
   if get_selected(combat_select) == hand then
      selected_card = get_selected_card_from_hand()
      if selected_card
	      and can_play_card(selected_card)
	      and btnp(enum_buttons.z)
      then -- setup card         
         if get_card_select_enemy(selected_card) then
            add_to_action_queue(enum_actions.select_from_enemies, selected_card)
         else 
            add_to_action_queue(enum_actions.invoke_card, selected_card)
         end         
	      return true
      else
         selected_card = nil
      end
   end
   
   if btnp(enum_buttons.left) then
      dec_cursor(get_selected(combat_select))
   elseif btnp(enum_buttons.right) then
      inc_cursor(get_selected(combat_select))
   end

   if btnp(enum_buttons.up) then
      inc_cursor(combat_select)
   elseif btnp(enum_buttons.down) then
      dec_cursor(combat_select)
   end

   set_cursor_to_element(field_view, get_selected(combat_select))
   
   if btnp(enum_buttons.x) then
      set_cursor_to_element(field_view, hand)
      add_to_action_queue(enum_actions.player_turn_end)
      set_cursor_none(combat_select)
      return true
   end
end   

function_map_actions[enum_actions.select_from_enemies] = function (_frame, _args)
   set_cursor_to_element(combat_select, enemies)
   
   if btnp(enum_buttons.left) then
      dec_cursor(enemies)
   elseif btnp(enum_buttons.right) then
      inc_cursor(enemies)
   end

   if btnp(enum_buttons.z) then
      add_to_action_queue(enum_actions.invoke_card, _args)
      return true
   end

   if btnp(enum_buttons.x) then  
      set_cursor_none(combat_select)      
      add_to_action_queue(enum_actions.player_turn_main, true)
      return true
   end
end

function_map_actions[enum_actions.spend_energy] = function (_frame, _args) 
   player.energy -= _args
   return true
end 

-- 5.2.1.3 use card
function_map_actions[enum_actions.invoke_card] = function (_frame, _args)
   invoke_card(_args)
   add_to_action_queue(enum_actions.spend_energy, get_card_cost(_args))
   add_to_action_queue(enum_actions.discard_card, _args)
   add_to_action_queue(enum_actions.player_turn_main)
   return true
end

function_map_actions[enum_actions.discard_card] = function (_frame, _args)      
   if _frame == 8 then
      del(get_hand(), _args)
      add(get_discard(), _args)
      reset_hand_cursor()
      return true
   end
end

function_map_actions[enum_actions.add_to_discard_pile] = function (_frame, _args)
   add(get_discard(), _args)
   return true
end

-- 5.2.1.4 player combat
-- args 
-- damage
-- enemy
function_map_actions[enum_actions.attack_enemy] = function (_frame, _args)
   local enemy = _args.enemy or get_selected(enemies)
   set_cursor_to_element(combat_select, enemies)
   set_cursor_to_element(enemies, enemy)
   if _frame == 10 then
      -- _args is damage :: int       
      local base_damage = _args.damage
      local mod_damage = base_damage
      if enemy then
         --interrupt_action_queue(enum_actions.display_event)
         if enemy.mods.v > 0 then
            mod_damage = base_damage + flr(base_damage*.5)
         end
         local damage, block = damage_block_calc(mod_damage, enemy.block)
         
         enemy.health -= damage
         enemy.health = clamp(enemy.health, 0, 999)
         enemy.block = block
         
         if enemy.health == 0 then
            immediate_add_action_queue(enum_actions.kill_enemy, enemy)
         end
      end         
   end
   if _frame == 20 then
      return true
   end
end

function_map_actions[enum_actions.kill_enemy] = function (_frame, _args)
   if _frame == 35 then
      del(enemies.list, _args)
      reset_enemies_cursor()
      return true
   end
end

function_map_actions[enum_actions.apply_selected] = function (_frame, _args)
   -- _args is damage :: int 
   if _frame == 5 then
      local enemy = get_selected(enemies)
      assert(enemy) --debug
      for k,v in pairs(_args) do
      if not enemy.mods[k] then
         enemy.mods[k] = 0
      end
	   enemy.mods[k] += v
      end
      return true
   else
      return false
   end      
end

function_map_actions[enum_actions.block] = function (_frame, _args)
   player.block += 5
   return true
end

-- 5.2.1.5 enemies actions
function_map_actions[enum_actions.enemy_turn_start] = function (_frame, _args)
   _args.block = 0
   return true
end

function_map_actions[enum_actions.enemies_turn_start] = function (_frame, _args)
   turn = enum_turns.enemies   
   if _frame == 45 then
      set_cursor_to_element(combat_select, enemies)
      for enemy in all(enemies.list) do
         --add_to_action_queue(enum_actions.enemy_turn_start, enemy)
      end      
      for enemy in all(enemies.list) do
         add_to_action_queue(enum_actions.enemy_action, enemy)
      end
      add_to_action_queue(enum_actions.enemies_turn_end)
      return true
   end
end


-- expects 
function_map_actions[enum_actions.enemy_action] = function (_frame, _args)
   if _frame == 15 then
      local enemy = _args
      local intent = enemy.get_intent(enemy)
      enemy.block += intent.block or 0
      enemy.mods.strength += intent.strength or 0
      player.health.cur -= intent.damage and (intent.damage + enemy.mods.strength) or 0            
   end
   if _frame == 30 then
      return true
   end
end

function_map_actions[enum_actions.enemies_turn_end] = function (_frame, _args)
   set_cursor_none(combat_select)
   reset_enemies_cursor()  
   for enemy in all(enemies.list) do      
      enemy.turn += 1     
      enemy.intent = nil
      enemy.get_intent(enemy)
      if enemy.mods.v then
         enemy.mods.v = clamp(enemy.mods.v-1, 0, 100)
      end
   end
   add_to_action_queue(enum_actions.player_turn_start)
   return true
end

-- general
function_map_actions[enum_actions.delay] = function (_frame, _args)
   if _frame == _args then
      return true
   end
end

-- 5.3 action constructor
function new_action(_action_id, _args)
   assert(is_num(_action_id)) --debug
   assert(function_map_actions[_action_id] != nil) --debug

   return {
      action_id = _action_id,
      args = _args,
      frame = 0
   }
end

function_map_actions[enum_actions.display_event] = function (_frame, _args)
   --display_event_text
   if _frame == 60 then
      return true
   end
end
