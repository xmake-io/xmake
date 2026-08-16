-- the esp32 blink example, it needs the esp32-devel addon
--
-- $ xmake f --board=esp32c3
-- $ xmake
-- $ xmake install                  -- flash the image to the board
-- $ xmake run                      -- flash it and monitor the serial output
--
includes("@addon/esp32-devel/board")

target("blink")
    add_rules("@addon/esp32-devel/app")
    add_files("src/*.c")

    -- the led pin of the board, @see boards/<board>/board.h
    add_includedirs("boards/" .. (get_config("board") or "esp32c3"))
