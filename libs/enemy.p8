pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- 6. the enemy object
-- a list of enemy typeobjects that take the form:
-- {
--   name :: string,
--   health :: { max :: number, cur :: number },
--   block :: number,
--   mods :: { modifiers },
--   get_intent :: _this_enemy -> string,
--   get_action :: _this_enemy -> _action
-- }

function get_enemy_intent_str(_enemy)
   assert(_enemy:get_intent().text) --debug
   return get(_enemy:get_intent().text)
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
   return new_intent(_name, icons_map.damage .. _damage, new_action(enum_actions.attack_player, _damage))
end

function new_block_intent(_name, _block)
   --return new_intent(_name, "b" .. _block, new_action(enum_actions.enemies_block, {block = _block}))
end

function new_damage_and_block_intent(_name, _damage, _block)
   return new_intent(_name, "d" .. _damage .. " b" .. _block, new_action(enum_actions.attack_player, _damage))
end

function new_apply_mods_intent(_name, _target, _mods)
   --return new_intent(_name, "???", new_action(enum_actions.apply mods, _target, _mods))
end

enum_enemies = {
   jaw_worm = 1
}

enemy_typeobjects = {
   {
      name = "jaw worm",
      health = 40,
      block = 11,
      get_intent = function (_this)
	 assert(_this.name) --debug
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
function new_enemy(_enemy_id)
   assert(enemy_typeobjects[_enemy_id], _enemy_id) --debug
   local _enemy_typeobject = enemy_typeobjects[_enemy_id]
   return {
      name = _enemy_typeobject.name,
      max_health = _enemy_typeobject.health,
      health = _enemy_typeobject.health,
      block = _enemy_typeobject.block or 0,
      mods = _enemy_typeobject.mods or {},
      previous_intents = {},
      turn = 0,
      get_intent = _enemy_typeobject.get_intent,
      invoke_action = _enemy_typeobject.invoke_action,
      mods = {v=0}
   }
end

-- expects a list of strings of enemy names, returns a list of enemies
function enemy_ids_to_enemies(_enemy_ids)
   local ret = {}
   for enemy_id in all(_enemy_ids) do
      add(ret, new_enemy(enemy_id))
   end
   return ret
end