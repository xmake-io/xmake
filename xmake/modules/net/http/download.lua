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
-- @file        download.lua
--

-- imports
import("core.base.option")
import("lib.detect.find_tool")
import("net.proxy")

-- get user agent
function _get_user_agent()

    -- init user agent
    if _g._USER_AGENT == nil then

        -- init systems
        local systems = {macosx = "Macintosh", linux = "Linux", windows = "Windows", msys = "MSYS", cygwin = "Cygwin"}

        -- os user agent
        local os_user_agent = ""
        if is_host("macosx") then
            local osver = try { function() return os.iorun("/usr/bin/sw_vers -productVersion") end }
            if osver then
                os_user_agent = ("Intel Mac OS X " .. (osver or "")):trim()
            end
        elseif is_subhost("linux", "msys", "cygwin") then
            local osver = try { function () return os.iorun("uname -r") end }
            if osver then
                os_user_agent = (os_user_agent .. " " .. (osver or "")):trim()
            end
        end

        -- make user agent
        _g._USER_AGENT = string.format("Xmake/%s (%s;%s)", xmake.version(), systems[os.subhost()] or os.subhost(), os_user_agent)
    end
    return _g._USER_AGENT
end

-- download url using curl
function _curl_download(tool, url, outputfile, opt)

    -- set basic arguments
    local argv = {}
    if option.get("verbose") then
        table.insert(argv, "-SL")
    else
        table.insert(argv, "-fsSL")
    end

    -- use proxy?
    local proxy_conf = proxy.config(url)
    if proxy_conf then
        table.insert(argv, "-x")
        table.insert(argv, proxy_conf)
    end

    -- set user-agent
    local user_agent = _get_user_agent()
    if user_agent then
        if tool.version then
            user_agent = user_agent .. " curl/" .. tool.version
        end
        table.insert(argv, "-A")
        table.insert(argv, user_agent)
    end

    -- ignore to check ssl certificates
    if opt.insecure then
        table.insert(argv, "-k")
    end

    -- continue to download?
    if opt.continue then
        table.insert(argv, "-C")
        table.insert(argv, "-")
    end

    -- set url
    table.insert(argv, url)

    -- ensure output directory
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set outputfile
    table.insert(argv, "-o")
    table.insert(argv, outputfile)

    -- download it
    os.vrunv(tool.program, argv)
end

-- download url using wget
function _wget_download(tool, url, outputfile, opt)

    -- ensure output directory
    local argv = {url}
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- use proxy?
    local proxy_conf = proxy.config(url)
    if proxy_conf then
        table.insert(argv, "-e")
        table.insert(argv, "use_proxy=yes")
        table.insert(argv, "-e")
        if url:startswith("http://") then
            table.insert(argv, "http_proxy=" .. proxy_conf)
        elseif url:startswith("https://") then
            table.insert(argv, "https_proxy=" .. proxy_conf)
        elseif url:startswith("ftp://") then
            table.insert(argv, "ftp_proxy=" .. proxy_conf)
        else
            table.insert(argv, "http_proxy=" .. proxy_conf)
        end
    end

    -- set user-agent
    local user_agent = _get_user_agent()
    if user_agent then
        if tool.version then
            user_agent = user_agent .. " wget/" .. tool.version
        end
        table.insert(argv, "-U")
        table.insert(argv, user_agent)
    end

    -- ignore to check ssl certificates
    if opt.insecure then
        table.insert(argv, "--no-check-certificate")
    end

    -- continue to download?
    if opt.continue then
        table.insert(argv, "-c")
    end

    -- set outputfile
    table.insert(argv, "-O")
    table.insert(argv, outputfile)

    -- download it
    os.vrunv(tool.program, argv)
end

-- download url
--
-- @param url           the input url
-- @param outputfile    the output file
-- @param opt           the option, {continue = true}
--
--
function main(url, outputfile, opt)

    -- init output file
    opt = opt or {}
    outputfile = outputfile or path.filename(url):gsub("%?.+$", "")

    -- attempt to download url using curl first
    local tool = find_tool("curl", {version = true})
    if tool then
        return _curl_download(tool, url, outputfile, opt)
    end

    -- download url using wget
    tool = find_tool("wget", {version = true})
    if tool then
        return _wget_download(tool, url, outputfile, opt)
    end
end
