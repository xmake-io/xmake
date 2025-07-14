add_rules("mode.debug", "mode.release")

add_requires("sfml")

target("graphics")
    set_kind("static")
    add_files("src/graphics.cpp")
    add_packages("sfml", {components = "graphics", public = true})

target("network")
    set_kind("static")
    add_files("src/network.cpp")
    add_packages("sfml", {components = "network", public = true})

target("test")
    set_kind("binary")
    add_files("src/main.cpp")
    add_deps("graphics", "network")

package("sfml")
    set_homepage("https://www.sfml-dev.org")
    set_description("Simple and Fast Multimedia Library")
    set_license("zlib")

    add_urls("https://github.com/SFML/SFML/archive/refs/tags/$(version).tar.gz",
             "https://github.com/SFML/SFML.git")

    -- Before 2.6.0 only x86 is supported for Mac
    if not is_plat("macosx") or not is_arch("arm.*") then
        add_versions("2.5.1", "438c91a917cc8aa19e82c6f59f8714da353c488584a007d401efac8368e1c785")
    end

    add_versions("3.0.1", "f99f71bb2f2608835b1a37e078512b75dd39d52b89e13e12246603a950da3c1f")
    add_versions("3.0.0", "37506fafbd618b1f8e153bbca8811e62203a70b32a1183279fb9612fd0501d2b")
    add_versions("2.6.1", "82535db9e57105d4f3a8aedabd138631defaedc593cab589c924b7d7a11ffb9d")
    add_versions("2.6.0", "0c3f84898ea1db07dc46fa92e85038d8c449e3c8653fe09997383173de96bc06")

    add_configs("graphics",   {description = "Use the graphics module", default = true, type = "boolean"})
    add_configs("window",     {description = "Use the window module", default = true, type = "boolean"})
    add_configs("audio",      {description = "Use the audio module", default = true, type = "boolean"})
    add_configs("network",    {description = "Use the network module", default = true, type = "boolean"})
    if is_plat("windows", "mingw") then
        add_configs("main", {description = "Link to the sfml-main library", default = true, type = "boolean"})
    end

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::sfml")
    elseif is_plat("linux") then
        add_extsources("pacman::sfml", "apt::libsfml-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::sfml/sfml-all")
    end

    if not is_host("windows") then
        add_extsources("pkgconfig::sfml-all")
    end

    on_component("graphics", function (package, component)
        local e = package:config("shared") and "" or "-s"
        if package:debug() then
            e = e .. "-d"
        end
        component:add("links", "sfml-graphics" .. e)
        component:add("deps", "window", "system")
        component:add("extsources", "brew::sfml/sfml-graphics")
        component:add("extsources", "pkgconfig::sfml-graphics")
    end)

    on_component("window", function (package, component)
        local e = package:config("shared") and "" or "-s"
        if package:debug() then
            e = e .. "-d"
        end
        component:add("links", "sfml-window" .. e)
        component:add("deps", "system")
        component:add("extsources", "brew::sfml/sfml-window")
        component:add("extsources", "pkgconfig::sfml-window")
        if not package:config("shared") then
            if package:is_plat("windows", "mingw") then
                component:add("syslinks", "opengl32", "gdi32", "advapi32", "user32")
            elseif package:is_plat("linux") then
                component:add("syslinks", "dl")
            elseif package:is_plat("bsd") then
                component:add("syslinks", "usbhid")
            elseif package:is_plat("macosx") then
                component:add("frameworks", "Foundation", "AppKit", "IOKit", "Carbon")
            elseif package:is_plat("iphoneos") then
                component:add("frameworks", "Foundation", "UIKit", "CoreGraphics", "QuartzCore", "CoreMotion")
            end
        end
    end)

    on_component("audio", function (package, component)
        local e = package:config("shared") and "" or "-s"
        if package:debug() then
            e = e .. "-d"
        end
        component:add("links", "sfml-audio" .. e)
        component:add("deps", "system")
        component:add("extsources", "brew::sfml/sfml-audio")
        component:add("extsources", "pkgconfig::sfml-audio")
        if not package:config("shared") and package:is_plat("windows", "mingw") then
            component:add("links", "flac", "vorbisenc", "vorbisfile", "vorbis", "ogg")
            if not (package:gitref() or package:version():ge("3.0.0")) then
                component:add("links", "openal32")
            end
        end
    end)

    on_component("network", function (package, component)
        local e = package:config("shared") and "" or "-s"
        if package:debug() then
            e = e .. "-d"
        end
        component:add("links", "sfml-network" .. e)
        component:add("deps", "system")
        component:add("extsources", "brew::sfml/sfml-network")
        component:add("extsources", "pkgconfig::sfml-network")
        component:add("extsources", "apt::sfml-network")
        if not package:config("shared") and package:is_plat("windows", "mingw") then
            component:add("syslinks", "ws2_32")
        end
    end)

    on_component("system", function (package, component)
        local e = package:config("shared") and "" or "-s"
        if package:debug() then
            e = e .. "-d"
        end
        component:add("links", "sfml-system" .. e)
        if package:is_plat("windows", "mingw") then
            component:add("syslinks", "winmm")
        end
        if package:is_plat("windows", "mingw") and package:config("main") then
            component:add("deps", "main")
        end
        component:add("extsources", "brew::sfml/sfml-system")
        component:add("extsources", "pkgconfig::sfml-system")
        if not package:config("shared") then
            if package:is_plat("windows", "mingw") then
                component:add("syslinks", "winmm")
            elseif package:is_plat("linux") then
                component:add("syslinks", "rt", "pthread")
            elseif package:is_plat("bsd", "macosx") then
                component:add("syslinks", "pthread")
            end
        end
    end)

    on_component("main", function (package, component)
        if package:is_plat("windows", "mingw") then
            local main_module = "sfml-main"
            if package:debug() then
                main_module = main_module .. "-d"
            end
            component:add("links", main_module)
        end
    end)

    on_load("windows", "linux", "macosx", "mingw", function (package)
        if package:is_plat("windows", "linux", "macosx") then
            package:add("deps", "cmake")
        end

        if not package:config("shared") then
            package:add("defines", "SFML_STATIC")
        end

        if package:config("graphics") then
            package:add("deps", "freetype")
        end

        if package:is_plat("linux") then
            if package:config("window") or package:config("graphics") then
                package:add("deps", "libx11", "libxcursor", "libxrandr", "libxrender", "libxfixes", "libxext", "eudev", "libxi")
                package:add("deps", "opengl", "glx", {optional = true})
            end
        end

        if package:config("audio") then
            package:add("deps", "libogg", "libflac", "libvorbis")
            if not (package:gitref() or package:version():ge("3.0.0")) then
                package:add("deps", "openal-soft")
            end
        end

        package:add("components", "system")
        for _, component in ipairs({"graphics", "window", "audio", "network"}) do
            if package:config(component) then
                package:add("components", component)
            end
        end

        if package:is_plat("windows", "mingw") and package:config("main") then
            package:add("components", "main")
        end
    end)

    on_install("windows", "linux", "macosx", "mingw", function (package)
        local configs = {"-DSFML_BUILD_DOC=OFF", "-DSFML_BUILD_EXAMPLES=OFF"}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        if package:config("shared") then
            table.insert(configs, "-DBUILD_SHARED_LIBS=ON")
            -- Fix missing system libs
            if package:config("audio") and not (package:gitref() or package:version():ge("3.0.0")) then
                if package:is_plat("windows", "mingw") then
                    local file = io.open("src/SFML/Audio/CMakeLists.txt", "a")
                    file:print("target_link_libraries(OpenAL INTERFACE winmm)")
                    file:close()
                end
            end
            if package:config("graphics") then
                local freetype = package:dep("freetype")
                if freetype then
                    local fetchinfo = freetype:fetch()
                    if fetchinfo then
                        if not freetype:config("shared") then
                            local libfiles = {}
                            for _, dep in ipairs(freetype:librarydeps()) do
                                local depinfo = dep:fetch()
                                if depinfo then
                                    table.join2(libfiles, depinfo.libfiles)
                                end
                            end
                            if #libfiles > 0 then
                                local libraries = {}
                                for _, libfile in ipairs(libfiles) do
                                    table.insert(libraries, (libfile:gsub("\\", "/")))
                                end
                                local lib_name = (package:gitref() or package:version():ge("3.0.0")) and "freetype" or "Freetype"
                                local file = io.open("src/SFML/Graphics/CMakeLists.txt", "a")
                                file:print("target_link_libraries(%s INTERFACE %s)", lib_name, table.concat(libraries, " "))
                                file:close()
                            end
                        end
                    end
                end
            end
            if package:config("window") and package:is_plat("linux") then
                local libfiles = {}
                for _, name in ipairs({"libx11", "libxcursor", "libxrandr", "libxrender", "libxfixes", "libxext"}) do
                    local dep = package:dep(name)
                    if dep then
                        local fetchinfo = dep:fetch()
                        if fetchinfo then
                            table.join2(libfiles, fetchinfo.libfiles)
                        end
                    end
                end
                if #libfiles > 0 then
                    libfiles = table.reverse_unique(libfiles)
                    local libraries = {}
                    for _, libfile in ipairs(libfiles) do
                        table.insert(libraries, (libfile:gsub("\\", "/")))
                    end
                    local file = io.open("src/SFML/Window/CMakeLists.txt", "a")
                    file:print("target_link_libraries(sfml-window PRIVATE " .. table.concat(libraries, " ") .. ")")
                    file:close()
                end
            end
        else
            table.insert(configs, "-DBUILD_SHARED_LIBS=OFF")
             -- SFML overrides MSVC runtimes if set to ON, xmake already takes cares of setting it
            table.insert(configs, "-DSFML_USE_STATIC_STD_LIBS=OFF")
        end
        table.insert(configs, "-DSFML_BUILD_AUDIO=" .. (package:config("audio") and "ON" or "OFF"))
        table.insert(configs, "-DSFML_BUILD_GRAPHICS=" .. (package:config("graphics") and "ON" or "OFF"))
        table.insert(configs, "-DSFML_BUILD_WINDOW=" .. (package:config("window") and "ON" or "OFF"))
        table.insert(configs, "-DSFML_BUILD_NETWORK=" .. (package:config("network") and "ON" or "OFF"))
        table.insert(configs, "-DWARNINGS_AS_ERRORS=OFF")
        if not is_plat("mingw") then
            table.insert(configs, "-DSFML_USE_SYSTEM_DEPS=TRUE")
        end
        if package:gitref() or package:version():ge("3.0.0") then
            table.insert(configs, "-DCMAKE_CXX_STANDARD=17")
        end

        local packagedeps
        if package:config("audio") and not (package:gitref() or package:version():ge("3.0.0")) then
            packagedeps = packagedeps or {}
            table.insert(packagedeps, "openal-soft")
        end
        if package:config("graphics") then
            packagedeps = packagedeps or {}
            table.insert(packagedeps, "freetype")
            table.insert(packagedeps, "zlib")
        end

        import("package.tools.cmake").install(package, configs, {packagedeps = packagedeps})
    end)

    on_test(function (package)
        local configs = (package:gitref() or package:version():ge("3.0.0")) and {languages = "c++17"} or {}
        assert(package:check_cxxsnippets({test = [[
            void test(int args, char** argv) {
                sf::Clock c;
                c.restart();
            }
        ]]}, {configs = configs, includes = "SFML/System.hpp"}))
        if package:config("graphics") then
            assert(package:check_cxxsnippets({test = [[
                void test(const sf::Texture& texture, const sf::Color& color) {
                    sf::Sprite sprite(texture);
                    sprite.setColor(color);
                }
            ]]}, {configs = configs, includes = "SFML/Graphics.hpp"}))
        end
        if package:config("window") or package:config("graphics") then
            assert(package:check_cxxsnippets({test = [[
                void test(int args, char** argv) {
                    sf::Window window(sf::VideoMode(), "Title");

                    window.close();
                }
            ]]}, {configs = configs, includes = "SFML/Window.hpp"}))
        end
        if package:config("audio") then
            assert(package:check_cxxsnippets({test = [[
                void test(int args, char** argv) {
                    sf::Music music;
                    auto res = music.openFromFile("music.ogg");
                    music.play();
                }
            ]]}, {configs = configs, includes = "SFML/Audio.hpp"}))
        end
        if package:config("network") then
            assert(package:check_cxxsnippets({test = [[
                void test(sf::UdpSocket& socket, const sf::IpAddress& remoteAddress) {
                    char data[100];
                    unsigned short remotePort = 54000;
                    auto status = socket.send(data, 100, remoteAddress, remotePort);
                }
            ]]}, {configs = configs, includes = "SFML/Network.hpp"}))
        end
    end)
package_end()
