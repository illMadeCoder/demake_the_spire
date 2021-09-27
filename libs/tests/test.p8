pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

tests = {}
test_counter = 0
tests_complete = false

function new_test(_name, _callback, _init)
    add(tests, {
        name=_name,
        callback=_callback,
        init = _init,
        frame = 0,
        complete = false
    })
end

function complete_test()
    tests[test_counter].complete = true
end 

function update_tests()
    if not tests_complete then
        if test_counter == 0 then
            printh("tests started")        
            test_counter += 1
        end 
        if test_counter <= #tests then
            local test_current = tests[test_counter]
            if test_current.frame == 0 then
                printh("performing the following test: " .. test_current.name)
                test_current:init()
                subscribe_to_action_queue(test_current)
            end 
            local test_complete = test_current.complete       
            test_current.frame += 1        
            if test_complete then
                test_current.complete = true
                unsubscribe_to_action_queue(test_current)
                test_counter += 1
                printh("test complete")            
            end
        end    
        if test_counter > #tests then
            printh("tests complete")
            tests_complete = true
        end
    end
end

test_btns = {
    false,
    false,
    false,
    false,
    false
}

function btnp(_x) 
    local ret = test_btns[_x]    
    test_btns[_x] = false
    return ret
end