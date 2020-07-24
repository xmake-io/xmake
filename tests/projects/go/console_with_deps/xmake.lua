add_rules("mode.debug", "mode.release")

add_requires("go::golang.org/x/sys/unix", {alias = "unix"})
add_requires("go::github.com/sirupsen/logrus", {alias = "logrus"})

target("test")
    set_kind("binary")
    add_files("src/*.go")
    add_packages("logrus", "unix")

