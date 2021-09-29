pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- 4 the card object
-- a card takes the form:
-- {
--   name :: string,
--   type :: card_type,
--   get_action :: this_card -> action,
--   get_description :: this_card -> string,
-- }
-- but may include 'private' helper methods to be used by the public methods
-- enum_card_types = {
--    attack = 1,
--    skill = 2,
--    power = 3,
--    status = 4,
--    curse = 5
-- }

card_type_color_map = {
   8,
   7,
   12,
   4,
   5
}

-- 4.1 card type_objects
-- enum_cards = {
--    strike = 1,
--    defend = 2,
--    anger = 3,
--    bash = 4,
--    reaper = 5
-- }

function damage_str(_card) 
   local modded_damage = _card.card_prototype.damage
   -- if player.mods.strength then
   --    modded_damage += player.mods.strength
   -- end   
   if _card.card_prototype.select_enemy and 
      get_selected(enemies) and 
      get_selected(enemies).mods.vulnerable 
      then modded_damage += flr(modded_damage*.5)
   end
   return "deal {9 " .. modded_damage .. icons_map.damage
end

function block_str(_card) 
   return "gain {6 " .. _card.card_prototype.block .. icons_map.block
end

card_type_objects = {
   {
      "strike", -- 1 name
      1, -- 2 type
      1, -- 3 cost      
      function (_this) -- 4 invoke_action	      
	      add_to_action_queue(15, 
                           {damage=_this.card_prototype.damage})
      end,
      function (_this) -- 5 get_description
	      return damage_str(_this)
      end,
      select_enemy = true,
      damage = 6
   },
   {
      "defend",
      2,
      1,
      function (_this)
	      add_to_action_queue(18, _this.card_prototype.block)
      end,
      function (_this)
	      return block_str(_this)
      end,
      block = 5
   },
   {
      "anger",
      1,
      0,
      function (_this)
         add_to_action_queue(15, {damage=_this.card_prototype.damage})
         add_to_action_queue(14, new_card(enum_cards.anger))         
      end,
      function (_this)
	      return {damage_str(_this), " adds a copy of this card into your discard pile"}
      end,
      select_enemy = true,
      damage = 6
   },
   {
      "bash",
      1,
      2,
      function (_this)
         add_to_action_queue(15, {damage=_this.card_prototype.damage})
         add_to_action_queue(17, _this.card_prototype.mods)
      end,
      function (_this)
	      return damage_str(_this)
      end,
      select_enemy = true,
      damage = 8,
      mods = {v=2}
   },
   {
      "reaper",
      1,
      2,
      function (_this)         
         for enemy in all(enemies.list) do
            add_to_action_queue(15, {enemy=enemy, damage=_this.card_prototype.damage})
         end
      end,
      function (_this)
         return (damage_str(_this) .. " to all enemies. heal hp equal to unblocked damage.")
      end,      
      damage = 4
   }
}

-- 4.2 card constructor
latest_card_instance_id = 1
function new_card(_card_id)   
   local card_instance =  {
      card_instance_id = latest_card_instance_id,
      card_prototype = card_type_objects[_card_id]
   }
   latest_card_instance_id += 1

   return card_instance
end

-- 4.2 general card methods
function get_card_name(_card)
   return _card.card_prototype[1]
end

function get_card_type(_card)
   return _card.card_prototype[2]
end

function get_card_cost(_card)   
   return _card.card_prototype[3]
end

function invoke_card(_card)
   return _card.card_prototype[4](_card)
end

function get_card_description(_card)
   return _card.card_prototype[5](_card)
end

function get_card_select_enemy(_card) 
   return _card.card_prototype.select_enemy
end 

-- expects a list of strings of card names, returns a list of cards
function card_ids_to_pile(_card_ids)
   local ret = {}
   for card_id in all(_card_ids) do
      add(ret, new_card(card_id))
   end
   return ret
end
