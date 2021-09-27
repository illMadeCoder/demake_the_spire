pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

function init_game(_card_ids)
    player = {
        health = {
           max = 80,
           cur = 80
        },
        energy_init = 3,
        energy = 3,
        block = 0,
        mods = {strength=1}
     }
    
    -- list and cursors
    relics = new_list_cursor()
    potions = new_list_cursor()
    deck = new_list_cursor(card_ids_to_pile({1,1,1,1,1}))
end