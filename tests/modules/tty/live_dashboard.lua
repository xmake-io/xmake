import("core.base.tty")
import("core.base.scheduler")

-- Demo advanced usage: Live updating dashboard
-- Similar to build tool real-time output

function simulate_build_process()
    if not tty.has_vtansi() then
        print("Terminal does not support ANSI control codes")
        return
    end
    
    print("\nBuild Dashboard - Live Updates")
    print(string.rep("=", 60))
    
    -- Hide cursor
    tty.cursor_hide()
    
    -- Print task list
    print("⏸ Parse project files       [" .. string.rep("░", 30) .. "]   0%")
    print("⏸ Resolve dependencies      [" .. string.rep("░", 30) .. "]   0%")
    print("⏸ Compile sources           [" .. string.rep("░", 30) .. "]   0%")
    print("⏸ Link executable           [" .. string.rep("░", 30) .. "]   0%")
    print("⏸ Create package            [" .. string.rep("░", 30) .. "]   0%")
    print("\nRecent logs:")
    
    local function update_task(row_offset, icon, name, progress)
        tty.cursor_save()
        tty.cursor_move_up(row_offset)
        tty.cr()
        tty.erase_line()
        local bar_width = 30
        local filled = math.floor(progress * bar_width)
        local bar = string.rep("█", filled) .. string.rep("░", bar_width - filled)
        io.write(string.format("%s %-24s [%s] %3d%%", icon, name, bar, math.floor(progress * 100)))
        io.flush()
        tty.cursor_restore()
    end
    
    local function add_log(message)
        io.write(string.format("[%s] %s\n", os.date("%H:%M:%S"), message))
        io.flush()
    end
    
    scheduler.co_start(function()
        -- Task 1: Parse
        add_log("Starting project parsing...")
        for i = 1, 20 do
            update_task(7, "▶", "Parse project files", i / 20)
            os.sleep(50)
        end
        update_task(7, "✓", "Parse project files", 1.0)
        add_log("Project parsed successfully")
        os.sleep(200)
        
        -- Task 2: Dependencies
        add_log("Resolving dependencies...")
        for i = 1, 15 do
            update_task(6, "▶", "Resolve dependencies", i / 15)
            os.sleep(80)
        end
        update_task(6, "✓", "Resolve dependencies", 1.0)
        add_log("Dependencies resolved: 12 packages")
        os.sleep(200)
        
        -- Task 3: Compile
        add_log("Compiling source files...")
        local source_files = {"main.cpp", "utils.cpp", "config.cpp", "parser.cpp", "builder.cpp"}
        for i = 1, #source_files do
            update_task(5, "▶", "Compile sources", i / #source_files)
            add_log("Compiling " .. source_files[i])
            os.sleep(300)
        end
        update_task(5, "✓", "Compile sources", 1.0)
        add_log("Compilation completed: 5 files")
        os.sleep(200)
        
        -- Task 4: Link
        add_log("Linking executable...")
        for i = 1, 10 do
            update_task(4, "▶", "Link executable", i / 10)
            os.sleep(100)
        end
        update_task(4, "✓", "Link executable", 1.0)
        add_log("Executable created: build/myapp")
        os.sleep(200)
        
        -- Task 5: Package
        add_log("Creating package...")
        for i = 1, 8 do
            update_task(3, "▶", "Create package", i / 8)
            os.sleep(120)
        end
        update_task(3, "✓", "Create package", 1.0)
        add_log("Package created: dist/myapp-1.0.0.tar.gz")
        
        -- Done
        os.sleep(500)
        add_log("Build completed successfully! 🎉")
        
        -- Restore cursor
        os.sleep(1000)
        tty.cursor_show()
        
        print("\nBuild process completed!")
    end)
end

function demo_spinner()
    if not tty.has_vtansi() then
        return
    end
    
    print("\n\n=== Spinner Demo ===")
    print("Loading")
    
    local frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
    tty.cursor_hide()
    
    for round = 1, 3 do
        for _, frame in ipairs(frames) do
            tty.cursor_save()
            tty.cursor_move_up(1)
            tty.erase_line()
            io.write(string.format("Loading %s [round %d/3]", frame, round))
            io.flush()
            tty.cursor_restore()
            os.sleep(80)
        end
    end
    
    tty.cursor_save()
    tty.cursor_move_up(1)
    tty.erase_line()
    io.write("Loading ✓ Complete!")
    io.flush()
    tty.cursor_restore()
    tty.cursor_show()
    
    print("")
end

function main()
    print("\n" .. string.rep("=", 60))
    print("TTY Live Dashboard Demo")
    print(string.rep("=", 60))
    
    -- Demo 1: Spinner
    demo_spinner()
    
    os.sleep(1000)
    
    -- Demo 2: Build Dashboard
    simulate_build_process()
end

