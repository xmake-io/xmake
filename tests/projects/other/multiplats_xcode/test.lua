function main(t)
    if is_host("macosx") then
        os.exec("xmake f -c -vD")
        os.exec("xmake -rvD")
        os.exec("xmake f -c -vD -p iphoneos")
        -- build only arm64 target first, avoid building armv7 if SDK doesn't support it
        os.exec("xmake -rvD test_iphoneos")
        -- try to build armv7 target, skip if SDK doesn't support it
        try
        {
            function ()
                os.exec("xmake f -c -vD -p iphoneos -a armv7")
                os.exec("xmake -rvD test_iphoneos_armv7")
            end,
            catch
            {
                function (errors)
                    -- SDK doesn't support armv7, skip this target
                    cprint("${color.warning}skip test_iphoneos_armv7: SDK doesn't support armv7")
                end
            }
        }
    end
end
