import("core.base.pipe")
import("core.base.bytes")

function test_read_start(t)
    local cases = {
        {"default_block", 8, "abc", nil, true, 3, "abc", "abc#####"},
        {"start1_once", 8, "wxyz", 1, false, 4, "wxyz", "wxyz####"},
        {"start1_full", 8, "ABCDEFGH", 1, true, 8, "ABCDEFGH", "ABCDEFGH"},
        {"start1_byte", 4, "Z", 1, false, 1, "Z", "Z###"},
        {"start2_block", 8, "abc", 2, true, 3, "abc", "#abc####"},
        {"start2_once", 8, "WXYZ", 2, false, 4, "WXYZ", "#WXYZ###"},
        {"start2_block_long", 10, "abcde", 2, true, 5, "abcde", "#abcde####"},
        {"start2_last_byte", 5, "pqrs", 2, false, 4, "pqrs", "#pqrs"}
    }
    local failures = {}
    for index, case in ipairs(cases) do
        local rpipe, wpipe = pipe.openpair("BB", 1024)
        try {
            function ()
                local buff = bytes(case[2], "#")
                if index == 1 then
                    print("PIPE_READ_BINDING public=%s base=%s bytes=%s",
                          debug.getinfo(rpipe.read).source, debug.getinfo(rpipe._read).source,
                          debug.getinfo(buff.slice).source)
                end
                -- Prewrite every byte before a single native read; no peer process is needed.
                t:are_equal(wpipe:write(case[3], {block = true, timeout = 1000}), case[6])
                local count, data = rpipe:read(buff, case[6], {start = case[4], block = case[5], timeout = 1000})
                local text = data and data:str() or nil
                local length = data and data:size() or -1
                local contents = buff:str()
                local passed = count == case[6] and length == case[6] and text == case[7] and contents == case[8]
                print("PIPE_READ_CASE name=%s status=%s count=%d length=%d data=%q buffer=%q",
                      case[1], passed and "PASS" or "FAIL", count, length, text or "<nil>", contents)
                if not passed then
                    table.insert(failures, string.format("%s: expected count/length %d and data %q, got %d/%d and %q",
                                                        case[1], case[6], case[7], count, length, text or "<nil>"))
                end
            end,
            finally {
                function ()
                    rpipe:close()
                    wpipe:close()
                    print("PIPE_READ_CLOSED name=%s handles=%s", case[1],
                          rpipe:cdata() == nil and wpipe:cdata() == nil and "CLOSED" or "OPEN")
                end
            }
        }
    end
    t:require(#failures == 0, table.concat(failures, "\n"))
end
