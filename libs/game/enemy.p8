pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

enemy_type_objects = {
   -- 1
   {
      name = "jaw worm",
      health = 40,
      block = 11,
      get_intent = function (_this)
            if not _this.intent then
               local choice = rnd()
               if _this.turn == "player" or choice < .25 then
                  _this.intent = {damage=11} -- thrash
               elseif (_this.turn == "enemies" or choice < .7) and _this.turn != 3 then 
                  _this.intent = {strength=3, block=6} --bellow
               else
                   _this.intent = {damage=7, block=5} -- thrash
               end
            end
            return _this.intent
         end
   }
}

function new_enemy(_enemy_id, _index)
   local _enemy_type_object = enemy_type_objects[_enemy_id]
   return {
      name = _enemy_type_object.name,
      max_health = _enemy_type_object.health,
      health = _enemy_type_object.health,
      block = _enemy_type_object.block or 0,
      turn = 1,
      get_intent = _enemy_type_object.get_intent,
      mods = {v=0,
              strength=0},
      index=_index
   }
end

function enemy_ids_to_enemies(_enemy_ids)
   local ret = {}
   for i,enemy_id in ipairs(_enemy_ids) do
      add(ret, new_enemy(enemy_id, i))
   end
   return ret   
end