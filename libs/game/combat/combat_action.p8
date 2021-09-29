pico-8 cartridge // http://www.pico-8.com
version 18
__lua__


-- returns a damage, block tuple
function damage_block_calc(_damage, _block)
   local damage_dealt = clamp(_damage - _block, 0, 999)   
   _block = clamp(_block - _damage, 0, 999)
   return damage_dealt, _block
end

-- 5.2
-- enum_actions = {
--    combat_start = 1,
--     player_turn_start = 2,
--     player_turn_end = 3,
--     full_hand_to_discard = 4,
--     full_draw_to_hand = 5,
--     single_draw_to_hand = 6,
--     full_discard_to_draw = 7,
--     randomize_draw = 8,
--     single_discard_to_draw = 9,
--     player_turn_main = 10,
--     select_from_enemies = 11,
--     invoke_card = 12,
--     discard_card = 13,
--     add_to_discard_pile = 14,
--     attack_enemy = 15,
--     kill_enemy = 16,
--     apply_selected = 17,
--     block = 18,
--     enemies_turn_start = 19,
--     enemy_action = 20,
--     enemies_turn_end = 21,
--     delay = 22,   
--     spend_energy = 23,
--     enemy_turn_start = 24
-- }

combat_action_callbacks = {
   -- 1 combat start
   function (_frame, _args)
      -- initialize deck
      draw.list = randomize_array_indexes(deck.list)
      reset_enemies_cursor()
   
      add_to_action_queue(2)
      -- delay draw sequence
      add_to_action_queue(22, 18)   
     
      return true
   end,
   -- 2 player turn start
   function (_frame, _args)
      set_cursor_to_element(field_view, hand)
      turn = "player"
      combat_player.energy = 3  
      add_to_action_queue(5)
      return true
   end,
   -- 3 player turn end
   function (_frame, _args)
      if _frame == 0 then         
         set_cursor_none(combat_select)
         set_cursor_to_element(field_view, hand)
      end

      if _frame == 10 then
         add_to_action_queue(4)
         add_to_action_queue(19)
         return true
      end
   end,
   -- 4 full hand to discard
   function (_frame, _args)
      for i=1, #hand.list do
         immediate_add_action_queue(13, hand.list[i])
      end
      return true
   end,
   -- 5 full draw to hand
   function (_frame, _args)
      for i=1, 5 do
         add_to_action_queue(6)
      end   
      add_to_action_queue(22, 10)
      add_to_action_queue(10)   
      return true
   end,
   -- 6 single draw to hand
   function (_frame, _args)   
      if _frame == 1 and is_empty(draw) and not is_empty(discard) then
         interrupt_action_queue(7)   
      end
   
      if _frame == 2 and not is_empty(draw) then
         pop_from_to(draw.list, hand.list)
         set_cursor_end(hand)
      end
   
      if _frame == 3 then -- change draw speed
         return true
      end
   end,
   -- 7 full discard to draw
   function ()
      immediate_add_action_queue(8)
      for i=1, #discard.list do
         immediate_add_action_queue(9)
      end
      return true
   end,
   -- 8 randomize draw
   function ()
      draw.list = randomize_array_indexes(draw.list)
      return true
   end,
   -- 9 single discard to draw
   function (_frame)
      if _frame == (speed_mode and 1 or 3) then
         pop_from_to(discard.list, draw.list)
         return true
      end
   end,
   -- 10 player turn main
   function (_frame, _args)
      if _frame == 0  then
         if not _args then      
            reset_all_cursors()
         else
            set_cursor_to_element(combat_select, hand)
            set_cursor_to_element(field_view, hand)    
         end
      end
      
      if get_selected(combat_select) == hand then
         selected_card = get_selected(hand)
         if selected_card
            and can_play_card(selected_card)
            and btnp(4)
         then -- setup card         
            if get_card_select_enemy(selected_card) then
               add_to_action_queue(11, selected_card)
            else 
               add_to_action_queue(12, selected_card)
            end         
            return true
         else
            selected_card = nil
         end
      end
      
      if get_selected(combat_select) != player then
         if btnp(0) then
            dec_cursor(get_selected(combat_select))
         elseif btnp(1) then
            inc_cursor(get_selected(combat_select))         
         end
      end
   
      if btnp(2) then
         inc_cursor(combat_select)
         enemy_mods_list_cursor.list = get_selected(enemies).mods
         set_cursor_mid(enemy_mods_list_cursor)
         set_cursor_mid(player_mods_list_cursor)
         
         if get_selected(combat_select) == enemy_mods_list_cursor and #enemy_mods_list_cursor.list <= 1 then
            inc_cursor(combat_select)
         end
         mod_display_frame = 0
      elseif btnp(3) then
         dec_cursor(combat_select)
         set_cursor_mid(enemy_mods_list_cursor)
         set_cursor_mid(player_mods_list_cursor)
         if get_selected(combat_select) == enemy_mods_list_cursor and #enemy_mods_list_cursor.list <= 1 then
            dec_cursor(combat_select)
         end
         mod_display_frame = 0
      end


         
      set_cursor_to_element(field_view, get_selected(combat_select))
      
      if btnp(5) then
         add_to_action_queue(3)
         return true
      end
   end,
   -- 11 select_from_enemies
   function (_frame, _args)
      set_cursor_to_element(combat_select, enemies)
      
      if btnp(0) then
         dec_cursor(enemies)
      elseif btnp(1) then
         inc_cursor(enemies)
      end
   
      if btnp(4) then
         add_to_action_queue(12, _args)
         return true
      end
   
      if btnp(5) then  
         set_cursor_none(combat_select)      
         add_to_action_queue(10, true)
         return true
      end
   end,
   -- 12 invoke card
   function (_frame, _args)
      invoke_card(_args)
      add_to_action_queue(23, get_card_cost(_args))
      add_to_action_queue(13, _args)
      add_to_action_queue(10)
      return true
   end,
   -- 13 discard card
   function (_frame, _args)      
      if _frame == 8 then
         del(hand.list, _args)
         add(discard.list, _args)
         set_cursor_mid(hand)
         return true
      end
   end,
   -- 14 add to discard pile
   function (_frame, _args)
      add(discard.list, _args)
      return true
   end,
   -- 15 attack enemy
   function (_frame, _args)
      local enemy = _args.enemy or get_selected(enemies)
      set_cursor_to_element(combat_select, enemies)
      set_cursor_to_element(enemies, enemy)
      if _frame == 10 then
         -- _args is damage :: int       
         local base_damage = _args.damage
         local mod_damage = base_damage
         if enemy then
            --interrupt_action_queue(enum_actions.display_event)
            -- if player.mods.strength then
            --    mod_damage = base_damage + player.mods.strength
            -- end            
            if enemy.mods.vulnerable then
               mod_damage = base_damage + flr(base_damage*.5)
            end
            local damage, block = damage_block_calc(mod_damage, enemy.block)
            
            enemy.health -= damage
            enemy.health = clamp(enemy.health, 0, 999)
            enemy.block = block
            
            if enemy.health == 0 then
               immediate_add_action_queue(16, enemy)
            end
         end         
      end
      if _frame == 20 then
         return true
      end
   end,
   -- 16 kill enemy
   function (_frame, _args)
      if _frame == 35 then
         del(enemies.list, _args)
         reset_enemies_cursor()
         return true
      end
   end,
   -- 17 apply selected
   function (_frame, _args)
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
   end,
   -- 18 block
   function (_frame, _args)
      player.block += 5
      return true
   end,
   -- 19 enemies_turn_start
   function (_frame, _args)
      turn = "enemies"
      if _frame == 45 then
         set_cursor_to_element(combat_select, enemies)
         for enemy in all(enemies.list) do
            add_to_action_queue(24, enemy)
         end      
         for enemy in all(enemies.list) do
            add_to_action_queue(20, enemy)
         end
         add_to_action_queue(21)
         return true
      end
   end,
   -- 20 enemy_action
   function (_frame, _args)
      set_cursor_to_element(enemies, _args)
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
   end,
   -- 21 enemies_turn_end
   function (_frame, _args)
      set_cursor_none(combat_select)
      reset_enemies_cursor()  
      for enemy in all(enemies.list) do      
         enemy.turn += 1     
         enemy.intent = nil
         enemy.get_intent(enemy)
         if enemy.mods.vulnerable then
            enemy.mods.vulnerable = clamp(enemy.mods.vulnerable-1, 0, 100)
         end
         for k,v in pairs(enemy.mods) do
            if v == 0 then
               enemy.mods[k] = nil
            end
         end
      end
      add_to_action_queue(2)
      return true
   end,
   -- 22 delay
   function (_frame, _args)
      if _frame == _args then
         return true
      end
   end,
   -- 23 spend energy
   function (_frame, _args) 
      combat_player.energy -= _args
      return true
   end ,
   -- 24 enemy_turn start
   function (_frame, _args)
      set_cursor_to_element(enemies, _args)
      _args.block = 0
      if _frame == 30 then
         return true
      end
   end
}