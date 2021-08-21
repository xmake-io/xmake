function get_module_flags(compinst, toolname, opt)
    local modulesflag = nil
    local outputflag = nil
    local interfaceflag = nil
    local partitionflag = nil
    if toolname:find("clang", 1, true) or toolname:find("gcc", 1, true) then
        if compinst:has_flags("-fmodules") then
            modulesflag = "-fmodules"
        elseif compinst:has_flags("-fmodules-ts") then
            modulesflag = "-fmodules-ts"
        end
    elseif toolname == "cl" then
        if compinst:has_flags("/experimental:module") then
            modulesflag = "/experimental:module"
        else
            print("Modules flag not found.")
        end

        if compinst:has_flags("/ifcOutput")  then
            outputflag = "/ifcOutput"
        elseif compinst:has_flags("/module:output") then
            outputflag = "/module:output"
        end

        if compinst:has_flags("/interface") then
                    interfaceflag = "/interface"
        elseif compinst:has_flags("/module:interface") then
            interfaceflag = "/module:interface"
        else
            print("Module interfaces flag not found.")
        end

        if compinst:has_flags("/internalPartition") then
            partitionflag = "/internalPartition"
        else
            print("Module interface partitions flag not found.")
        end
    end

    if modulesflag then
        opt.modulesflag = modulesflag
    end
    if outputflag then 
        opt.outputflag = outputflag
    end
    if interfaceflag then
        opt.interfaceflag = interfaceflag
    end
    if partitionflag then
        opt.partitionflag = partitionflag
    end
end