--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        xmake.lua
--

rule("go.env")
    on_load(function (target)

        -- imports
        import("private.tools.go.goenv")
        import("private.async.runjobs")
        import("core.base.tty")
        import("core.base.option")
        import("core.project.config")

        -- check and install go packages for other platform
        local goroot   = goenv.GOROOT()
        local goos     = goenv.GOOS(target:plat())
        local goarch   = goenv.GOARCH(target:arch())
        if goroot and goos and goarch then
            local goroot_local = path.join(config.buildir(), ".goenv", path.filename(goroot))
            local gopkgdir = path.join(os.isdir(goroot_local) and goroot_local or goroot, "pkg", goos .. "_" .. goarch)
            if not os.isdir(gopkgdir) or os.emptydir(gopkgdir) then
                local gosrcdir = path.join(goroot, "src")
                local confirm = utils.confirm({default = true, description = ("we need build go for %s_%s only once first!"):format(goos, goarch)})
                if confirm then
                    local build_task = function ()
                        tty.erase_line_to_start().cr()
                        printf("building go for %s_%s .. ", goos, goarch)
                        io.flush()
                        if is_host("windows") then
                            os.vrunv(path.join(gosrcdir, "make.bat"), {"--no-clean"}, {envs = {GOOS = goos, GOARCH = goarch, GOROOT_BOOTSTRAP = goroot}, curdir = gosrcdir})
                        else

                            -- we need copy goroot to the local directory to solving permission problem
                            if is_host("linux") then
                                os.vcp(goroot, goroot_local)
                                goroot = path.absolute(goroot_local)
                                gosrcdir = path.absolute(path.join(goroot_local, "src"))
                            end

                            -- we patch '/' to GOROOT_BOOTSTRAP to solve the following issue
                            --
                            -- in make.bash
                            -- ERROR: $GOROOT_BOOTSTRAP must not be set to $GOROOT
                            -- Set $GOROOT_BOOTSTRAP to a working Go tree >= Go 1.4.
                            --
                            os.vrunv(path.join(gosrcdir, "make.bash"), {"--no-clean"}, {envs = {GOOS = goos, GOARCH = goarch, GOROOT_BOOTSTRAP = goroot .. "/"}, curdir = gosrcdir})
                        end
                        tty.erase_line_to_start().cr()
                        cprint("building go for %s_%s .. ${color.success}${text.success}", goos, goarch)
                    end
                    if option.get("verbose") then
                        build_task()
                    else
                        runjobs("build/goenv", build_task, {progress = true})
                    end
                end
            end

            -- switch to the local go root directory
            if os.isdir(goroot_local) and os.isdir(gopkgdir) and not os.emptydir(gopkgdir) then
                config.set("gc",   path.join(goroot_local, "bin", "go"), {readonly = true, force = true})
                config.set("gcld", path.join(goroot_local, "bin", "go"), {readonly = true, force = true})
                config.set("gcar", path.join(goroot_local, "bin", "go"), {readonly = true, force = true})
            end
        end
    end)
