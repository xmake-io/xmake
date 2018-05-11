
-- add modes: debug and release 
add_rules("mode.debug", "mode.release")

-- add target
target("kcs")

    -- add rules
    add_rules("wdk.kmdf.driver")

    -- add flags for rule: wdk.man
    add_values("wdk.man.flags", "-prefix Kcs")
    add_values("wdk.man.resource", "kcsCounters.rc")
    add_values("wdk.man.header", "kcsCounters.h")
    add_values("wdk.man.counter_header", "kcsCounters_counters.h")
    
    -- add files
    add_files("*.c", "*.rc", "*.man") 

