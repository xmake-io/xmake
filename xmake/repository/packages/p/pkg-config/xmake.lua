package("pkg-config")

    set_kind("binary")
    set_homepage("https://freedesktop.org/wiki/Software/pkg-config/")
    set_description("A helper tool used when compiling applications and libraries.")

    if is_host("macosx", "linux") then
        add_urls("https://pkgconfig.freedesktop.org/releases/pkg-config-$(version).tar.gz",
                 "http://fco.it.distfiles.macports.org/mirrors/macports-distfiles/pkgconfig/pkg-config-$(version).tar.gz",
                 "git://anongit.freedesktop.org/pkg-config")
        add_versions("0.29.2", "6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591")
    end

    on_install("macosx", "linux", function (package)
        local pcpath = {"/usr/local/lib/pkgconfig", "/usr/lib/pkgconfig"}
        if is_host("macosx") then
            local macver = os.iorun("sw_vers -productVersion"):trim()
            if #macver > 0 then
                local vers = macver:split('%.')
                table.insert(pcpath, "/usr/local/Homebrew/Library/Homebrew/os/mac/pkgconfig/" .. vers[1] .. '.' .. vers[2])
            end
        end
        import("package.tools.autoconf").install(package, {"--disable-debug", "--disable-host-tool", "--with-internal-glib", ["with-pc-path"] = table.concat(pcpath, ':')})
    end)

    on_test(function (package)
        os.vrun("pkg-config --version")
    end)
