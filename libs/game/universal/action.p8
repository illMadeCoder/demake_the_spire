pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

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

function new_action(_action_id, _args)
   -- assert(is_num(_action_id)) --debug
   -- assert(function_map_actions[_action_id] != nil) --debug

   return {
      action_id = _action_id,
      action_callback = combat_action_callbacks[_action_id],
      args = _args,
      frame = 0
   }
end