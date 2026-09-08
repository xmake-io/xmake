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
-- @file        download.lua
--

-- imports
import("core.base.global")
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

-- download url using aria2
function _aria2_download(tool, url, outputfile, opt)

    -- ensure output directory
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- set basic arguments
    local argv = {"--no-conf=true"}
    if option.get("verbose") then
        table.insert(argv, "--console-log-level=notice")
    else
        table.insert(argv, "--console-log-level=error")
    end

    -- user-agent
    local user_agent = _get_user_agent()
    if user_agent then
        table.insert(argv, "--user-agent=" .. user_agent)
    end

    -- use proxy?
    local proxy_conf = proxy.config(url)
    if proxy_conf then
        table.insert(argv, "--all-proxy=" .. proxy_conf)
    end

    -- ignore to check ssl certificates
    if opt.insecure then
        table.insert(argv, "--check-certificate=false")
    end

    -- add custom headers
    if opt.headers then
        for _, header in ipairs(opt.headers) do
            table.insert(argv, "--header=" .. header)
        end
    end

    -- continue to download?
    if opt.continue then
        table.insert(argv, "--continue=true")
    end

    -- set connect timeout
    if opt.timeout then
        table.insert(argv, "--connect-timeout=" .. tostring(opt.timeout))
    end

    -- set read timeout (inactivity timeout in aria2)
    if opt.read_timeout then
        table.insert(argv, "--timeout=" .. tostring(opt.read_timeout))
    end

    -- disable asynchronous DNS to avoid c-ares IPv6/dual-stack name resolution issues
    table.insert(argv, "--async-dns=false")

    -- enable parallel download (multi-threaded)
    table.insert(argv, "--split=5")
    table.insert(argv, "--max-connection-per-server=4")
    table.insert(argv, "--min-split-size=1M")
    table.insert(argv, "--allow-overwrite=true")
    table.insert(argv, "--auto-file-renaming=false")

    -- set output directory and filename
    table.insert(argv, "--dir=" .. outputdir)
    table.insert(argv, "--out=" .. path.filename(outputfile))

    -- set url
    table.insert(argv, url)

    -- download it
    os.vrunv(tool.program, argv)
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

    -- add custom headers
    if opt.headers then
        for _, header in ipairs(opt.headers) do
            table.insert(argv, "-H")
            table.insert(argv, header)
        end
    end

    -- continue to download?
    if opt.continue then
        table.insert(argv, "-C")
        table.insert(argv, "-")
    end

    -- set timeout
    if opt.timeout then
        table.insert(argv, "--max-time")
        table.insert(argv, tostring(opt.timeout))
    end

    -- set read timeout
    if opt.read_timeout then
        table.insert(argv, "--speed-limit")
        table.insert(argv, "0")
        table.insert(argv, "--speed-time")
        table.insert(argv, tostring(opt.read_timeout))
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

    -- add custom headers
    if opt.headers then
        for _, header in ipairs(opt.headers) do
            table.insert(argv, "--header=" .. header)
        end
    end

    -- continue to download?
    if opt.continue then
        table.insert(argv, "-c")
    end

    -- set timeout
    if opt.timeout then
        table.insert(argv, "--timeout=" .. tostring(opt.timeout))
    end

    -- set read timeout
    if opt.read_timeout then
        table.insert(argv, "--read-timeout=" .. tostring(opt.read_timeout))
    end

    -- set outputfile
    table.insert(argv, "-O")
    table.insert(argv, outputfile)

    -- download it
    os.vrunv(tool.program, argv)
end

-- download url using powershell
-- e.g.
-- powershell -ExecutionPolicy Bypass -File "D:\scripts\download.ps1" "url" "outputfile"
function _powershell_download(tool, url, outputfile, opt)

    -- get the script file
    local scriptfile = path.join(os.programdir(), "scripts", "download.ps1")

    -- ensure output directory
    local outputdir = path.directory(outputfile)
    if not os.isdir(outputdir) then
        os.mkdir(outputdir)
    end

    -- download it
    local argv = {"-ExecutionPolicy", "Bypass", "-File", scriptfile, url, outputfile}
    os.vrunv(tool.program, argv)
end

-- downloaders mapping
local _DOWNLOADERS = {
    aria2 = _aria2_download,
    curl = _curl_download,
    wget = _wget_download,
    powershell = _powershell_download,
    pwsh = _powershell_download
}

-- find download tool by name
function _find_download_tool(name)
    if name == "powershell" then
        if is_host("windows") then
            return find_tool("pwsh") or find_tool("powershell")
        end
    elseif name == "pwsh" then
        return find_tool("pwsh")
    else
        return find_tool(name, {version = true})
    end
end

-- get candidate downloaders
function _get_downloaders(opt)
    local downloader = (opt and opt.downloader) or option.get("downloader") or global.get("downloader") or os.getenv("XMAKE_DOWNLOADER")
    if downloader and downloader ~= "" then
        if type(downloader) == "table" then
            if #downloader > 0 then
                return downloader
            end
        else
            local list = {}
            for _, name in ipairs(downloader:split(",", {plain = true})) do
                name = name:trim()
                if #name > 0 then
                    table.insert(list, name)
                end
            end
            if #list > 0 then
                return list
            end
        end
    end
    local candidates = {"aria2", "curl", "wget"}
    if is_host("windows") then
        table.insert(candidates, "powershell")
    end
    return candidates
end

-- download url with the first available tool (aria2/curl/wget/powershell) and fallback
function _download(url, outputfile, opt)

    local downloaders = _get_downloaders(opt)
    local tools = {}
    for _, name in ipairs(downloaders) do
        local tool = _find_download_tool(name)
        if tool then
            local download_fn = _DOWNLOADERS[name]
            if download_fn then
                table.insert(tools, {name = name, tool = tool, download = download_fn})
            end
        end
    end
    assert(#tools > 0, "no available download tool found (%s)!", table.concat(downloaders, ", "))

    local errors = {}
    for i, tool_info in ipairs(tools) do
        local ok = try
        {
            function ()
                tool_info.download(tool_info.tool, url, outputfile, opt)
                return true
            end,
            catch
            {
                function (errs)
                    table.insert(errors, string.format("%s: %s", tool_info.name, tostring(errs)))
                end
            }
        }
        if ok then
            return
        end

        -- clean up partial outputfile and aria2 control files before next attempt
        os.tryrm(outputfile)
        os.tryrm(outputfile .. ".aria2")

        -- fallback to next available tool
        local next_tool = tools[i + 1]
        if next_tool then
            wprint("downloading %s with %s failed, falling back to %s ..", url, tool_info.name, next_tool.name)
        end
    end

    raise(table.concat(errors, "\n"))
end

-- is it a ssl/tls certificate verification error?
function _is_ssl_cert_error(errors)
    errors = (errors or ""):lower()
    return errors:find("ssl", 1, true)
        or errors:find("tls", 1, true)
        or errors:find("certificate", 1, true)
        or errors:find("handshake", 1, true)
end

-- download url, and retry once with ssl verification disabled on a certificate error
function _download_fallback(url, outputfile, opt)
    local errors
    local ok = try
    {
        function ()
            _download(url, outputfile, opt)
            return true
        end,
        catch
        {
            function (errs)
                errors = tostring(errs)
            end
        }
    }
    if not ok then
        if _is_ssl_cert_error(errors) then
            wprint("download failed due to ssl certificate verification, retrying with ssl verification disabled ..")
            return _download(url, outputfile, table.join(opt, {insecure = true}))
        end
        raise(errors)
    end
end

-- download url
--
-- @param url           the input url
-- @param outputfile    the output file
-- @param opt           the option, e.g. {continue = true, insecure = false, insecure_fallback = false}
--
-- @note if opt.insecure_fallback is enabled and the download fails due to a ssl certificate
--       error, it will retry once with ssl verification disabled. this is only safe when the
--       caller verifies the downloaded file afterwards (e.g. by its sha256 checksum).
--
function main(url, outputfile, opt)

    -- init output file
    opt = opt or {}
    outputfile = outputfile or path.filename(url):gsub("%?.+$", "")

    -- download it directly if we do not need the insecure fallback
    if opt.insecure or not opt.insecure_fallback then
        return _download(url, outputfile, opt)
    end

    -- download it with the insecure fallback
    return _download_fallback(url, outputfile, opt)
end
