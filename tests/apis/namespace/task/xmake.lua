task("task0")
    set_menu {options = {}}
    on_run(function ()
        print("task0")
    end)

namespace("ns1", function ()
    task("task1")
        set_menu {options = {}}
        on_run(function ()
            print("NS1_TASK1")
        end)

    namespace("ns2", function()
        task("task2")
            set_menu {options = {}}
            on_run(function ()
                print("NS2_TASK2")
            end)
    end)
end)

