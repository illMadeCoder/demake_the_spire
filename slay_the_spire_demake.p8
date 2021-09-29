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
#include libs/utility/list_cursor.p8
#include libs/game/universal/game.p8
#include libs/game/universal/card.p8
#include libs/game/universal/action.p8
#include libs/game/universal/action_queue.p8
#include libs/game/combat/combat_action.p8
#include libs/game/combat/enemy.p8
#include libs/game/combat/combat.p8
#include libs/graphics/backgrounds.p8
#include libs/graphics/print_helpers.p8
#include libs/graphics/combat_graphics.p8
#include libs/game/combat/mod.p8

-- #include libs/tests/test.p8
-- #include libs/tests/combat/combat.p8
-- #include libs/tests/combat/cards.p8

debug_mode = true -- debug
rnd_seed = rnd(100)

-- 8. pico-8 hooks
function _init()
   frame = 0
   mod_display_frame = 0
   init_game({1,2,2,1,1,2,2,2})
   init_combat({1,1})
end

function _update()
   update_action_queue()   
   update_combat()   
   frame += 1
   mod_display_frame += 1
end

function _draw()
   cls()   
   draw_combat()
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
