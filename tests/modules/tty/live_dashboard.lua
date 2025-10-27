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
    io.write("⏸ Parse project files       [" .. string.rep("░", 30) .. "]   0%\n")
    io.write("⏸ Resolve dependencies      [" .. string.rep("░", 30) .. "]   0%\n")
    io.write("⏸ Compile sources           [" .. string.rep("░", 30) .. "]   0%\n")
    io.write("⏸ Link executable           [" .. string.rep("░", 30) .. "]   0%\n")
    io.write("⏸ Create package            [" .. string.rep("░", 30) .. "]   0%\n")
    io.write("\nRecent logs:\n")
    io.flush()

    local log_count = 0

    local function update_task_line(task_index, icon, name, progress)
        -- Move to the task line (from current cursor position)
        -- We need to go up: log_count lines + 1 separator line + (5 - task_index) task lines
        local lines_up = log_count + 1 + (5 - task_index + 1)
        tty.cursor_move_up(lines_up)

        tty.cr()
        tty.erase_line()
        local bar_width = 30
        local filled = math.floor(progress * bar_width)
        local bar = string.rep("█", filled) .. string.rep("░", bar_width - filled)
        io.write(string.format("%s %-24s [%s] %3d%%\n", icon, name, bar, math.floor(progress * 100)))

        -- Move back down
        tty.cursor_move_down(lines_up - 1)
        io.flush()
    end

    local function add_log(message)
        io.write(string.format("[%s] %s\n", os.date("%H:%M:%S"), message))
        io.flush()
        log_count = log_count + 1
    end

    scheduler.co_start(function()
        -- Task 1: Parse (index 1, top task)
        add_log("Starting project parsing...")
        for i = 1, 20 do
            update_task_line(1, "▶", "Parse project files", i / 20)
            os.sleep(50)
        end
        update_task_line(1, "✓", "Parse project files", 1.0)
        add_log("Project parsed successfully")
        os.sleep(200)

        -- Task 2: Dependencies (index 2)
        add_log("Resolving dependencies...")
        for i = 1, 15 do
            update_task_line(2, "▶", "Resolve dependencies", i / 15)
            os.sleep(80)
        end
        update_task_line(2, "✓", "Resolve dependencies", 1.0)
        add_log("Dependencies resolved: 12 packages")
        os.sleep(200)

        -- Task 3: Compile (index 3)
        add_log("Compiling source files...")
        local source_files = {"main.cpp", "utils.cpp", "config.cpp", "parser.cpp", "builder.cpp"}
        for i = 1, #source_files do
            update_task_line(3, "▶", "Compile sources", i / #source_files)
            add_log("Compiling " .. source_files[i])
            os.sleep(300)
        end
        update_task_line(3, "✓", "Compile sources", 1.0)
        add_log("Compilation completed: 5 files")
        os.sleep(200)

        -- Task 4: Link (index 4)
        add_log("Linking executable...")
        for i = 1, 10 do
            update_task_line(4, "▶", "Link executable", i / 10)
            os.sleep(100)
        end
        update_task_line(4, "✓", "Link executable", 1.0)
        add_log("Executable created: build/myapp")
        os.sleep(200)

        -- Task 5: Package (index 5, bottom task)
        add_log("Creating package...")
        for i = 1, 8 do
            update_task_line(5, "▶", "Create package", i / 8)
            os.sleep(120)
        end
        update_task_line(5, "✓", "Create package", 1.0)
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
    io.write("Loading\n")
    io.flush()

    local frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
    tty.cursor_hide()

    for round = 1, 3 do
        for _, frame in ipairs(frames) do
            tty.cursor_move_up(1)
            tty.cr()
            tty.erase_line()
            io.write(string.format("Loading %s [round %d/3]\n", frame, round))
            io.flush()
            os.sleep(80)
        end
    end

    tty.cursor_move_up(1)
    tty.cr()
    tty.erase_line()
    io.write("Loading ✓ Complete!\n")
    io.flush()
    tty.cursor_show()
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

