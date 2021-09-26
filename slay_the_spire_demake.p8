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
#include libs/utility/utilities.p8
#include libs/utility/print_helpers.p8
#include libs/utility/debug_helpers.p8
#include libs/utility/list_cursor.p8
#include libs/utility/action_queue.p8
#include libs/game/game_state.p8
#include libs/game/card.p8 
#include libs/game/action.p8
#include libs/game/enemy.p8
#include libs/graphics/graphics.p8
#include libs/graphics/graphic_buffer.p8
#include libs/graphics/backgrounds.p8

debug_mode = true -- debug
rnd_seed = rnd(100)
card_images = false

-- 8. pico-8 hooks
function _init()
   frame = 0
   enemies.list = enemy_ids_to_enemies({1})
   deck.list = card_ids_to_pile({1,1,1,1,1})
   add_to_action_queue(1)
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
