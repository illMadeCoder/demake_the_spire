pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
mod_type_objects = {
    {
        "vulnerable",
        "v",
        "vulnerable creatures take 50% more damage from attacks."
    },
    {
        "strength",
        "s",
        "each point of strengths gives +1" .. icons_map.damage .. " per hit." 
    }
}

function print_mod_description(_mod, _x, _y, _c)    
    print_centered(_mod.degree .. " " .. _mod.name, _x, _y, _c)
    local strs = str_wrapped(_mod.description, 14)
    for j,str in ipairs(strs) do
        print_centered(str, _x, 2+_y+j*6, _c)
    end     
 end  

function mods_str(_mods) 
    local s = ''
    for mod in all(_mods) do 
        local is_selected = get_selected(combat_select) == enemy_mods_list_cursor and get_selected(enemy_mods_list_cursor).mod_id == mod.mod_id
        if is_selected then
            s = s .. "{14 " .. mod.degree .. mod.name_short .. "}"
        else
            s = s .. mod.degree .. mod.name_short
        end
    end
    return fill_rest_str(s,"~",10)
end

function new_mod(_mod_id, _degree)
    local mod_type_object = mod_type_objects[_mod_id]
    return {
        mod_id = _mod_id,
        name = mod_type_object[1],
        name_short = mod_type_object[2],
        description = mod_type_object[3],
        degree = _degree or 1
    }
end