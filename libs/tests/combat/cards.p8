pico-8 cartridge // http://www.pico-8.com
version 18
__lua__


new_test("card: strike", 
    function (_self, _action)   
        if _action.action_id == 10 then 
            test_btns[4] = true
        end
        if _action.action_id == 11 then 
            test_btns[4] = true
        end
        if _action.action_id == 12 then 
            complete_test()
        end        
    end, 
    function (_self)
        new_combat()   
        enemies.list = enemy_ids_to_enemies({1})
        deck.list = card_ids_to_pile({1,1,1,1,1})
        add_to_action_queue(1)
    end
)