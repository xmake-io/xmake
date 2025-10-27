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

    io.write("Building project...\n")
    io.write("Status: Starting...\n")
    io.flush()

    os.sleep(1000)

    -- Go back and update the status line
    tty.cursor_move_up(1)
    tty.cr()
    tty.erase_line()
    io.write("Status: Compiling files...\n")
    io.flush()

    os.sleep(1000)

    tty.cursor_move_up(1)
    tty.cr()
    tty.erase_line()
    io.write("Status: Done! ✓\n")
    io.flush()
end

function example3_multi_line_update()
    print("\n=== Example 3: Multi-line Updates ===\n")

    if not tty.has_vtansi() then
        print("ANSI not supported")
        return
    end

    -- Create a simple status board
    io.write("Task 1: Waiting...\n")
    io.write("Task 2: Waiting...\n")
    io.write("Task 3: Waiting...\n")
    io.flush()

    tty.cursor_hide()

    -- Update Task 1 to Running
    tty.cursor_move_up(3)
    tty.cr()
    tty.erase_line()
    io.write("Task 1: Running... \n")
    io.flush()
    os.sleep(500)

    -- Update Task 1 to Done
    tty.cursor_move_up(1)
    tty.cr()
    tty.erase_line()
    io.write("Task 1: Done ✓\n")
    io.flush()

    -- Update Task 2 to Running
    tty.cr()
    tty.erase_line()
    io.write("Task 2: Running... \n")
    io.flush()
    os.sleep(500)

    -- Update Task 2 to Done
    tty.cursor_move_up(1)
    tty.cr()
    tty.erase_line()
    io.write("Task 2: Done ✓\n")
    io.flush()

    -- Update Task 3 to Running
    tty.cr()
    tty.erase_line()
    io.write("Task 3: Running... \n")
    io.flush()
    os.sleep(500)

    -- Update Task 3 to Done
    tty.cursor_move_up(1)
    tty.cr()
    tty.erase_line()
    io.write("Task 3: Done ✓\n")
    io.flush()

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

