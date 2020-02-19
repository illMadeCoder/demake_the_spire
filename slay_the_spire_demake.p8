pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- demake_the_spire.p8
-- source code for a pico-8 targeted demake of game slay the spire by Megacrit
-- by Jesse Bergerstock aka illMadeCoder
-- Developed in 2020

-- take note that the following code targets pico-8 which has a code token limit of 8192
-- and certain design decisions we're made to optimize towards that limit

-- also any lines that end with --debug or sequence of lines that start with --debug start to --debug end are designed to be removed for a release build

-- table of contents
-- note that this is not always up to date but is still useful
-- 1. general utility functions
-- 1.1 object functions
-- 1.2 print and string
-- 1.3 numeric
-- 1.4 array
-- 2. general game enums
-- 2.1 pico-8 enums
-- 2.2 game state enums
-- 2.3 game object enums
-- 3. state
-- 3.1 display state
-- 3.2 game state
-- 3.3 game state method
-- 4 the card object
-- 4.1 card prototypes
-- 4.2 card constructor
-- 4.3 general card methods
-- 5. the action object
-- 5.1 action helper methods
-- 5.2 action callbacks
-- 5.2.1 combat state
-- 5.2.1.1 player actions
-- 5.2.1.2 card control
-- 5.2.1.3 use card
-- 5.2.1.4 player combat
-- 5.2.1.5 enemies action
-- 5.2.1.6 general
-- 5.3 action constructor
-- 5. the action_queue singleton
-- 6. the enmy object
-- 6. enemy constructors
-- 7. display
-- 7.1 display variables
-- 7.2 helpers
-- 7.3 combat
-- 7.3.3 player
-- 7.3.4 enemies
-- 8. pico-8 hooks
-- 9. debug helpers --debug

debug = false --debug

--debug start
-- debug helpers
-- debug visual
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
--debug end

-- test variables
card_images = false

-- 1. general utility functions
-- 1.0 types
function is_num(_x)
   return type(_x) == "number"
end

function is_str(_x)
   return type(_x) == "string"
end

function is_bool(_x)
   return type(_x) == "boolean"
end

function is_function(_x)
   return type(_x) == "function"
end

function is_object(_x)
   return type(_x) == "table"
end

function is_in_enum(_x, _enum)
   local ret = false
   for k,v in pairs(_enum) do
      ret = ret or _x == v
   end
   return ret
end

-- 1.1 object
function shallow_clone(_object)
   assert(_object)
   local ret = {}
   for k,v in pairs(_object) do
      ret[k] = v
   end
   return ret
end

-- this function allows a developer to have some method for each
-- member of an enum such that an enum val can be applied to a map to
-- return the appropriate function dispatch
function enum_to_function_map(_map, _enum_val, _enum)
   for k,v in pairs(_enum) do
      if _enum_val == v then
	 assert(_map[v], k) --debug
	 return _map[v]
      end
   end
end

-- 1.2 print and string
function shorten_str(_str, _shorten)
   return sub(_str,0,_shorten)
end

function print_centered(_str, _x, _y, _c)
   print(_str, _x - #_str*2, _y, _c)
end

function print_right_just(_str, _x, _y, _c)
   print(_str, _x - #_str*4, _y, _c)
end

function print_selected(_str, _x, _y, _c, _selected)
   print((_selected and "X" or "") .. _str, _x, _y, (_selected and enum_game_colors.player_color) or _c)
end

function split_str(_str, _split_char)
   local ret = {}
   local index = 1
   local cur = ""
   while (#_str >= index) do
      local char = sub(_str, index, index)
      if char == _split_char then
	 add(ret, cur)
	 cur = ""
      else
	 cur = cur .. char
      end
      index += 1
   end
   if ret != "" then
      add(ret, cur)
   end
   return ret
end

-- 1.3 numeric
function lerp(_percent, _min, _max)
   return _percent*(_max-_min)+_min
end

function rotate(_x, _min, _max)
   return _x < _min and _max or (_x > _max and _min or _x)
end

function clamp(_x, _min, _max)
   return _x <= _min and _min or (_x >= _max and _max or _x)
end

-- 1.4 array
function randomize_array_indexes(_array)
   local size = #_array
   local randomized_array = {}

   for i = 1, size do
      add(randomized_array, nil)
   end
   for elem in all(_array) do
      -- choose random index
      local rnd_index = flr(rnd(size)+1)
      -- if random index has already been populated try again
      while randomized_array[rnd_index] != nil do
      	 rnd_index = flr(rnd(size)+1)
      end
      randomized_array[rnd_index] = elem
   end
   
   return randomized_array
end

-- 2. pico-8 enums
enum_buttons = {
  left =  0,
  right = 1,
  up =    2,
  down =  3,
  z =     4,
  x =     5
}

enum_colors = {
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

-- 3. game state
-- game state enums
enum_field_modes = {
   hand = 1,
   draw = 2,
   discard = 3,
   relics = 4,
   potions = 5,
   enemies = 6
}

enum_field_select_modes = {
   none = 1,
   hand = 2,
   enemies = 3,
   devices = 4
}

enum_turns = {
   player = 1,
   enemies = 2
}

enum_utilities = {
   relics = 1,
   potions = 2,
   draw_pile = 3,
   discard_pile = 4
}

-- 3.1 game state
game_state = {
   frame = 0,
   act = nil,
   player = {
      health = {
	 max = 80,
	 cur = 80
      },
      deck = {},
      relics = {},
      potions = {}
   },
   combat = {
      enemies = {},
      player = {
	 energy_max = 3,
	 energy = 3,
	 block = 0,
	 mods = {},	 
      },
      piles = {
	 draw = {},
	 discard = {},
	 hand = {},
	 exhaust = {}
      }, -- todo combine piles and cursors into new abstraction
      hand_size = 0,
      cursors = {
	 hand = 0,
	 enemies = 0,
	 discard = 0,
	 utilities = 0
      },
      field_mode = 1,
      field_select_mode = 1,
      turn = 1
   }
}

-- 3.2 game_state state accessors
-- field select mode
function is_field_select_mode(_enum_field_select_mode_val)
   return game_state.combat.field_select_mode == _enum_field_select_mode_val
end

function set_field_select_mode(_enum_field_select_mode_val)
   game_state.combat.field_select_mode = _enum_field_select_mode_val
end

-- deck
function get_deck()
   return game_state.player.deck
end

-- hand accessors
function get_hand()
   return game_state.combat.piles.hand
end

function get_hand_cursor()
   return game_state.combat.cursors.hand
end

function inc_hand_cursor()
   game_state.combat.cursors.hand += 1
   game_state.combat.cursors.hand = rotate(get_hand_cursor(), 1, #get_hand())
end

function dec_hand_cursor()
   game_state.combat.cursors.hand -= 1
   game_state.combat.cursors.hand = rotate(get_hand_cursor(), 1, #get_hand())
end

function get_selected_card_from_hand()
   return get_hand()[game_state.combat.cursors.hand]
end

function is_selected_card_from_hand(_card)
   return _card == get_hand()[game_state.combat.cursors.hand]
end

function reset_hand_cursor()
   game_state.combat.cursors.hand = flr(#get_hand()/2)+1
end

function set_hand_cursor_to_end()
   game_state.combat.cursors.hand = #get_hand()
end

function set_hand_cursor_to_end()
   game_state.combat.cursors.hand = #get_hand()
end

function pop_hand_to_discard()
   return pop_card_from_a_to_b(get_hand(), get_discard())
end

-- draw pile
function get_draw()
   return game_state.combat.piles.draw
end

function get_draw_cursor()
   return game_state.combat.cursors.draw
end

function inc_draw_cursor()
   game_state.combat.cursors.draw += 1
   game_state.combat.cursors.draw = rotate(get_draw_cursor(), 1, #get_draw())
end

function dec_draw_cursor()
   game_state.combat.cursors.draw -= 1
   game_state.combat.cursors.draw = rotate(get_draw_cursor(), 1, #get_draw())
end

function randomize_draw_pile()
   game_state.combat.piles.draw = randomize_array_indexes(get_draw())
end

function init_draw_pile()
   game_state.combat.piles.draw = randomize_array_indexes(get_deck())
end

function pop_draw_to_hand()
   return pop_card_from_a_to_b(get_draw(), get_hand())
end

function is_draw_empty()
   return #get_draw() == 0
end

-- discard accessors
function get_discard()
   return game_state.combat.piles.discard
end

function is_discard_empty()
   return #get_discard() == 0
end

function reset_discard_cursor()
   game_state.combat.cursors.discard = flr(#game_state.combat.piles.discard/2)+1
end

function pop_discard_to_draw()
   return pop_card_from_a_to_b(get_discard(), get_draw())
end

function inc_discard_cursor()
   game_state.combat.cursors.discard += 1
   game_state.combat.cursors.discard = rotate(get_discard_cursor(), 1, #get_discard())
end

function dec_discard_cursor()
   game_state.combat.cursors.discard -= 1
   game_state.combat.cursors.discard = rotate(get_discard_cursor(), 1, #get_discard())
end

-- enemy accessors
function get_enemies()
   return game_state.combat.enemies
end

function get_selected_enemy()
   return game_state.combat.enemies[game_state.combat.cursors.enemies]
end

function reset_enemies_cursor()
   game_state.combat.cursors.enemies = flr(#game_state.combat.enemies/2)+1
end

-- 4 the card object
-- a card takes the form:
-- {
--   name :: string,
--   type :: card_type,
--   get_action :: this_card -> action,
--   get_description :: this_card -> string,
-- }
-- but may include 'private' helper methods to be used by the public methods
enum_card_types = {
   attack = 1,
   skill = 2,
   power = 3,
   status = 4
}

enum_mods = {
   weakness = 1
}

mods_function_map = {}
mods_function_map[enum_mods.weakness] = function (_damage)
   return _flr(_damage/2)
end

enum_relics = {}
relics_function_map = {}

-- 4.1 card prototypes
card_prototypes = {
   strike = {
      name = "strike",
      type = enum_card_types.attack,
      base_cost = 1,
      invoke_action = function (_this)
	 add_to_action_queue("select_from_enemies")
	 add_to_action_queue("attack_enemy", 6)
      end,
      get_description = function (_this)
	 return "deal 6 damage"
      end
   },
   defend = {
      name = "defend",
      type = enum_card_types.action,
      base_cost = 1,
      invoke_action = function (_this)
	 add_to_action_queue("block", 5) 
      end,
      get_description = function (_this)
	 return "get 5 block"
      end
   },
   anger = {
      name = "anger",
      type = enum_card_types.attack,
      base_damage = 6,
      base_cost = 0,
      invoke_action = function (_this)
	 add_to_action_queue("select_from_enemies")
	 add_to_action_queue("attack_enemy", _this.base_damage)
	 add_to_action_queue("add_to_discard_pile", _this)
      end,
      get_description = function (_this)
	 return ""
      end
   },
   bash = {
      name = "bash",
      type = enum_card_types.attack,
      base_damage = 6,
      base_cost = 2,
      invoke_action = function (_this)
	 add_to_action_queue("select_from_enemies")
	 add_to_action_queue("attack_enemy", _this.base_damage)
	 add_to_action_queue("apply_selected", {v=2})
      end,
      get_description = function (_this)
	 return "deal 6 apply 2w"
      end
   },
     clothesline = {
      name = "clothesline",
      type = enum_card_types.attack,
      base_damage = 12,
      base_cost = 2,
      invoke_action = function (_this)
	 add_to_action_queue("select_from_enemies")
	 add_to_action_queue("attack_enemy", _this.base_damage)
	 add_to_action_queue("apply_selected", {w=2})
      end,
      get_description = function (_this)
	 return ""
      end
   }
}

-- 4.2 card constructor
function new_card(_card_name)
   assert(card_prototypes[_card_name])
   return shallow_clone(card_prototypes[_card_name])
end

-- 4.2 general card methods
function get_card_cost(_card)
   return _card.base_cost
end

-- expects a list of strings of card names, returns a list of cards
function card_names_to_pile(_card_names)
   local ret = {}
   for card_name in all(_card_names) do
      add(ret, new_card(card_name))
   end
   return ret
end

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
   assert(_card_pile_a)
   assert(_card_pile_b)
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
action_callbacks = {
   -- 5.2.1 combat action callback
   combat_start = function (_frame, _args)
      -- initialize deck
      init_draw_pile()
      reset_enemies_cursor()
      add_to_action_queue("player_turn_start")
      return true
   end,

   -- 5.2.1.1 player actions
   player_turn_start = function (_frame, _args)
      game_state.combat.field_mode = enum_field_modes.hand
      game_state.combat.turn = enum_turns.player
      game_state.combat.player.energy = game_state.combat.player.energy_max
      reset_enemies_cursor()
      add_to_action_queue("full_draw_to_hand")
      return true
   end,
   
   player_turn_end = function (_frame, _args)
      set_field_select_mode(enum_field_select_modes.none)
      add_to_action_queue("full_hand_to_discard")
      add_to_action_queue("enemies_turn_start")
      return true
   end,

   -- 5.2.1.2 card control

   -- hand to discard
   full_hand_to_discard = function (_frame, _args)
      for i=1, #game_state.combat.piles.hand do
	 immediate_add_action_queue("discard_card", game_state.combat.piles.hand[i])
      end
      return true
   end,

   single_hand_to_discard = function (_frame, _args)
      if _frame == 10 then
	 pop_hand_to_discard()
	 set_hand_cursor_to_end()
	 return true
      end
   end,

   -- draw to hand
   full_draw_to_hand = function (_frame, _args)
      for i=1, 5 do
	 add_to_action_queue("single_draw_to_hand")
      end
      add_to_action_queue("reset_hand_cursor")
      add_to_action_queue("player_turn_main")
      return true
   end,
   
   single_draw_to_hand = function (_frame, _args)
      if is_draw_empty() and not is_discard_empty() then
      	 interrupt_action_queue("full_discard_to_draw")
      elseif _frame == 15 or is_draw_empty() then
   	 return true
      elseif _frame == 5 then
	 pop_draw_to_hand()
	 set_hand_cursor_to_end()
      end
   end,

   reset_hand_cursor = function ()
      reset_hand_cursor()
      return true
   end,

   -- discard to draw
   full_discard_to_draw = function ()
      immediate_add_action_queue("randomize_draw")
      for i=1, #get_discard() do
	 immediate_add_action_queue("single_discard_to_draw")
      end
      return true
   end,

   randomize_draw = function ()
      randomize_draw_pile()
      return true
   end,
   
   single_discard_to_draw = function (_frame)
      if _frame == 3 then
	 pop_discard_to_draw()
	 return true
      end
   end,

   -- field control   
   player_turn_main = function ()
      -- todo this logic needs to be somewhere cleaner
      game_state.combat.cursors.utilities = 0
      game_state.combat.field_mode = enum_field_modes.hand
      set_field_select_mode(enum_field_select_modes.hand)

      if btnp(enum_buttons.left) then
	 dec_hand_cursor()
      elseif btnp(enum_buttons.right) then
	 inc_hand_cursor()
      end

      -- play card from hand
      local selected_card = get_selected_card_from_hand()
      if selected_card
   	 and game_state.combat.player.energy - get_card_cost(selected_card) >= 0
   	 and btnp(enum_buttons.z)
      then
   	 game_state.combat.player.energy -= get_card_cost(selected_card)
	 add_to_action_queue("invoke_card", selected_card)
   	 return true
      end
      
      -- if btnp(enum_buttons.up) then
      -- 	 add_to_action_queue("view_enemies")
      -- 	 return true
      -- end

      -- if btnp(enum_buttons.down) then
      -- 	 add_to_action_queue("view_devices")
      -- 	 return true
      -- end

      if btnp(enum_buttons.x) then
      	 add_to_action_queue("player_turn_end")
      	 return true
      end
   end,   
   
   select_from_enemies = function ()
      set_field_select_mode(enum_field_select_modes.enemies)
      
      if btnp(enum_buttons.left) then
	 game_state.combat.cursors.enemies -= 1
      elseif btnp(enum_buttons.right) then
	 game_state.combat.cursors.enemies += 1
      end
      
      game_state.combat.cursors.enemies = rotate(game_state.combat.cursors.enemies,
      					   1,
      					   #game_state.combat.enemies)

      if btnp(enum_buttons.z) then
	 set_field_select_mode(enum_field_select_modes.none)
	 return true
      end
   end,

   view_enemies = function (_frame, _args)
      set_field_select_mode(enum_field_select_modes.enemies)
      if btnp(enum_buttons.left) then
	 game_state.combat.cursors.enemies -= 1
      elseif btnp(enum_buttons.right) then
	 game_state.combat.cursors.enemies += 1
      end
      
      game_state.combat.cursors.enemies = rotate(game_state.combat.cursors.enemies,
					   1,
					   #game_state.combat.enemies)
      if btnp(enum_buttons.down) then
	 add_to_action_queue("player_turn_main")
	 return true
      end
   end,

   -- 5.2.1.3 use card
   invoke_card = function (_frame, _args)
      _args:invoke_action()
      add_to_action_queue("discard_card", _args)
      add_to_action_queue("player_turn_main")
      return true
   end,
   
   discard_card = function (_frame, _args)      
      if _frame == 15 then
	 del(game_state.combat.piles.hand, _args)
	 add(game_state.combat.piles.discard, _args)
	 reset_hand_cursor()
	 return true
      end
   end,

   add_to_discard_pile = function (_frame, _args)
      add(game_state.combat.piles.discard, _args)
      return true
   end,

   -- 5.2.1.4 player combat
   attack_enemy = function (_frame, _args)
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
      if _frame == 35 then
	 del(game_state.combat.enemies, _args)
	 reset_enemies_cursor()
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
      game_state.combat.player.block += 5
      return true
   end,

   -- 5.2.1.5 enemies actions
   enemies_turn_start = function (_frame, _args)
      game_state.combat.turn = enum_turns.enemies
      game_state.combat.field_mode = enum_field_modes.enemies
      if _frame == 45 then
	 add_to_action_queue("enemies_actions")
	 return true
      end
   end,

   enemies_actions = function (_frame, _args)
      for i=1, #game_state.combat.enemies do
	 add_to_action_queue("enemy_action", i)
      end
      add_to_action_queue("enemies_turn_end")
      return true
   end,

   enemy_action = function (_frame, _args)
      if _frame == 0 then
	 game_state.combat.cursors.enemies = _args
      end
      if _frame == 15 then
	 add_intent_to_action_queue(
	    game_state.combat.enemies[game_state.combat.cursors.enemies]:get_intent()
	 )
      end
      if _frame == 30 then
	 return true
      end
   end,

   enemies_turn_end = function (_frame, _args)
      set_field_select_mode(enum_field_select_modes.none)
      for enemy in all(game_state.combat.enemies) do
	 enemy.intent = nil
	 enemy.turn += 1
      end
      add_to_action_queue("player_turn_start")
      return true
   end,

   attack_player = function (_frame, _args)
      game_state.player.health.cur -= _args
      return true
   end,

   enemy_block = function (_frame, _args)
      --game_state.combat.enemies[.health.cur -= _args
      return true
   end,

   enemy_apply = function (_frame, _args)
      return true
   end,
   
   -- general
   delay = function (_frame, _args)
      if _frame == _args then
	 return true
      end
   end
}

-- 5.3 action constructor
function new_action(_action_name, _args)
   assert(action_callbacks[_action_name] != nil, _action_name)

   return {
      name = _action_name,
      callback = action_callbacks[_action_name],
      args = _args,
      frame = 0
   }
end

-- 5. the action_queue singleton
-- The action_queue is an array of action objects to be executed in
-- the order they were inserted (fifo)
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

function add_intent_to_action_queue(_intent, _args)
   add(action_queue, _intent.action)
   log_action_queue("add intent", _intent.name)
end

function is_action_queue_currently(_name)
   return action_queue[1].name == _name
end

function log_action_queue(_change, _action_name)
   add(action_queue_log, _change .. ": " .. _action_name)
   for action in all(action_queue) do
      add(action_queue_log, " " .. action.name)
   end
end

-- 6. the enemy object
-- a list of enemy prototypes that take the form:
-- {
--   name :: string,
--   health :: { max :: number, cur :: number },
--   block :: number,
--   mods :: { modifiers },
--   get_intent :: _this_enemy -> string,
--   get_action :: _this_enemy -> _action
-- }

intent_action_builders = {
   d = function(_damage)
      return function (_this)
	 add_to_action_queue("attack_player", _damage)
      end
   end,
   b = function (_block)
      return function (_this)
	 add_to_action_queue("enemy_block", _block)
      end
   end,
   s = function (_apply)
      return function (_this)
	 add_to_action_queue("enemy_apply", {s  = _apply})
      end
   end
}

function get_enemy_intent_str(_enemy)
   assert(_enemy:get_intent().text)
   return text_to_str(_enemy:get_intent().text)
end

-- intents may take multiple forms dependending on their complexity,
-- if an intent only is text it suggests it can be contextucted as a basic intent
function new_intent(_name, _text, _action)
      return {
      name = _name,
      text = _text,
      action = _action
   }
end

function new_damage_intent(_name, _damage)
   return new_intent(_name, "d" .. _damage, new_action("attack_player", _damage))
end

function new_block_intent(_name, _block)
   return new_intent(_name, "b" .. _block, new_action("enemies_block", {block = _block}))
end

function new_damage_and_block_intent(_name, _damage, _block)
   return new_intent(_name, "d" .. _damage .. " b" .. _block, new_action("attack_player", _damage))
end

function new_apply_mods_intent(_name, _target, _mods)
   --return new_intent(_name, "???", new_action("apply mods", _target, _mods))
end

enemy_prototypes = {
   jaw_worm = {
      name = "jaw worm",
      health = 40,      
      get_intent = function (_this)
	 assert(_this.name)
	 if not _this.intent then
	    if _this.turn == 0 then
	       _this.intent = new_damage_intent("chomp",11)
	    else
	       local choice = rnd(1)
	       local choice_str
	       if choice <= .45 then
		  _this.intent = new_damage_intent("bellow", 11)
	       elseif choice <= .75 then
		  _this.intent = new_block_intent("thrash", 11)
	       else
		  _this.intent = new_damage_intent("chomp", 11)
	       end
	    end
	 end
	 return _this.intent
      end
	 
   }
}

--  6.1 enemy constructors
function new_enemy(_enemy_prototype)
   return {
      name = _enemy_prototype.name,
      health = _enemy_prototype.health,
      block = _enemy_prototype.block or 0,
      mods = _enemy_prototype.mods or {},
      previous_intents = {},
      turn = 0,
      get_intent = _enemy_prototype.get_intent,
      invoke_action = _enemy_prototype.invoke_action
   }
end

-- expects a list of strings of enemy names, returns a list of enemies
function enemy_names_to_enemies(_enemy_names)
   local ret = {}
   for enemy_name in all(_enemy_names) do
      add(ret, new_enemy(enemy_prototypes[enemy_name]))
   end
   return ret
end

-- acts
combat_setups = {
   {
      "jaw_worm"
   }
}

enum_node_types = {
   combat = 1,
   event = 2,
   rest = 3,
   shop = 4,
   boss = 5
}
  
function new_act(_act_num)
   return {
      enum_nodes_types.combat,
      next = {}
   }
end

-- 7 display
enum_display_types = {
   text_box = 1,
   scroll_box = 2,
   cascade = 3,
   display_pile = 4,
   focus_sides = 5
}

enum_just = {
   left = 1,
   center = 2,
   right = 3
}

just_function_map = {}
just_function_map[enum_just.left] = print 
just_function_map[enum_just.center] = print_centered
just_function_map[enum_just.right] = print_right_just

function text_to_str(_text)
   assert(_text, type(_text)) --debug
   return is_function(_text)
      and _text()
      or _text
end

function display_text_box(_text_box)
   assert(is_in_enum(_text_box.just, enum_just) or _text_box.just == nil, _text_box.just)
   if _text_box.just == nil then
      print(text_to_str(_text_box.text),
	    _text_box.x,
	    _text_box.y,
	    _text_box.c)
   else
      just_function_map[_text_box.just](text_to_str(_text_box.text),
					_text_box.x,
					_text_box.y,
					_text_box.c)
   end
end

function new_text_box(_text, _x, _y, _c, _o_just)
   assert(text_to_str(_text) and _x and _y and _c) --debug
   return {
      display_type = enum_display_types.text_box,
      text = _text,
      x = _x,
      y = _y,
      c = _c,
      just = _o_just or enum_just.left
   }
end

function new_cascade(_header, _x, _y, _c, _get_override_c, _members)
   -- returns a list of text boxes
   --debug start
   assert(is_str(_header))
   assert(is_num(_x))
   assert(is_num(_y))
   assert(is_num(_c))
   assert(is_function(_get_override_c))
   assert(is_object(_members))
   --debug end
   
   local ret = {}
   ret.display_type = enum_display_types.cascade
   ret.elements = {}
   add(ret.elements, new_text_box(_header, _x, _y, _c))
   for i=1, #_members do
      local member = _members[i]
      add(ret.elements, new_text_box(member.text, _x+4, _y+6*i, member.c))
   end
   return ret
end

function new_focus_sides(_get_list,
			 _get_focus_index,
			 _x,
			 _y,
			 _display_focus,
			 _display_side)
   assert(_get_list)
   assert(_get_focus_index)
   assert(_x)
   assert(_y)
   assert(_display_focus)
   assert(_display_side)
   return {
      display_type = enum_display_types.focus_sides,
      get_list = _get_list,
      get_focus_index = _get_focus_index,
      x = _x,
      y = _y,
      display_focus = _display_focus,
      display_side = _display_side
   }
end

function new_cascade_member(_c, _text)
   assert(is_num(_c)) --debug
   assert(text_to_str(_text)) --debug
   return  {
      c = _c,
      text = _text
   }
end

function new_display_pile(_str, _get_pile, _x, _y, _c)
   return {
      display_type = enum_display_types.display_pile,
      text = _str,
      get_pile = _get_pile,
      x = _x,
      y = _y,
      c = _c
   }
end

function display_card_focus(_card,_x,_y)
   -- energy
   print_centered(get_card_cost(_card) .. "* ", _x - 20, _y, enum_colors.yellow)

   -- name
   print_centered(_card.name,
	 _x,
	 _y,
	 get_card_color(_card))

   -- description
   print_centered(_card.get_description(),
		  _x,
		  _y+8,
   		  get_card_color(_card))

   -- image
   if card_images then
      rectfill(_x-16, _y+8, _x+16, _y+32, enum_colors.purple)
       --rect(_x-16, _y+8, _x+16, _y+32, get_card_color(_card))
      print_centered("img", _x, _y+18, enum_colors.black)
   end
end

function display_card_side(_card, _x, _y, _side)
   local f = _side == "right" and print_right_just or print
   f(shorten_str(_card.name, 7),
     _x,
     _y,
     enum_colors.white)
end

function display_focus_enemy(_enemy, _x, _y)
   _x = _x - 20
   local c = 
      (game_state.combat.turn == enum_turns.enemies and action_queue[1].name == "enemy_action") and enum_colors.red
      or
      (is_field_select_mode(enum_field_select_modes.enemies) and
	  get_selected_enemy() == _enemy) and display_game_state_colors.player_color
      or display_game_state_colors.enemy_color

   local enemy_dead_col = is_action_queue_currently("kill_enemy") and enum_colors.dark_blue or nil
   print(_enemy.name, _x, _y, enemy_dead_col or c)
   print("intent:" .. get_enemy_intent_str(_enemy), _x+4, _y+6, enemy_dead_col or display_game_state_colors.intent_color)
   print("health:" .. _enemy.health, _x+4, _y+12, enemy_dead_col or display_game_state_colors.health_color)
   print("block:" .. _enemy.block, _x+4, _y+18, enemy_dead_col or display_game_state_colors.block_color)
   local mods_str = ""
   for k,v in pairs(_enemy.mods) do
      mods_str = mods_str .. k .. v .. ","
   end
   print("mods:" .. sub(mods_str, 1, #mods_str-1), _x+4, _y+24, enemy_dead_col or display_game_state_colors.mods_color)
end

function display_side_enemy(_enemy, _x, _y, _side)
   local f = _side == "right" and print_right_just or print
   f(shorten_str(_enemy.name, 7),
     _x,
     _y,
     display_game_state_colors.enemy_color)
end

-- 7.1 display variables
display_game_state_colors = {
   player_color = enum_colors.pink,
   enemy_color = enum_colors.dark_purple,
   card_color = enum_colors.white,
   health_color = enum_colors.red,
   block_color = enum_colors.grey,
   intent_color = enum_colors.orange,
   energy_color = enum_colors.yellow,
   mods_color = enum_colors.dark_grey,
   relics_color = enum_colors.dark_green,
   potions_color = enum_colors.purple
}

display_function_map = {}

display_function_map[enum_display_types.text_box] = function (_text_box)
   assert(is_in_enum(_text_box.just, enum_just)
	     or _text_box.just == nil, _text_box.just)
   
   if _text_box.just == nil then
      print(text_to_str(_text_box.text),
	    _text_box.x,
	    _text_box.y,
	    _text_box.c)
   else
      just_function_map[_text_box.just](text_to_str(_text_box.text),
					_text_box.x,
					_text_box.y,
					_text_box.c)
   end
end

display_function_map[enum_display_types.scroll_box] = function ()
end

display_function_map[enum_display_types.cascade] = function (_cascade)
   draw_display_elements(_cascade.elements)
end

display_function_map[enum_display_types.display_pile] = function (_pile)
   print_selected(text_to_str(_pile.text), _pile.x, _pile.y, _pile.c)
   print(#_pile.get_pile(), _pile.x+6, _pile.y+6, _pile.c)
end

display_function_map[enum_display_types.focus_sides] = function (_focus_sides)
   local _list, _focus_index, _x, _y, _display_focus, _display_side =
      _focus_sides.get_list(), _focus_sides.get_focus_index(), _focus_sides.x, _focus_sides.y,
   _focus_sides.display_focus, _focus_sides.display_side

   
   if _list[_focus_index] then
      _display_focus(_list[_focus_index], _x+63, _y)
   end

   -- left side
   for i=1, _focus_index-1 do
      _display_side(_list[i], _x, _y-i*6+(_focus_index)*6)
   end
   
   -- right side
   for i=_focus_index+1, #_list do
      _display_side(_list[i], _x+129, _y+(i-_focus_index)*6, "right")
   end   
end

display = {
   combat = {
      show = true,
      scroll_boxes = {
	 -- relics = {
	 --    just = enum_just.left,
	 --    c = display_game_state_colors.relics_color,	    
	 --    x = 75,
	 --    y = 103
	 -- }
      },
      text_boxes = {
	 new_text_box(function()
	       return "pots:"
		      end, 75, 123, display_game_state_colors.potions_color)
      },
      cascades = {
	 new_cascade("player", 0, 99,
		     display_game_state_colors.player_color,
		     function ()
		     end,
		     {
			new_cascade_member(display_game_state_colors.energy_color,
					   function ()
					      return "energy:" ..
						 game_state.combat.player.energy ..
						 "*"
			end),
			new_cascade_member(display_game_state_colors.health_color,
					   function ()
					      return "health:" ..
						 game_state.player.health.cur ..
						 "/" ..
						 game_state.player.health.max
			end),
			new_cascade_member(
			   display_game_state_colors.block_color,
			   function ()
			      return "block:"
				 .. game_state.combat.player.block
			end),
			new_cascade_member(display_game_state_colors.mods_color,
					   function ()
					      -- local ret = ""
					      -- for k,v in pairs(game_state.combat.player.mods) do
					      --    ret = ret .. k .. ","
					      -- end
					      -- sub(ret,1,#ret-1)
					      return "mods:"
			end)
		     }
	 )
      },
      piles = {
	 new_display_pile("draw",
			  get_draw,
			  0,
			  84,
			  enum_colors.orange),
	 new_display_pile("disc",
			  get_discard,
			  113,
			  84,
			  enum_colors.dark_orange)
      },

      focus_sides = {
	 new_focus_sides(
	    function ()
	       return game_state.combat.piles.hand
	    end,
	    function ()
	       return game_state.combat.cursors.hand
	    end,
	    0,
	    35,
	    display_card_focus,
	    display_card_side),
	 
	 new_focus_sides(
	    function ()
	       return game_state.combat.enemies
	    end,
	    function () return
		  game_state.combat.cursors.enemies
	    end,
	    0,
	    0,
	    display_focus_enemy,
	    display_side_enemy),
      }
   }
}

-- 7.2 display helpers
function get_card_color(_card)
   return (is_selected_card_from_hand(_card) and is_action_queue_currently("discard_card")) and enum_colors.dark_blue or
      (is_field_select_mode(enum_field_select_modes.hand) and is_selected_card_from_hand(_card))
      and display_game_state_colors.player_color
      or display_game_state_colors.card_color
end

function draw_display()
   for k,v in pairs(display) do
      if v.show then
	 draw_display_model(v)
      end
   end
end

function draw_display_model(_display_model)
   for k,v in pairs(_display_model) do
      if is_object(v) then
	 draw_display_elements(v)
      end
   end
end

function draw_display_elements(_elements)
   for elem in all(_elements) do
      local display_f = enum_to_function_map(display_function_map, elem.display_type, enum_display_types)
      display_f(elem)
   end
end

-- 8. pico-8 hooks
function _init()
   game_state.frame = 0
   game_state.combat.enemies = enemy_names_to_enemies({"jaw_worm"})

   game_state.player.deck = card_names_to_pile({"strike",
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
   game_state.frame += 1
end

function _draw()   
   cls()
   draw_display()
end
