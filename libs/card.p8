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
enum_card_types = {
   attack = 1,
   skill = 2,
   power = 3,
   status = 4
}

-- 4.1 card typeobjects
enum_cards = {
   strike = 1,
   defend = 2,
   anger = 3,
   bash = 4,
   clotheseline = 5
}

function dmg_str(_card) 
   return "deal " .. (     _card.base.select_enemy and
                           enemies and 
                           get_selected(enemies) 
                           and 
                           get_selected(enemies).mods.v > 0 
                              and _card.base.dmg + flr(_card.base.dmg*.5) 
                              or _card.base.dmg) .. " damage"
end

card_typeobjects = {
   {
      "strike", -- 1 name
      enum_card_types.attack, -- 2 type
      1, -- 3 cost      
      function (_this) -- 4 invoke_action	      
	      add_to_action_queue(enum_actions.attack_enemy, _this.base.dmg)
      end,
      function (_this) -- 5 get_description
	      return dmg_str(_this)
      end,
      select_enemy = true,
      dmg = 6
   },
   {
      "defend",
      enum_card_types.skill,
      1,
      function (_this)
	      add_to_action_queue(enum_actions.block, _this.base.block)
      end,
      function (_this)
	      return "get " .. _this.base.block .. " block"
      end,
      block = 5
   },
   {
      "anger",
      enum_card_types.attack,
      6,
      0,
      function (_this)
         add_to_action_queue(enum_actions.attack_enemy, _this.base_damage)
      end,
      function (_this)
	 return ""
      end,
      true
   },
   {
      "bash",
      enum_card_types.attack,
      2,
      function (_this)
         add_to_action_queue(enum_actions.attack_enemy, _this.base.dmg)
         add_to_action_queue(enum_actions.apply_selected, _this.base.mods)
      end,
      function (_this)
	      return dmg_str(_this)
      end,
      select_enemy = true,
      dmg = 8,
      mods = {v=2}
   },
   {
      "clothesline",
      enum_card_types.attack,
      12,
      2,
      function (_this)
         add_to_action_queue(enum_actions.attack_enemy, _this.base_damage)
         add_to_action_queue(enum_actions.apply_selected, {w=2})
      end,
      function (_this)
	 return ""
      end,
      true
   }
}

-- 4.2 card constructor
function new_card(_card_id)
   assert(card_typeobjects[_card_id]) --debug
   return {
      base = card_typeobjects[_card_id]
   }
end

-- 4.2 general card methods
function get_card_name(_card)
   return _card.base[1]
end

function get_card_type(_card)
   return _card.base[2]
end

function get_card_cost(_card)   
   return _card.base[3]
end

function invoke_card(_card)
   return _card.base[4](_card)
end

function get_card_description(_card)
   return _card.base[5](_card)
end

function get_card_select_enemy(_card) 
   return _card.base.select_enemy
end 

-- expects a list of strings of card names, returns a list of cards
function card_ids_to_pile(_card_ids)
   local ret = {}
   for card_id in all(_card_ids) do
      add(ret, new_card(card_id))
   end
   return ret
end
