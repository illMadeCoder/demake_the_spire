pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
frame = 0

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
field_view = new_list_cursor({relics, potions, exhaust, discard, draw, hand})

-- 3.2 game_state state accessors
-- hand accessors
function get_hand()
   return hand.list
end

function get_hand_cursor()
   return hand.cursor
end

function get_selected_card_from_hand()
   return get_selected(hand)
end

selected_card = nil
function get_selected_card()
   return selected_card
end

function can_play_card(_card)
   return player.energy - get_card_cost(_card) >= 0 
end

function is_selected_card_from_hand(_card)
   return is_selected(hand, _card)
end

function reset_hand_cursor()
   set_cursor_mid(hand)
end

function set_hand_cursor_to_end()
   hand.cursor = #get_hand()
end

function set_hand_cursor_to_end()
   hand.cursor = #get_hand()
end

function pop_hand_to_discard()
   return pop_card_from_a_to_b(get_hand(), get_discard())
end

-- draw pile
function get_draw()
   return draw.list
end

function reset_draw_cursor()
   set_cursor_mid(draw)
end

function get_draw_cursor()
   return draw.cursor
end

function randomize_draw_pile()
   draw.list = randomize_array_indexes(get_draw())
end

function init_draw_pile()
   draw.list = randomize_array_indexes(deck.list)
end

function pop_draw_to_hand()
   return pop_card_from_a_to_b(get_draw(), get_hand())
end

function is_draw_empty()
   return #get_draw() == 0
end

-- discard accessors
function get_discard()
   return discard.list
end

function is_discard_empty() --inline
   return #get_discard() == 0
end

function reset_discard_cursor()
   set_cursor_mid(discard)
end

function pop_discard_to_draw()
   return pop_card_from_a_to_b(get_discard(), get_draw())
end

--exhaust
function get_exhaust()
   return exhaust.list
end

-- enemy accessors
function reset_enemies_cursor()
   set_cursor_mid(enemies)
end

function reset_all_cursors()
   reset_hand_cursor()
   reset_draw_cursor()
   reset_discard_cursor() 
   set_cursor_to_element(combat_select, hand)
   set_cursor_to_element(field_view, hand)   
end

function get_potions()
   return potions.list
end

function get_relics()
   return relics.list
end