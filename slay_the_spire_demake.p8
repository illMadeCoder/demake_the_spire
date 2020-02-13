spico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--[[ Constants --]]
c_colors = {
   black = 0,
   dark_blue = 1,
   dark_purple = 2,
   dark_green = 3,
   dark_orange = 4,
   dark_grey = 5,
   grey = 6,
   white = 7,
   red = 8,
   orange = 9,
   yellow = 10,
   green = 11,
   blue = 12,
   purple = 13,
   pink = 14,
   peach = 15
}

c_player_color = c_colors.pink
c_enemy_color = c_colors.dark_purple
c_card_color = c_colors.white
c_card_color_selected = c_player_color

--[[ general utility functions --]]
function shallow_clone(_object)
   assert(_object)
   local ret = {}
   for k,v in pairs(_object) do
      ret[k] = v
   end
   return ret
end

function print_centered(_str, _x, _y, _c)
   print(_str, _x - (#_str*4)/2, _y, _c)
end

function print_selected(_str, _x, _y, _c, _selected)
   print((_selected and "X" or "") .. _str, _x, _y, (_selected and c_player_color) or _c)
end	

function rotate(_x, _min, _max)
   return _x < _min and _max or (_x > _max and _min or _x)
end

function clamp(_x, _min, _max)
   return _x <= _min and _min or (_x >= _max and _max or _x)
end

function randomize_array_indexes(_array)
   local size = #_array
   local randomized_array = {}

   for i = 1, size do
      add(randomized_array, nil)
   end
   for elem in all(_array) do
      -- choose random inde
      local rnd_index = flr(rnd(size)+1)
      -- if random index has already been populated try again
      while randomized_array[rnd_index] != nil do
      	 rnd_index = flr(rnd(size)+1)
      end
      randomized_array[rnd_index] = elem
   end
   
   return randomized_array
end

game = {
   player = {
      health = {
	 max = 80,
	 cur = 80
      },
      deck = {},
      relics = {},
      potions = {},
      draw_power = 5
   },
   combat = {
      enemies = {},
      player = {
	 energy_max = 3,
	 energy = 3,
	 block = 0,
	 mods = {},	 
      },
      card_piles = {
	 draw = {},
	 discard = {},
	 hand = {},
	 exhaust = {}
      },
      hand_size = 0,
      cursors = {
	 hand = 0,
	 enemies = 0,
	 discard = 0,
	 utilities = 0
      },
      graphics = {	 
	 enemy_dead_flag = false,
	 discard_card = false
      },
      display_mode = 1,
      select_mode = 1,
      turn = 1
   }
}

c_display_modes = {
   hand = 1,
   draw = 2,
   discard = 3,
   relics = 4,
   potions = 5,
   enemies = 6
}

c_select_modes = {
   none = 1,
   hand = 2,
   enemies = 3,
   devices = 4
}

c_turns = {
   player = 1,
   enemies = 2
}

c_utilities = {
   draw_pile = 1,
   discard_pile = 2,
   relics = 3,
   potions = 4
}

--[[ state accesser methods --]]
function get_select_mode()
   return game.combat.select_mode
end

function set_select_mode(_arg)
   game.combat.select_mode = _arg
end

function get_selected_hand()
   return game.combat.card_piles.hand[game.combat.cursors.hand]
end

function get_selected_enemy()
   return game.combat.enemies[game.combat.cursors.enemies]
end

function reset_hand_cursor()
   game.combat.cursors.hand = flr(#game.combat.card_piles.hand/2)+1
end

function reset_enemies_cursor()
   game.combat.cursors.enemies = flr(#game.combat.enemies/2)+1
end

--[[
   a card takes the form:
   {
     name :: string,
     type :: card_type,
     get_action :: this_card -> action,
     get_description :: this_card -> string,
     get_cost :: this_card -> number
   }
   but may include 'private' helper methods to be used by the public methods
--]]

--[[ card utility functions --]]

card_types = {
   attack = 1,
   skill = 2,
   power = 3
}

card_prototypes = {
   strike = {
      name = "strike",
      type = card_types.attack,
      invoke_action = function (_this)
	 add_to_action_queue("select_from_enemies")
	 add_to_action_queue("attack_selected", 6)
      end,
      get_description = function (_this)
      end,
      get_cost = function (_this)
	 return 1
      end
   },
   defend = {
      name = "defend",
      type = card_types.action,
      invoke_action = function (_this)
	 add_to_action_queue("block", 5) 
      end,
      get_description = function (_this)
      end,
      get_cost = function (_this)
	 return 1
      end
   },
   anger = {
      name = "anger",
      type = card_types.attack,
      base_damage = 6,
      invoke_action = function (_this)
	 add_to_action_queue("select_from_enemies")
	 add_to_action_queue("attack_selected", _this.base_damage)
	 add_to_action_queue("add_to_discard_pile", _this)
      end,
      get_description = function (_this)
      end,
      get_cost = function (_this)
	 return 0
      end
   },
   bash = {
      name = "bash",
      type = card_types.attack,
      base_damage = 6,
      invoke_action = function (_this)
	 add_to_action_queue("select_from_enemies")
	 add_to_action_queue("attack_selected", _this.base_damage)
	 add_to_action_queue("apply_selected", {v=2})
      end,
      get_description = function (_this)
      end,
      get_cost = function (_this)
	 return 2
      end
   },
     clothesline = {
      name = "clothesline",
      type = card_types.attack,
      base_damage = 12,
      invoke_action = function (_this)
	 add_to_action_queue("select_from_enemies")
	 add_to_action_queue("attack_selected", _this.base_damage)
	 add_to_action_queue("apply_selected", {w=2})
      end,
      get_description = function (_this)
      end,
      get_cost = function (_this)
	 return 2
      end
   }
}

function new_card(_card_name)
   assert(card_prototypes[_card_name])
   return shallow_clone(card_prototypes[_card_name])
end

--[[ expects a list of strings of card names, returns a list of cards --]]
function card_names_to_pile(_card_names)
   local ret = {}
   for card_name in all(_card_names) do
      add(ret, new_card(card_name))
   end
   return ret
end

--[[ 
   a list of actions who take the form
   {
     callback :: frame -> args -> bool,
     frame :: integer,
     args :: object
   }

   an action is this game's way of representing discrete behavior that
   require x frames or condition to fully execute and occassionally
   multiple ordered steps. The callback boolean's result of truth
   indicate the end of an action's execution
--]]

--[[ action utility functions --]]
function move_card_from_a_to_b(_card, _card_pile_a, _card_pile_b)
   assert(_card_pile_a)
   assert(_card_pile_b)
   del(_card_pile_a, _card)
   add(_card_pile_b, _card)
end

function pop_card_from_a_to_b(_card_pile_a, _card_pile_b)
   move_card_from_a_to_b(_card_pile_a[#_card_pile_a], _card_pile_a, _card_pile_b)
end

-- returns a damage, block tuple
function damage_block_calc(_damage, _block)
   local damage_dealt = clamp(_damage - _block, 0, 999)   
   _block = clamp(_block - _damage, 0, 999)
   return damage_dealt, _block
end
   
action_callbacks = {
   combat_start = function (_frame, _args)
      --[[ initialize deck --]]
      game.combat.card_piles.draw = randomize_array_indexes(game.player.deck)
      reset_enemies_cursor()
      add_to_action_queue("player_turn_start")
      return true
   end,
   
   player_turn_start = function (_frame, _args)
      game.combat.display_mode = c_display_modes.hand
      game.combat.turn = c_turns.player
      game.combat.player.energy = game.combat.player.energy_max
      reset_enemies_cursor()
      add_to_action_queue("full_draw_to_hand")
      return true
   end,
   
   player_turn_end = function (_frame, _args)
      set_select_mode(c_select_modes.none)
      add_to_action_queue("full_hand_to_discard")
      add_to_action_queue("enemies_turn_start")
      return true
   end,

   enemies_turn_start = function (_frame, _args)
      game.combat.turn = c_turns.enemies
      game.combat.display_mode = c_display_modes.enemies
      if _frame == 45 then
	 add_to_action_queue("enemies_actions")
	 return true
      end
   end,

   enemies_actions = function (_frame, _args)
      for i=1, #game.combat.enemies do
	 add_to_action_queue("enemy_action", i)
      end
      add_to_action_queue("enemies_turn_end")
      return true
   end,

   enemy_action = function (_frame, _args)
      if _frame == 0 then
	 game.combat.cursors.enemies = _args
      end
      if _frame == 15 then
	 game.combat.enemies[game.combat.cursors.enemies]:invoke_action()
      end
      if _frame == 30 then
	 return true
      end
   end,

   enemies_turn_end = function (_frame, _args)
      set_select_mode(c_select_modes.none)
      add_to_action_queue("player_turn_start")
      return true
   end,
   
   full_hand_to_discard = function (_frame, _args)
      for i=1, #game.combat.card_piles.hand do
	 immediate_add_action_queue("discard_card", game.combat.card_piles.hand[i])
      end
      return true
   end,

   single_hand_to_discard = function (_frame, _args)
      if _frame == 10 then
	 pop_card_from_a_to_b(game.combat.card_piles.hand,
			      game.combat.card_piles.discard)
	 game.combat.cursors.hand = #game.combat.card_piles.hand
	 return true
      end
   end,

   delay = function (_frame, _args)
      if _frame == _args then
	 return true
      end
   end,
   
   full_draw_to_hand = function (_frame, _args)
      for i=1, game.player.draw_power do
	 add_to_action_queue("single_draw_to_hand")
      end
      add_to_action_queue("select_from_hand")
      return true
   end,
   
   single_draw_to_hand = function (_frame, _args)
      local card_draw =
	 game.combat.card_piles.draw[flr(rnd(#game.combat.card_piles.draw))+1]

      if not card_draw and #game.combat.card_piles.discard > 0 then
      	 interrupt_action_queue("full_discard_to_draw")
      	 return false
      end
      
      if _frame == 15 or #game.combat.card_piles.draw == 0 then
   	 return true
      end

      if _frame == 5 then
   	 del(game.combat.card_piles.draw, card_draw)

   	 add(game.combat.card_piles.hand, card_draw)
	 
   	 game.combat.cursors.hand = #game.combat.card_piles.hand
      end
   end,
   
   full_discard_to_draw = function (_frame, _args)
      for i=1, #game.combat.card_piles.discard do
	 immediate_add_action_queue("single_discard_to_draw")
      end
      immediate_add_action_queue("randomize_draw")
      return true
   end,

   randomize_draw = function (_frame, _args)
      game.combat.card_piles.draw = randomize_array_indexes(game.combat.card_piles.draw)
      return true
   end,
   
   single_discard_to_draw = function (_frame, _args)
      if _frame == 3 then
        pop_card_from_a_to_b(game.combat.card_piles.discard, game.combat.card_piles.draw)
	return true
      end
   end,
   
   select_from_hand = function (_frame, _args)
      -- todo this logic needs to be somewhere cleaner
      game.combat.cursors.utilities = 0
      game.combat.display_mode = c_display_modes.hand
      set_select_mode(c_select_modes.hand)
      if _frame == 0 then
   	 reset_hand_cursor()
      end
      if btnp(0) then
   	 game.combat.cursors.hand -= 1
      elseif btnp(1) then
   	 game.combat.cursors.hand += 1
      end
      game.combat.cursors.hand = rotate(game.combat.cursors.hand,
   					1,
   					#game.combat.card_piles.hand)

      -- play card from hand
      local selected_card = get_selected_hand()
      if selected_card
   	 and game.combat.player.energy - selected_card:get_cost() >= 0
   	 and btnp(4)
      then
   	 game.combat.player.energy -= selected_card:get_cost()
	 add_to_action_queue("invoke_card", selected_card)
   	 return true
      end
      
      if btnp(2) then
	 add_to_action_queue("view_enemies")
	 return true
      end

      if btnp(3) then
	 add_to_action_queue("view_devices")
	 return true
      end

      if btnp(5) then
	 add_to_action_queue("player_turn_end")
	 return true
      end
      
      return false
   end,

   view_devices = function (_frame, _args)
      if _frame == 0 then
	 game.combat.cursors.utilities = 1
      end
      
      set_select_mode(c_select_modes.devices)
      if btnp(2) then
	 game.combat.cursors.utilities -= 1
      end

      if btnp(3) then
	 game.combat.cursors.utilities += 1
      end

      game.combat.cursors.utilities = clamp(game.combat.cursors.utilities, 0, 4)

      if game.combat.cursors.utilities <= 0 then
	 add_to_action_queue("select_from_hand")	 
	 return true
      elseif btnp(4) then
      	 if game.combat.cursors.utilities == c_utilities.draw_pile then
  	    add_to_action_queue("view_draw")
            return true
	 elseif game.combat.cursors.utilities == c_utilities.discard_pile then	 
  	    add_to_action_queue("view_discard")
            return true	 end
      end
   end,

   view_draw = function (_frame)
     if _frame == 0 then
       game.combat.display_mode = c_display_modes.draw
       game.combat.cursors.draw = flr(#game.combat.card_piles.draw/2)+1
     end
     
     if btnp(0) then
     	game.combat.cursors.draw -= 1 
     end
     
     if btnp(1) then
     	game.combat.cursors.draw += 1 
     end

     game.combat.cursors.draw = clamp(game.combat.cursors.draw, 1, #game.combat.card_piles.draw)

     if btnp(4) then
       add_to_action_queue("select_from_hand")
       return true
     end
   end,

   view_discard = function (_frame)
     if _frame == 0 then
       game.combat.display_mode = c_display_modes.discard
       game.combat.cursors.discard = flr(#game.combat.card_piles.discard/2)+1
     end
     if btnp(4) then
       add_to_action_queue("select_from_hand")
       return true
     end
   end,

   invoke_card = function (_frame, _args)
      _args:invoke_action()
      add_to_action_queue("discard_card", _args)
      add_to_action_queue("select_from_hand")
      return true
   end,   
   
   discard_card = function (_frame, _args)      
      game.combat.graphics.discard_card = true
      if _frame == 15 then
	 del(game.combat.card_piles.hand, _args)
	 add(game.combat.card_piles.discard, _args)
	 reset_hand_cursor()
	 game.combat.graphics.discard_card = false
	 return true
      end
   end,   
   
   select_from_enemies = function (_frame, _args)
      set_select_mode(c_select_modes.enemies)
      
      if btnp(0) then
	 game.combat.cursors.enemies -= 1
      elseif btnp(1) then
	 game.combat.cursors.enemies += 1
      end
      
      game.combat.cursors.enemies = rotate(game.combat.cursors.enemies,
      					   1,
      					   #game.combat.enemies)
      if btnp(4) then
	 set_select_mode(c_select_modes.none)
	 return true
      end
   end,

   view_enemies = function (_frame, _args)
      set_select_mode(c_select_modes.enemies)
      if btnp(0) then
	 game.combat.cursors.enemies -= 1
      elseif btnp(1) then
	 game.combat.cursors.enemies += 1
      end
      
      game.combat.cursors.enemies = rotate(game.combat.cursors.enemies,
					   1,
					   #game.combat.enemies)
      if btnp(3) then
	 add_to_action_queue("select_from_hand")
	 return true
      end
   end,
   
   attack_selected = function (_frame, _args)
      -- _args is damage :: int 
      if _frame == 5 then
	 local enemy = get_selected_enemy()
	 if enemy then
	    local damage, block = damage_block_calc(_args, enemy.block)
	    
	    enemy.health -= damage
	    enemy.health = clamp(enemy.health, 0, 999)
	    enemy.block = block
	    
	    if enemy.health == 0 then
	       immediate_add_action_queue("kill_enemy", enemy)
	    end
	 end
	 return true
      else
	 return false
      end      
   end,

   kill_enemy = function (_frame, _args)
      game.combat.graphics.enemy_dead_flag = true
      if _frame == 35 then
	 del(game.combat.enemies, _args)
	 reset_enemies_cursor()
         game.combat.graphics.enemy_dead_flag = false
	 return true
      end
   end,
   
   apply_selected = function (_frame, _args)
      -- _args is damage :: int 
      if _frame == 5 then
	 local enemy = get_selected_enemy()
	 assert(enemy)
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
   
   block = function (_frame, _args)
      game.combat.player.block += 5
      return true
   end,
   
   add_to_discard_pile = function (_frame, _args)
      add(game.combat.card_piles.discard, _args)
      return true
   end   
}

function new_action(_action_name, _args)
   assert(action_callbacks[_action_name] != nil)

   return {
      name = _action_name,
      callback = action_callbacks[_action_name],
      args = _args,
      frame = 0
   }
end

--[[ 
   The action_queue is an array of action objects to be executed in
   the order they were inserted (fifo)
--]]

action_queue = {}
action_queue_log = {}

function update_action_queue()
   local action = action_queue[1]
   if action == nil then
      return
   else
      if action.callback(action.frame, action.args) then
	 del(action_queue, action)
	 log_action_queue("del", action.name)
      end
      action.frame += 1
   end
end

function interrupt_action_queue(_action_name, _args)
   local new_action_queue = {}

   add(new_action_queue, new_action(_action_name, _args))

   for action in all(action_queue) do
      add(new_action_queue, action)
   end

   action_queue = new_action_queue

   log_action_queue("int", _action_name)
end

function immediate_add_action_queue(_action_name, _args)
   local new_action_queue = {}
   add(new_action_queue, action_queue[1])
   add(new_action_queue, new_action(_action_name, _args))
   
   for i=2, #action_queue do
      add(new_action_queue, action_queue[i])
   end
   
   action_queue = new_action_queue
   log_action_queue("imm", _action_name)
end

function add_to_action_queue(_action_name, _args)
   add(action_queue, new_action(_action_name, _args))
   log_action_queue("add", _action_name)
end

function log_action_queue(_change, _action_name)
   add(action_queue_log, _change .. ": " .. _action_name)
   for action in all(action_queue) do
      add(action_queue_log, " " .. action.name)
   end
end

--[[
   a list of enemy prototypes that take the form:
   {
     name :: string,
     health :: { max :: number, cur :: number },
     block :: number,
     mods :: { modifiers },
     get_intent :: _this_enemy -> string,
     get_action :: _this_enemy -> _action
   }
--]]

enemy_prototypes = {
   dummy = {
      name = "dummy",
      health = 10,
      block = 5,      
      get_intent = function (_this)
	 return "d6"
      end,
      invoke_action = function (_this)
	 local d,b = damage_block_calc(6, game.combat.player.block)
	 game.player.health.cur -= d
	 game.combat.player.block = b
      end
   }
}

function new_enemy(_enemy_prototype)
   return {
      name = _enemy_prototype.name,
      health = _enemy_prototype.health,
      block = _enemy_prototype.block or 0,
      mods = _enemy_prototype.mods or {},
      get_intent = _enemy_prototype.get_intent,
      invoke_action = _enemy_prototype.invoke_action
   }
end

--[[ expects a list of strings of enemy names, returns a list of enemies --]]
function enemy_names_to_enemies(_enemy_names)
   local ret = {}
   for enemy_name in all(_enemy_names) do
      add(ret, new_enemy(enemy_prototypes[enemy_name]))
   end
   return ret
end

function _init()
   game.combat.enemies = enemy_names_to_enemies({"dummy",
   						 "dummy",
   						 "dummy"})

   game.player.deck = card_names_to_pile({"strike",
   					  "strike",
   					  "strike",
   					  "strike",
   					  "strike",
   					  "bash",
   					  "defend",
   					  "defend",
   					  "defend"})

   add_to_action_queue("combat_start")
end

function _update()
   update_action_queue()
end

function display_card_background(_x, _y, _c)
   rectfill(_x, _y, _x+12, _y+15, _c or c_colors.orange)
end

function display_combat()
   display_combat_player(0,98)
   display_utilities(63, 104)

   if game.combat.display_mode == c_display_modes.hand then
      display_hand(0, 40)
   elseif game.combat.display_mode == c_display_modes.draw then   
      display_draw(0, 40)
   elseif game.combat.display_mode == c_display_modes.discard then
      display_discard(0,40)
   elseif game.combat.display_mode == c_display_modes.enemies then
      display_enemies_turn(0,40)
   end
   
   if #game.combat.enemies > 0 then
      display_combat_enemies(0, 0)
   end
end

function display_enemies_turn(_x, _y)
   print("enemies", 40, _y, c_colors.dark_blue)
end

function display_combat_player(_x, _y)
   print("player", _x, _y, c_player_color)
   print("energy:(" .. game.combat.player.energy .. ")", _x+4, _y+6, c_colors.yellow)
   print("health:" .. game.player.health.cur .. "/" .. game.player.health.max,
	 _x+4, _y+12, c_colors.red)
   print("block:" .. game.combat.player.block, _x+4, _y+18, c_colors.grey)
   print("mods:", _x+4, _y+24, c_colors.dark_grey)
end

function display_utilities(_x, _y)
   local cursor = game.combat.cursors.utilities
   display_draw_pile(_x, _y, cursor == c_utilities.draw_pile)
   display_discard_pile(_x, _y+6, cursor == c_utilities.discard_pile)
   display_relics(_x, _y+12, cursor == c_utilities.relics)
   display_potions(_x, _y+18, cursor == c_utilities.potions)
end

function display_relics(_x, _y, _selected)
   print_selected("relics:" .. #game.player.relics, _x, _y, c_colors.dark_green, _selected)
end

function display_potions(_x, _y, _selected)
   print_selected("potions:" .. #game.player.potions, _x, _y, c_colors.purple, _selected) 
end

function display_draw_pile(_x, _y, _selected)
   print_selected("draw:" .. #game.combat.card_piles.draw, _x, _y, c_colors.orange, _selected)
end

function display_discard_pile(_x, _y, _selected)
   print_selected("disc:" .. #game.combat.card_piles.discard, _x, _y, c_colors.dark_orange, _selected)
end

function get_card_color(_card)
   return (get_selected_hand() == _card and game.combat.graphics.discard_card) and c_colors.dark_blue or
      (get_select_mode() == c_select_modes.hand and get_selected_hand() == _card)
      and c_card_color_selected
      or c_card_color
end

function display_focus_sides(_list, _focus_index, _x, _y, _display_focus, _display_side)
   if _list[_focus_index] then
      _display_focus(_list[_focus_index], _x+63, _y)
   end
   
   for i=1, _focus_index-1 do
      _display_side(_list[i], _x, _y-i*6+(_focus_index)*6)
   end

   for i=_focus_index+1, #_list do
      _display_side(_list[i], _x+100, _y+(i-_focus_index)*6)
   end   
end

function display_cards(_cards, _focus_index, _x, _y)
   display_focus_sides(_cards, _focus_index, _x, _y, display_card_focus, display_card_side)
end

function display_card_focus(_card,_x,_y)
   print_centered("(" .. _card.get_cost() .. ")\n" .. _card.name,
	 _x,
	 _y,
	 get_card_color(_card)
   )
end

function display_card_side(_card, _x, _y)
   print(_card.name,
	 _x,
	 _y,
	 c_colors.white)
end

function display_hand(_x, _y)
   local hand = game.combat.card_piles.hand
   local hand_size = #hand
   print("your hand", 40, _y, c_colors.dark_blue)
   display_cards(hand, game.combat.cursors.hand, _x, _y+8)   
end

function display_draw(_x, _y)
   local hand = game.combat.card_piles.draw
   local hand_size = #hand
   print("your draw", 40, _y, c_colors.dark_blue)
   display_cards(hand, game.combat.cursors.draw, _x, _y+8)   
end

function display_discard(_x, _y)
   local hand = game.combat.card_piles.discard
   local hand_size = #hand
   print("your discard", 40, _y, c_colors.dark_blue)
   display_cards(hand, game.combat.cursors.discard, _x, _y+8)   
end	 

function display_combat_enemies(_x, _y)
   local enemies_cursor = game.combat.cursors.enemies
   local enemies = game.combat.enemies
   display_focus_sides(enemies, enemies_cursor, _x, _y, display_enemy_focused, display_enemy_side)		        
end

function display_enemy_side(_enemy, _x, _y)
   print(_enemy.name, _x, _y, c_enemy_color)
end

function display_enemy_focused(_enemy, _x, _y)
   _x = _x - 24
   local c = 
      (game.combat.turn == c_turns.enemies and action_queue[1].name == "enemy_action") and c_colors.red
      or
      (get_select_mode() == c_select_modes.enemies and
	  get_selected_enemy() == _enemy) and c_player_color
      or c_enemy_color

   local enemy_dead_col = game.combat.graphics.enemy_dead_flag and c_colors.dark_blue or nil
   print(_enemy.name, _x, _y, enemy_dead_col or c)
   print("intent:" .. _enemy:get_intent(), _x+4, _y+6, enemy_dead_col or c_colors.orange)
   print("health:" .. _enemy.health, _x+4, _y+12, enemy_dead_col or c_colors.red)
   print("block:" .. _enemy.block, _x+4, _y+18, enemy_dead_col or c_colors.grey)
   local mods_str = ""
   for k,v in pairs(_enemy.mods) do
      mods_str = mods_str .. k .. v .. ","
   end
   print("mods:" .. sub(mods_str, 1, #mods_str-1), _x+4, _y+24, enemy_dead_col or c_colors.dark_grey)
end

function _draw()   
   cls()
   display_combat()
end

--[[ debug to console --]]
function dprint_card_pile(_card_pile)
   for card in all(_card_pile) do
      printh(card.name)
   end
end

function dprint_discard_pile()
   local hand = game.combat.card_piles.discard
   printh("drpint_discard_pile: " .. #hand)
   dprint_card_pile(hand)
end

function dprint_draw()
   local hand = game.combat.card_piles.draw
   printh("drpint_draw: " .. #hand)
   dprint_card_pile(hand)
end

function dprint_hand()
   local hand = game.combat.card_piles.hand
   printh("drpint_hand: " .. #hand)
   dprint_card_pile(hand)
end

function dprint_enemies()
   printh("dprint_enemies: " .. #game.combat.enemies)
   for enemy in all(game.combat.enemies) do
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
