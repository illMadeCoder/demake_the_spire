pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

new_test("combat starts then draw cards then player turn then player turn end then enemy turn then player turn again", 
    function (_self, _action)   
        if _action.action_id == 10 then 
            test_btns[5] = true
        end
        if _action.action_id == 19 then
            complete_test()
        end 
    end, 
    function (_self)            
        new_combat()
        add_to_action_queue(1)
        enemies.list = enemy_ids_to_enemies({1})
        deck.list = card_ids_to_pile({1,1,1,1,1})
    end
)