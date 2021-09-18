pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- demake_the_spire.p8
-- source code for a pico-8 targeted demake of game slay the spire by Megacrit
-- by Jesse Bergerstock aka illMadeCoder
-- Developed in 2020

-- take note that the following code targets pico-8 which has a code token limit of 8192
-- and certain design decisions we're made to optimize towards that limit

-- any lines that end with --debug or sequence of lines that start with --debug_start to -- debug_end are designed to be removed for a release build
#include libs/utilities.p8
#include libs/print_helpers.p8
#include libs/debug_helpers.p8
#include libs/list_cursor.p8
#include libs/enum_colors.p8
#include libs/enum_buttons.p8
#include libs/enum_game_turns.p8
#include libs/game_state.p8
#include libs/card.p8
#include libs/mods.p8
#include libs/action.p8
#include libs/action_queue.p8
#include libs/enemy.p8
#include libs/graphics.p8
#include libs/graphic_buffer.p8
#include libs/backgrounds.p8

debug_mode = true -- debug
rnd_seed = rnd(100)
card_images = false
speed_mode = true
menuitem(1, "speed mode",
	 function ()
	    immediate_add_action_queue(enum_actions.toggle_speed_mode)
	 end
)

-- 8. pico-8 hooks
function _init()
   frame = 0

   enemies.list = enemy_ids_to_enemies({enum_enemies.jaw_worm})

   deck.list = card_ids_to_pile({enum_cards.strike,
   					  enum_cards.strike,
   					  enum_cards.strike,
   					  enum_cards.strike,
   					  enum_cards.strike,
   					  enum_cards.bash,
   					  enum_cards.defend,
   					  enum_cards.defend,
   					  enum_cards.defend,
					  enum_cards.defend})

   add_to_action_queue(enum_actions.combat_start)
end

function _update()
   update_action_queue()
   update_graphic_buffer()
   frame += 1
end

function _draw()
   cls()
   draw_graphic_buffer()
end

__gfx__
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000010010001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000010010001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
