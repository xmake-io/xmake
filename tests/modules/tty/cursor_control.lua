import("core.base.tty")
import("core.base.scheduler")

-- Demo TTY cursor position control features
-- Implement partial screen refresh

function _progress_bar_inline(label, progress)
    local bar_width = 40
    local filled = math.floor(progress * bar_width)
    local bar = string.rep("█", filled) .. string.rep("░", bar_width - filled)
    
    -- Clear the line and output content
    tty.cr()
    tty.erase_line()
    io.write(string.format("%s: [%s] %3d%%", label, bar, math.floor(progress * 100)))
    io.flush()
end

function main()
    -- Check if ANSI control codes are supported
    if not tty.has_vtansi() then
        print("Terminal does not support ANSI control codes")
        return
    end

    print("=== TTY Cursor Control Demo ===")
    print("This demo shows partial screen refresh using cursor positioning")
    print("\n")
    
    -- Hide cursor for smoother display
    tty.cursor_hide()
    
    print("Demo 1: Multiple Progress Bars (Parallel Updates)")
    print("------------------------------------------------")
    
    -- Reserve lines for progress bars
    print("Task 1: Downloading")
    print("Task 2: Compiling  ")
    print("Task 3: Linking    ")
    
    -- Simulate three parallel task progress bars
    for step = 1, 100 do
        -- Task 1 progress
        local progress1 = step / 100
        tty.cursor_save()
        tty.cursor_move_up(3)
        _progress_bar_inline("Task 1: Downloading", progress1)
        tty.cursor_restore()
        
        -- Task 2 progress (starts later, progresses faster)
        local progress2 = math.max(0, math.min(1.0, (step - 10) / 80))
        tty.cursor_save()
        tty.cursor_move_up(2)
        _progress_bar_inline("Task 2: Compiling  ", progress2)
        tty.cursor_restore()
        
        -- Task 3 progress (starts even later)
        local progress3 = math.max(0, math.min(1.0, (step - 30) / 60))
        tty.cursor_save()
        tty.cursor_move_up(1)
        _progress_bar_inline("Task 3: Linking    ", progress3)
        tty.cursor_restore()
        
        os.sleep(30)  -- 30ms delay
    end
    
    print("\n\nDemo 2: Dynamic Status Updates")
    print("--------------------------------")
    
    -- Print initial status and counter
    print("Status: Waiting...")
    print("Counter: 0")
    
    local statuses = {
        "Initializing...",
        "Loading configuration...",
        "Parsing files...",
        "Building dependencies...",
        "Compiling sources...",
        "Linking executable...",
        "Done!"
    }
    
    for i, status in ipairs(statuses) do
        -- Update status line
        tty.cursor_save()
        tty.cursor_move_up(2)
        tty.cr()
        tty.erase_line()
        io.write(string.format("Status: %s", status))
        io.flush()
        tty.cursor_restore()
        
        -- Update counter line
        tty.cursor_save()
        tty.cursor_move_up(1)
        tty.cr()
        tty.erase_line()
        io.write(string.format("Counter: %d", i * 100))
        io.flush()
        tty.cursor_restore()
        
        os.sleep(500)
    end
    
    -- Restore cursor visibility
    tty.cursor_show()
    
    print("\n\nDemo 3: Erase and Update Specific Line")
    print("----------------------------------------")
    
    print("Line 1: This line will stay")
    print("Line 2: This line will be updated...")
    print("Line 3: This line will stay too")
    
    os.sleep(1000)
    
    -- Update only the middle line
    tty.cursor_save()
    tty.cursor_move_up(2)
    tty.cr()
    tty.erase_line()
    io.write("Line 2: Updated content! ✓")
    io.flush()
    tty.cursor_restore()
    print("\n\nAll demos completed!")
    print("\nKey features demonstrated:")
    print("  - cursor_move_up/down/left/right: Move cursor relatively")
    print("  - cursor_save/restore: Save and restore cursor position")
    print("  - erase_line(): Clear current line")
    print("  - cursor_hide()/cursor_show(): Control cursor visibility")
    print("  - Partial screen refresh without clearing entire screen")
end

