import(".test_base", {alias = "test_build"})

function main(t)
  t:will_raise(test_build, "circular modules dependency detected")
end
