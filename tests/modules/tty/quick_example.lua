-- Quick example: Demonstrates the most common use cases

import("core.base.tty")

function example1_simple_progress()
    print("\n=== Example 1: Simple Progress Bar ===\n")
    
    if not tty.has_vtansi() then
        print("ANSI not supported")
        return
    end
    
    print("Downloading file...")
    for i = 0, 100, 5 do
        local width = 40
        local filled = math.floor(i / 100 * width)
        local bar = string.rep("█", filled) .. string.rep("░", width - filled)
        
        -- Move to start of line, clear it, and redraw
        tty.cr()
        tty.erase_line()
        io.write(string.format("[%s] %3d%%", bar, i))
        io.flush()
        
        os.sleep(50)
    end
    print("")  -- New line after progress
end

function example2_update_previous_line()
    print("\n=== Example 2: Update Previous Line ===\n")
    
    if not tty.has_vtansi() then
        print("ANSI not supported")
        return
    end
    
    print("Building project...")
    print("Status: Starting...")
    
    os.sleep(1000)
    
    -- Go back and update the status line
    tty.cursor_move_up(1)
    tty.erase_line()
    io.write("Status: Compiling files...")
    io.flush()
    print("")  -- Move to next line
    
    os.sleep(1000)
    
    tty.cursor_move_up(1)
    tty.erase_line()
    io.write("Status: Done! ✓")
    io.flush()
    print("")
end

function example3_multi_line_update()
    print("\n=== Example 3: Multi-line Updates ===\n")
    
    if not tty.has_vtansi() then
        print("ANSI not supported")
        return
    end
    
    -- Create a simple status board
    print("Task 1: Waiting...")
    print("Task 2: Waiting...")
    print("Task 3: Waiting...")
    
    tty.cursor_hide()
    
    -- Update Task 1
    tty.cursor_save()
    tty.cursor_move_up(3)
    tty.erase_line()
    io.write("Task 1: Running... ")
    io.flush()
    tty.cursor_restore()
    os.sleep(500)
    
    tty.cursor_save()
    tty.cursor_move_up(3)
    tty.erase_line()
    io.write("Task 1: Done ✓")
    io.flush()
    tty.cursor_restore()
    
    -- Update Task 2
    tty.cursor_save()
    tty.cursor_move_up(2)
    tty.erase_line()
    io.write("Task 2: Running... ")
    io.flush()
    tty.cursor_restore()
    os.sleep(500)
    
    tty.cursor_save()
    tty.cursor_move_up(2)
    tty.erase_line()
    io.write("Task 2: Done ✓")
    io.flush()
    tty.cursor_restore()
    
    -- Update Task 3
    tty.cursor_save()
    tty.cursor_move_up(1)
    tty.erase_line()
    io.write("Task 3: Running... ")
    io.flush()
    tty.cursor_restore()
    os.sleep(500)
    
    tty.cursor_save()
    tty.cursor_move_up(1)
    tty.erase_line()
    io.write("Task 3: Done ✓")
    io.flush()
    tty.cursor_restore()
    
    tty.cursor_show()
end

function main()
    print(string.rep("=", 60))
    print("TTY Cursor Control - Quick Examples")
    print(string.rep("=", 60))
    
    example1_simple_progress()
    example2_update_previous_line()
    example3_multi_line_update()
    
    print("\n" .. string.rep("=", 60))
    print("All examples completed!")
    print("Check test.lua, cursor_control.lua, and live_dashboard.lua")
    print("for more advanced examples.")
    print(string.rep("=", 60))
end

