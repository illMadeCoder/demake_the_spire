pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- 5. the action_queue singleton
-- The action_queue is an array of action objects to be executed in
-- the order they were inserted (fifo)
action_queue = {}
-- action_queue_log = {} --debug

function update_action_queue()
   local action = action_queue[1]
   if action == nil then
      return
   else
      if function_map_actions[action.action_id](action.frame, action.args) then
	      del(action_queue, action)
	    --log_action_queue("del", action.action_id) --debug
      end
      action.frame += 1
   end
end

function interrupt_action_queue(_action_id, _args)
   local new_action_queue = {}

   add(new_action_queue, new_action(_action_id, _args))

   for action in all(action_queue) do
      add(new_action_queue, action)
   end

   action_queue = new_action_queue

   --log_action_queue("int", _action_id) --debug
end

function immediate_add_action_queue(_action_id, _args)
   local new_action_queue = {}
   add(new_action_queue, action_queue[1])
   add(new_action_queue, new_action(_action_id, _args))
   
   for i=2, #action_queue do
      add(new_action_queue, action_queue[i])
   end
   
   action_queue = new_action_queue
   --log_action_queue("imm", _action_id) --debug
end

function add_to_action_queue(_action_id, _args)
   add(action_queue, new_action(_action_id, _args))
   --log_action_queue("add", _action_id)--debug
end

function is_action_queue_currently(_action_id)
   -- assert(is_in_enum(_action_id, enum_actions), _action_id) --debug
   return action_queue[1] and action_queue[1].action_id == _action_id
end

--debug_start
-- function log_action_queue(_change, _action_id)
--    -- add(action_queue_log, _change .. ": " .. enum_key(_action_id, enum_actions))
--    -- for action in all(action_queue) do
--    --    add(action_queue_log, " " .. enum_key(action.action_id, enum_actions))
--    -- end
-- end
--debug_end