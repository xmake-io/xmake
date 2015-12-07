-- the base package
add_option("base")
    
    -- set category
    set_option_category("package")
   
    -- add links
    if os("windows") then add_option_links("ws2_32") 
    elseif os("android") then add_option_links("m", "c") 
    else add_option_links("pthread", "dl", "m", "c") end

