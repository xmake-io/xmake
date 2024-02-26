import(".test_base", {alias = "test_build"})

function main(t)
    if test_build.can_build() then
        t:will_raise(test_build, "multiple declarations of module interface detected")
    end
end
