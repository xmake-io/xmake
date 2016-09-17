-- the base package
option("base")
    
    -- set category
    set_category("package")
   
    -- add links
    if is_os("windows") then add_links("ws2_32") 
    elseif is_os("android") then add_links("m", "c") 
    else add_links("pthread", "dl", "m", "c") end

