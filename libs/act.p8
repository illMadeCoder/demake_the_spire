pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- acts
combat_setups = {
   {
      enum_enemies.jaw_worm
   }
}

enum_act_node_types = {
   combat = 1,
   event = 2,
   rest = 3,
   shop = 4,
   boss = 5
}
  
function new_act(_act_num)
   return {
      enum_act_node_types.combat,
      next = {}
   }
end