import("core.base.tty")

function test_cursor_move()
    if not tty.has_vtansi() then
        print("Terminal does not support ANSI control codes, skipping test")
        return
    end
    
    print("\n=== Test: cursor_move ===")
    io.write("Line 1\n")
    io.write("Line 2\n")
    io.write("Line 3\n")
    io.write("Line 4\n")
    io.write("Line 5\n")
    io.flush()
    
    os.sleep(1000)
    
    -- Move to line 3 and update content
    tty.cursor_move_up(3)
    tty.cr()
    tty.erase_line()
    io.write("Line 3 - UPDATED!\n")
    io.flush()
    
    -- Move cursor back to end
    tty.cursor_move_down(2)
    
    print("\n✓ cursor_move_up test passed")
end

function test_cursor_move_directions()
    if not tty.has_vtansi() then
        return
    end
    
    print("\n=== Test: cursor movement directions ===")
    
    -- Create a small coordinate system
    for i = 1, 5 do
        io.write(string.rep(" ", 60) .. "\n")
    end
    io.flush()
    
    -- Move to starting position
    tty.cursor_move_up(5)
    tty.cursor_move_right(10)
    io.write("START")
    io.flush()
    os.sleep(500)
    
    -- Move right
    tty.cursor_move_right(10)
    io.write("RIGHT")
    io.flush()
    os.sleep(500)
    
    -- Move down
    tty.cursor_move_down(2)
    io.write("DOWN")
    io.flush()
    os.sleep(500)
    
    -- Move left
    tty.cursor_move_left(5)
    io.write("LEFT")
    io.flush()
    os.sleep(500)
    
    -- Move up
    tty.cursor_move_up(1)
    io.write("UP")
    io.flush()
    
    -- Move to end
    tty.cursor_move_down(3)
    io.write("\n")
    io.flush()
    
    print("✓ cursor movement directions test passed")
end

function test_cursor_hide_show()
    if not tty.has_vtansi() then
        return
    end
    
    print("\n=== Test: cursor hide/show ===")
    
    print("Cursor is visible now...")
    os.sleep(1000)
    
    tty.cursor_hide()
    print("Cursor is hidden now (you shouldn't see it blinking)...")
    os.sleep(2000)
    
    tty.cursor_show()
    print("Cursor is visible again!")
    
    print("✓ cursor hide/show test passed")
end

function test_erase_operations()
    if not tty.has_vtansi() then
        return
    end
    
    print("\n=== Test: erase operations ===")
    
    -- Test erase_line_to_end
    io.write("This is a long line that will be partially erased")
    io.flush()
    os.sleep(1000)
    tty.cursor_move_left(30)
    tty.erase_line_to_end()
    io.write("<- erased to end\n")
    io.flush()
    
    os.sleep(1000)
    
    -- Test full line erase
    io.write("This entire line will be erased")
    io.flush()
    os.sleep(1000)
    tty.cr()
    tty.erase_line()
    io.write("Replaced!\n")
    io.flush()
    
    print("✓ erase operations test passed")
end

function test_partial_screen_update()
    if not tty.has_vtansi() then
        return
    end
    
    print("\n=== Test: partial screen update ===")
    
    -- Create a table
    io.write("┌────────────────────────────────┐\n")
    io.write("│ Task         │ Status          │\n")
    io.write("├────────────────────────────────┤\n")
    io.write("│ Compile      │ Pending...      │\n")
    io.write("│ Link         │ Pending...      │\n")
    io.write("│ Package      │ Pending...      │\n")
    io.write("└────────────────────────────────┘\n")
    io.flush()
    
    os.sleep(1000)
    tty.cursor_hide()
    
    -- Update first task status
    tty.cursor_move_up(4)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Running...      │\n")
    io.flush()
    os.sleep(800)
    
    tty.cursor_move_up(1)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Done! ✓         │\n")
    io.flush()
    os.sleep(500)
    
    -- Update second task status
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Running...      │\n")
    io.flush()
    os.sleep(800)
    
    tty.cursor_move_up(1)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Done! ✓         │\n")
    io.flush()
    os.sleep(500)
    
    -- Update third task status
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Running...      │\n")
    io.flush()
    os.sleep(800)
    
    tty.cursor_move_up(1)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Done! ✓         │\n")
    io.flush()
    
    tty.cursor_show()
    tty.cursor_move_down(1)
    
    print("\n✓ partial screen update test passed")
end

function main(...)
    -- Run all tests
    test_cursor_move()
    test_cursor_move_directions()
    test_cursor_hide_show()
    test_erase_operations()
    test_partial_screen_update()
    
    print("\n" .. string.rep("=", 50))
    print("All TTY cursor control tests completed!")
    print(string.rep("=", 50))
end

