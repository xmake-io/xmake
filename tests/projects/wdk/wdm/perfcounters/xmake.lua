add_rules("mode.debug", "mode.release")

target("kcs")
    add_rules("wdk.env.wdm", "wdk.driver")
    add_values("wdk.man.prefix", "Kcs")
    add_values("wdk.man.resource", "kcsCounters.rc")
    add_values("wdk.man.header", "kcsCounters.h")
    add_values("wdk.man.counter_header", "kcsCounters_counters.h")
    add_files("*.c", "*.rc", "*.man")

