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

--[[
   an intent is an object that define an enemies action in combat
   each property existing in the _intent_obj argument object defines the behavior of the intent
   An _intent_obj may or may not have the following properties:
   _intent_obj = {
      block,
      damage,
      v,
      ... all other mods 
   }
--]]

enum_enemies = {
   jaw_worm = 1
}

enemy_typeobjects = {
   {
      name = "jaw worm",
      health = 40,
      block = 11,
      get_intent = function (_this)
            if not _this.intent then
               local choice = rnd()
               if _this.turn == 1 or choice < .25 then
                  _this.intent = {damage=11} -- thrash
               elseif (_this.turn == 2 or choice < .7) and _this.turn != 3 then 
                  _this.intent = {strength=3, block=6} --bellow
               else
                   _this.intent = {damage=7, block=5} -- thrash
               end
            end
            return _this.intent
         end
   }
}

--  6.1 enemy constructors
function new_enemy(_enemy_id, _index)
   assert(enemy_typeobjects[_enemy_id], _enemy_id) --debug
   local _enemy_typeobject = enemy_typeobjects[_enemy_id]
   return {
      name = _enemy_typeobject.name,
      max_health = _enemy_typeobject.health,
      health = _enemy_typeobject.health,
      block = _enemy_typeobject.block or 0,
      turn = 1,
      get_intent = _enemy_typeobject.get_intent,
      mods = {v=0,
              strength=0},
      index=_index
   }
end

-- expects a list of strings of enemy names, returns a list of enemies
function enemy_ids_to_enemies(_enemy_ids)
   local ret = {}
   for i,enemy_id in ipairs(_enemy_ids) do
      add(ret, new_enemy(enemy_id, i))
   end
   return ret
end