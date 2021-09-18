pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
graphic_buffer = {}

function update_graphic_buffer()
   for graphic in all(graphic_buffer) do
      graphic.state.frame += 1
   end
end

function draw_graphic(graphic)
   return graphic.show and graphic.callback(graphic.state)     
end

function draw_graphic_buffer()
   for graphic in all(graphic_buffer) do
      if draw_graphic(graphic) then
	 del(graphic_buffer, graphic)
      end
   end
end

function add_to_graphic_buffer(_graphic_id, _args)
   local graphic = new_graphic(_graphic_id, _args)
   add(graphic_buffer, graphic)
   return graphic
end

function add_graphic_to_graphic_buffer(_graphic_id, _args)
   add(graphic_buffer, new_graphic(_graphic_id, _args))
end
