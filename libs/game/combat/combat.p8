pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

function init_combat(_enemy_ids)    
    combat_player = {
      energy = 3,
      block = 0,
      mods = {new_mod(1,2), new_mod(2,1)}      
    }

    hand = new_list_cursor()
    discard = new_list_cursor()
    draw = new_list_cursor()
    exhaust = new_list_cursor()
    enemies = new_list_cursor(enemy_ids_to_enemies({1,1,1}))
    player_mods_list_cursor = new_list_cursor(combat_player.mods)
    enemy_mods_list_cursor = new_list_cursor(combat_player.mods)
    enemy_mods_list_cursor.cursor = 1
    field = {frame = 0}
    
    -- move left and right
    combat_select = new_list_cursor({relics, potions, exhaust, discard, draw, player_mods_list_cursor, hand, enemy_mods_list_cursor, enemies})
    -- moves up and down
    field_view = new_list_cursor({relics,  enemy_mods_list_cursor, enemies, potions, exhaust, discard, draw, player_mods_list_cursor, hand})   
    selected_card = nil

    add_to_action_queue(1)
end 

function update_combat()
   field.frame += 1
end

function can_play_card(_card)
   return combat_player.energy - get_card_cost(_card) >= 0 
end

-- enemy accessors
function reset_enemies_cursor()
   set_cursor_mid(enemies)
end

function reset_all_cursors()
   set_cursor_mid(hand)
   set_cursor_mid(draw)
   set_cursor_mid(discard) 
   set_cursor_to_element(combat_select, hand)
   set_cursor_to_element(field_view, hand)   
end