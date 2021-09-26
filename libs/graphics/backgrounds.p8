pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

backgrounds = {
function (_i, _j)
end -- done
,
function (_i, _j)
   spr(0, _i*8, _j*8, 1, 1, (frame % 40 <= 20))
end --done
}

-- function_map_backgrounds[enum_backgrounds.enemy_waves] = function (_i, _j)
--    local c = _i % 3 == 0 and 2 or 4
--    circ(_i*16, _j*16, lerp_rotate(frame/60, 50, 100), c) -- todo capture last half of this
-- end --todo

-- function_map_backgrounds[enum_backgrounds.matrix] = function (_i, _j)
--    rect(_i*8, _j*8, _i*8+6, _j*8+6,
-- 	flr((frame % 128)/10) % (_i + _j) == 0 and
-- 	   12 or 2)
-- end -- todo

-- function_map_backgrounds[enum_backgrounds.new] = function (_i, _j)
-- end -- todo

-- function_map_backgrounds[enum_backgrounds.evil_eyes] = function (_i, _j)
--    print(icons_map.evil_eye,
-- 	 _i*8,
-- 	 _j*8,
-- 	 _i+_j == (flr(frame/10)%30) and 8 or 0)
-- end -- todo