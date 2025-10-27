import("core.base.tty")

function test_cursor_move()
    if not tty.has_vtansi() then
        print("Terminal does not support ANSI control codes, skipping test")
        return
    end
    
    print("\n=== Test: cursor_move ===")
    print("Line 1")
    print("Line 2")
    print("Line 3")
    print("Line 4")
    print("Line 5")
    
    os.sleep(1000)
    
    -- Move to line 3 and update content
    tty.cursor_save()
    tty.cursor_move_up(3)
    tty.erase_line()
    io.write("Line 3 - UPDATED!")
    io.flush()
    tty.cursor_restore()
    
    print("\n✓ cursor_move_up test passed")
end

function test_cursor_move_directions()
    if not tty.has_vtansi() then
        return
    end
    
    print("\n=== Test: cursor movement directions ===")
    
    -- Create a small coordinate system
    for i = 1, 5 do
        print(string.rep(" ", 60))
    end
    
    tty.cursor_save()
    
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
    
    tty.cursor_restore()
    
    print("\n✓ cursor movement directions test passed")
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
    
    -- 测试 erase_line_to_end
    io.write("This is a long line that will be partially erased")
    io.flush()
    os.sleep(1000)
    tty.cursor_move_left(30)
    tty.erase_line_to_end()
    io.write("<- erased to end")
    io.flush()
    print("")
    
    os.sleep(1000)
    
    -- 测试整行擦除
    io.write("This entire line will be erased")
    io.flush()
    os.sleep(1000)
    tty.cr()
    tty.erase_line()
    io.write("Replaced!")
    io.flush()
    print("")
    
    print("✓ erase operations test passed")
end

function test_partial_screen_update()
    if not tty.has_vtansi() then
        return
    end
    
    print("\n=== Test: partial screen update ===")
    
    -- 创建一个表格
    print("┌────────────────────────────────┐")
    print("│ Task         │ Status          │")
    print("├────────────────────────────────┤")
    print("│ Compile      │ Pending...      │")
    print("│ Link         │ Pending...      │")
    print("│ Package      │ Pending...      │")
    print("└────────────────────────────────┘")
    
    os.sleep(1000)
    
    -- 更新第一个任务状态
    tty.cursor_save()
    tty.cursor_move_up(4)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Running...      │")
    io.flush()
    tty.cursor_restore()
    os.sleep(800)
    
    tty.cursor_save()
    tty.cursor_move_up(4)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Done! ✓         │")
    io.flush()
    tty.cursor_restore()
    os.sleep(500)
    
    -- 更新第二个任务状态
    tty.cursor_save()
    tty.cursor_move_up(3)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Running...      │")
    io.flush()
    tty.cursor_restore()
    os.sleep(800)
    
    tty.cursor_save()
    tty.cursor_move_up(3)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Done! ✓         │")
    io.flush()
    tty.cursor_restore()
    os.sleep(500)
    
    -- 更新第三个任务状态
    tty.cursor_save()
    tty.cursor_move_up(2)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Running...      │")
    io.flush()
    tty.cursor_restore()
    os.sleep(800)
    
    tty.cursor_save()
    tty.cursor_move_up(2)
    tty.cursor_move_to_col(32)
    tty.erase_line_to_end()
    io.write("│ Done! ✓         │")
    io.flush()
    tty.cursor_restore()
    
    print("\n✓ partial screen update test passed")
end

function main(...)
    -- 运行所有测试
    test_cursor_move()
    test_cursor_move_directions()
    test_cursor_hide_show()
    test_erase_operations()
    test_partial_screen_update()
    
    print("\n" .. string.rep("=", 50))
    print("All TTY cursor control tests completed!")
    print(string.rep("=", 50))
end

