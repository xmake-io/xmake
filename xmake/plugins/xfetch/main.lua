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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ruki
-- @file        main.lua
--

-- imports
import("core.base.option")
import("core.base.global")
import("core.package.package", {alias = "core_package"})

-- the small ascii logos for the known systems, like fastfetch
local logos = {
    xmake = {color = "green", lines = {
        [[                     _        ]],
        [[__  ___ __  __  __ _| | ______]],
        [[\ \/ / |  \/  |/ _  | |/ / __ \]],
        [[ >  <  | \__/ | /_| |   <  ___/]],
        [[/_/\_\_|_|  |_|\__ \|_|\_\____|]]}},
    linux = {color = "yellow", lines = {
        [[    .--.]],
        [[   |o_o |]],
        [[   |:_/ |]],
        [[  //   \ \]],
        [[ (|     | )]],
        [[/'\_   _/`\]],
        [[\___)=(___/]]}},
    windows = {color = "blue", lines = {
        [[ ______ ______]],
        [[|      |      |]],
        [[|______|______|]],
        [[|      |      |]],
        [[|______|______|]]}},
    macosx = {color = "white", lines = {
        [[       .:']],
        [[    _ :'_]],
        [[ .'`_`-'_``.]],
        [[:________.-']],
        [[:_______:]],
        [[ :_______`-;]],
        [[  `._.-._.']]}},
    bsd = {color = "red", lines = {
        [[/\,-'''''-,/\]],
        [[\_)       (_/]],
        [[|           |]],
        [[|           |]],
        [[ ;         ;]],
        [[  '-_____-']]}},
    archlinux = {color = "cyan", lines = {
        [[      /\]],
        [[     /  \]],
        [[    /\   \]],
        [[   /      \]],
        [[  /   ,,   \]],
        [[ /   |  |  -\]],
        [[/_-''    ''-_\]]}},
    ubuntu = {color = "red", lines = {
        [[         _]],
        [[     ---(_)]],
        [[ _/  ---  \]],
        [[(_) |   |]],
        [[  \  --- _/]],
        [[     ---(_)]]}},
    debian = {color = "red", lines = {
        [[  _____]],
        [[ /  __ \]],
        [[|  /    |]],
        [[|  \___-]],
        [[-_]],
        [[  --_]]}},
    fedora = {color = "blue", lines = {
        [[      _____]],
        [[     /   __)\]],
        [[     |  /  \ \]],
        [[  ___|  |__/ /]],
        [[ / (_    _)_/]],
        [[/ /  |  |]],
        [[\ \__/  |]],
        [[ \(_____/]]}},
    centos = {color = "yellow", lines = {
        [[ ____^____]],
        [[ |\  |  /|]],
        [[ | \ | / |]],
        [[<---- ---->]],
        [[ | / | \ |]],
        [[ |/__|__\|]],
        [[     v]]}},
    linuxmint = {color = "green", lines = {
        [[ ___________]],
        [[|_          \]],
        [[  | | _____ |]],
        [[  | | | | | |]],
        [[  | | | | | |]],
        [[  | \_____/ |]],
        [[  \_________/]]}},
    gentoo = {color = "magenta", lines = {
        [[ _-----_]],
        [[(       \]],
        [[\    0   \]],
        [[ \        )]],
        [[ /      _/]],
        [[(     _-]],
        [[\____-]]}},
    opensuse = {color = "green", lines = {
        [[  _______]],
        [[__|   __ \]],
        [[     / .\ \]],
        [[     \__/ |]],
        [[   _______|]],
        [[   \_______]],
        [[__________/]]}},
    manjaro = {color = "green", lines = {
        [[||||||||| ||||]],
        [[||||||||| ||||]],
        [[||||      ||||]],
        [[|||| |||| ||||]],
        [[|||| |||| ||||]],
        [[|||| |||| ||||]],
        [[|||| |||| ||||]]}},
    nixos = {color = "blue", lines = {
        [[  \\  \\ //]],
        [[ ==\\__\\/ //]],
        [[   //   \\//]],
        [[==//     //==]],
        [[ //\\___//]],
        [[// /\\  \\==]],
        [[  // \\  \\]]}},
    alpine = {color = "blue", lines = {
        [[   /\ /\]],
        [[  /  \  \]],
        [[ /    \  \]],
        [[/      \  \]],
        [[        \  \]],
        [[         \]]}}
}
-- get the logo of the current system
function _get_logo()
    local name = option.get("logo")
    if not name then
        -- os.host() is always the real host system, e.g. windows, linux, macosx ..
        -- even if we are running in the msys/cygwin subsystem, @see os.subhost()
        name = os.host()
        if name == "linux" then
            name = linuxos.name()
        end
    end
    -- we will show the linux or xmake logo if the logo drawing is not found
    local logo = logos[name]
    if not logo then
        logo = os.host() == "linux" and logos.linux or logos.xmake
    end
    return logo
end

-- get the user and host name
function _get_title()
    local user = os.getenv("USER") or os.getenv("USERNAME") or "user"
    local host = os.getenv("HOSTNAME") or os.getenv("COMPUTERNAME")
    if not host and is_host("linux", "macosx", "bsd") and os.isfile("/etc/hostname") then
        local content = io.readfile("/etc/hostname")
        if content then
            host = content:trim()
        end
    end
    return user .. "@" .. (host or os.host())
end

-- get the operation system name and version
function _get_os()
    if is_host("linux") then
        -- the system version may be unavailable on the rolling release distributions
        local version = try { function () return linuxos.version() end }
        return linuxos.name() .. (version and (" " .. tostring(version)) or "") .. " " .. os.arch()
    elseif is_host("macosx") then
        local version = try { function () return macos.version() end }
        return "macOS" .. (version and (" " .. tostring(version)) or "") .. " " .. os.arch()
    elseif is_host("windows") then
        local version = try { function () return winos.version() end }
        return "Windows" .. (version and (" " .. tostring(version)) or "") .. " " .. os.arch()
    end
    return os.host() .. " " .. os.arch()
end

-- get the cpu name
function _get_cpu()
    local name = os.cpuinfo("model_name") or os.cpuinfo("vendor") or "unknown"
    return string.format("%s (%d)", name, os.cpuinfo("ncpu") or 1)
end

-- format the given size in MB as GiB, we do not use `%.1f` to avoid the locale decimal separator
function _format_gib(size_mb)
    local gib10 = math.floor(size_mb / 1024 * 10 + 0.5)
    return string.format("%d.%d GiB", math.floor(gib10 / 10), gib10 % 10)
end

-- get the memory usage, the sizes of os.meminfo() are in MB
function _get_memory()
    local meminfo = os.meminfo()
    if meminfo.totalsize and meminfo.availsize then
        -- `%%%%` will be shown as `%`, because cprint will format this string again
        return string.format("%s / %s (%d%%%%)",
            _format_gib(meminfo.totalsize - meminfo.availsize),
            _format_gib(meminfo.totalsize),
            math.floor(meminfo.usagerate * 100))
    end
end

-- get the count of the installed packages
function _get_packages()
    local count = #os.dirs(path.join(core_package.installdir(), "*", "*"))
    return string.format("%d (xrepo)", count)
end

-- get the count of the installed plugins
function _get_plugins()
    return tostring(#os.files(path.join(global.directory(), "plugins", "*", "xmake.lua")))
end

-- get all the information lines
function _get_infolines(color)
    local title = _get_title()
    local infos = {
        {"OS",       _get_os()},
        {"CPU",      _get_cpu()},
        {"Memory",   _get_memory()},
        {"Shell",    os.shell()},
        {"Terminal", os.term()},
        {"xmake",    "v" .. xmake.version()},
        {"Packages", _get_packages()},
        {"Plugins",  _get_plugins()},
        {"Theme",    global.get("theme") or "default"}
    }
    if is_host("linux") then
        local kernelver = try { function () return linuxos.kernelver() end }
        if kernelver then
            table.insert(infos, 2, {"Kernel", tostring(kernelver)})
        end
    end
    local lines = {}
    table.insert(lines, "${bright " .. color .. "}" .. title .. "${clear}")
    table.insert(lines, string.rep("-", #title))
    for _, info in ipairs(infos) do
        if info[2] then
            table.insert(lines, "${bright " .. color .. "}" .. info[1] .. "${clear}: " .. info[2])
        end
    end
    table.insert(lines, "")
    table.insert(lines, "${onblack}   ${onred}   ${ongreen}   ${onyellow}   ${onblue}   ${onmagenta}   ${oncyan}   ${onwhite}   ${clear}")
    return lines
end

function main()
    local logo = _get_logo()
    local logolines = logo.lines
    local infolines = _get_infolines(logo.color)
    -- show the logo and information side by side, like fastfetch
    local width = 0
    for _, line in ipairs(logolines) do
        width = math.max(width, #line)
    end
    local startline = 1
    if #infolines > #logolines then
        startline = math.floor((#infolines - #logolines) / 2) + 1
    end
    print("")
    for i = 1, math.max(#logolines, #infolines) do
        local left = logolines[i - startline + 1] or ""
        local right = infolines[i] or ""
        left = left .. string.rep(" ", width - #left)
        -- escape `%`, because cprint will format this string again
        left = left:gsub("%%", "%%%%")
        cprint("  ${bright %s}%s${clear}  %s", logo.color, left, right)
    end
    print("")
end
