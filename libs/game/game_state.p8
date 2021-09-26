pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
act = nil

player = {
   health = {
      max = 80,
      cur = 80
   },
   energy_init = 3,
   energy = 3,
   draw_power = 5,
   block = 0,
   mods = {}
}

-- list and cursors
relics = new_list_cursor()
potions = new_list_cursor()
deck = new_list_cursor()
hand = new_list_cursor()
discard = new_list_cursor()
draw = new_list_cursor()
exhaust = new_list_cursor()
enemies = new_list_cursor()

-- meta list and cursors
combat_select = new_list_cursor({relics, potions, exhaust, discard, draw, hand, enemies})
field_view = new_list_cursor({relics, enemies, potions, exhaust, discard, draw, hand})

-- 3.2 game_state state accessors
-- hand accessors
selected_card = nil

function can_play_card(_card)
   return player.energy - get_card_cost(_card) >= 0 
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