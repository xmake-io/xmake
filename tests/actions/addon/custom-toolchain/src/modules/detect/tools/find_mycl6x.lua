import("lib.detect.find_program")

-- find the compiler of the my-c6000 toolchain
--
-- @note it's just the host compiler, we only need a real program to build with,
-- the point of this test is that this finder itself comes from the addon
--
function main(opt)
    for _, name in ipairs({"gcc", "clang", "cc"}) do
        local program = find_program(name, opt)
        if program then
            return program
        end
    end
end
