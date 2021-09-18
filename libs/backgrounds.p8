pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

enum_backgrounds = {
   weaving = 1,
   enemy_waves = 2,
   black = 3,
   new = 4,
   matrix = 5,
   evil_eyes = 6
}

function_map_backgrounds = {}

function_map_backgrounds[enum_backgrounds.black] = function (_i, _j)
end -- done

function_map_backgrounds[enum_backgrounds.weaving] = function (_i, _j)
   spr(0, _i*8, _j*8, 1, 1, (frame % 40 <= 20))
end --done

function_map_backgrounds[enum_backgrounds.enemy_waves] = function (_i, _j)
   local c = _i % 3 == 0 and enum_colors.dark_purple or enum_colors.dark_orange
   circ(_i*16, _j*16, lerp_rotate(frame/60, 50, 100), c) -- todo capture last half of this
end --todo

function_map_backgrounds[enum_backgrounds.matrix] = function (_i, _j)
   rect(_i*8, _j*8, _i*8+6, _j*8+6,
	flr((frame % 128)/10) % (_i + _j) == 0 and
	   enum_colors.blue or enum_colors.dark_purple)
end -- todo

function_map_backgrounds[enum_backgrounds.new] = function (_i, _j)
end -- todo

function_map_backgrounds[enum_backgrounds.evil_eyes] = function (_i, _j)
   print(icons_map.evil_eye,
	 _i*8,
	 _j*8,
	 _i+_j == (flr(frame/10)%30) and enum_colors.red or enum_colors.black)
end -- todo