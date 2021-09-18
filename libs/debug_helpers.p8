pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- debug visuals
function draw_reticle(_x, _y)
   _x = _x or 63
   _y = _y or 63
   for i = 0, flr(127/2) do
      pset(_x, i*2, enum_colors.dark_green)
      pset(i*2, _y, enum_colors.dark_green)
   end
end


function draw_screen_edge()
   rect(0,0,127,127,enum_colors.dark_green)
end

-- debug to console
function dprint_card_pile(_card_pile)
   for card in all(_card_pile) do
      printh(card.name)
   end
end

function dprint_discard_pile()
   printh("drpint_discard_pile: " .. #get_discard())
   dprint_card_pile(get_discard())
end

function dprint_draw()
   printh("drpint_draw: " .. #get_draw())
   dprint_card_pile(get_draw())
end

function dprint_hand()
   printh("drpint_hand: " .. #get_hand())
   dprint_card_pile(get_hand())
end

function dprint_enemies()
   printh("dprint_enemies: " .. #get_enemies())
   for enemy in all(get_enemies()) do
      printh(enemy.name)
   end
end

function dprint_action_queue()
   printh("dprint action queue: " .. #action_queue)
   for i=1, #action_queue do
      printh(i .. ": " .. action_queue[i].name)
   end
end

function dprint_action_queue_log()
   printh("dprint action queue log: " .. #action_queue_log)
   for i=1, #action_queue_log do
      printh(i .. ": " .. action_queue_log[i])
   end
end
