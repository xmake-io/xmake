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
-- @file        codesign.lua
--

-- imports
import("lib.detect.find_tool")
import("core.cache.global_detectcache")

-- get mobile provision name
function _get_mobile_provision_name(provision)
    local p = provision:find("<key>Name</key>", 1, true)
    if p then
        local e = provision:find("</string>", p, true)
        if e then
            return provision:sub(p, e + 9):match("<string>(.*)</string>")
        end
    end
end

-- get mobile provision entitlements
function _get_mobile_provision_entitlements(provision)
    local p = provision:find("<key>Entitlements</key>", 1, true)
    if p then
        local e = provision:find("</dict>", p, true)
        if e then
            return provision:sub(p, e + 7):match("(<dict>.*</dict>)")
        end
    end
end

-- get codesign identities
function codesign_identities()
    local identities = global_detectcache:get2("codesign", "identities")
    local lastime = global_detectcache:get2("codesign", "lastime")
    if type(lastime) == "number" and os.time() - lastime > 3 * 24 * 3600 then -- > 3 days
        identities = nil
    end
    if identities == nil then
        identities = {}
        local results = try { function() return os.iorun("/usr/bin/security find-identity") end }
        if results then
            local splitinfo = results:split("Valid identities only", {plain = true})
            if splitinfo and #splitinfo > 1 then
                results = splitinfo[2]
            end
        end
        if not results then
            -- it may be slower
            results = try { function() return os.iorun("/usr/bin/security find-identity -v -p codesigning") end }
        end
        if results then
            for _, line in ipairs(results:split('\n', {plain = true})) do
                local sign, identity = line:match("%) (%w+) \"(.+)\"")
                if sign and identity then
                    identities[identity] = sign
                end
            end
        end
        global_detectcache:set2("codesign", "identities", identities or false)
        global_detectcache:set2("codesign", "lastime", os.time())
        global_detectcache:save()
    end
    return identities or nil
end

-- get provision profiles only for mobile
function mobile_provisions()
    local mobile_provisions = global_detectcache:get2("codesign", "mobile_provisions")
    local lastime = global_detectcache:get2("codesign", "lastime")
    if type(lastime) == "number" and os.time() - lastime > 3 * 24 * 3600 then -- > 3 days
        mobile_provisions = nil
    end
    if mobile_provisions == nil then
        mobile_provisions = {}
        local files = os.files("~/Library/MobileDevice/Provisioning Profiles/*.mobileprovision")
        for _, file in ipairs(files) do
            local results = try { function() return os.iorunv("/usr/bin/security", {"cms", "-D", "-i", file}) end }
            if results then
                local name = _get_mobile_provision_name(results)
                if name then
                    mobile_provisions[name] = results
                end
            end
        end
        global_detectcache:set2("codesign", "mobile_provisions", mobile_provisions or false)
        global_detectcache:set2("codesign", "lastime", os.time())
        global_detectcache:save()
    end
    return mobile_provisions or nil
end

-- dump all information of codesign
function dump()

    -- only for macosx
    assert(is_host("macosx"), "codesign: only support for macOS!")

    -- do dump
    print("==================================== codesign identities ====================================")
    print(codesign_identities())
    print("===================================== mobile provisions =====================================")
    print(mobile_provisions())
end

-- remove signature
function unsign(programdir)

    -- only for macosx
    assert(is_host("macosx"), "codesign: only support for macOS!")

    -- get codesign
    local codesign = find_tool("codesign")
    if not codesign then
        return
    end

    -- remove signature
    os.vrunv(codesign.program, {"--remove-signature", programdir})
end

-- main entry
function main (programdir, codesign_identity, mobile_provision, opt)

    -- only for macosx
    opt = opt or {}
    assert(is_host("macosx"), "codesign: only support for macOS!")

    -- get codesign
    local codesign = find_tool("codesign")
    if not codesign then
        return
    end

    -- get codesign_allocate
    local codesign_allocate
    local xcode_sdkdir = get_config("xcode")
    if xcode_sdkdir then
        codesign_allocate = path.join(xcode_sdkdir, "Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/codesign_allocate")
    end

    -- get codesign
    local sign = "-"
    if codesign_identity then -- we will uses sign/'-' if be false for `xmake f --xcode_codesign_identity=n`
        local identities = codesign_identities()
        if identities then
            sign = identities[codesign_identity]
            assert(sign, "codesign: invalid sign identity(%s)!", codesign_identity)
        end
    end

    -- get entitlements for mobile
    local entitlements
    if codesign_identity and mobile_provision then
        local provisions = mobile_provisions()
        if provisions then
            mobile_provision = provisions[mobile_provision]
            if mobile_provision then
                local entitlements_data = _get_mobile_provision_entitlements(mobile_provision)
                if entitlements_data then
                    entitlements = os.tmpfile() .. ".plist"
                    io.writefile(entitlements, string.format([[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
%s
</plist>
]], entitlements_data))
                end
            end
        end
    end

    -- do sign
    local argv = {"--force", "--timestamp=none"}
    if opt.deep then
        table.insert(argv, "--deep")
    end
    table.insert(argv, "--sign")
    table.insert(argv, sign)
    if entitlements then
        table.insert(argv, "--entitlements")
        table.insert(argv, entitlements)
    end
    table.insert(argv, programdir)
    os.vrunv(codesign.program, argv, {envs = {CODESIGN_ALLOCATE = codesign_allocate}})
    if entitlements then
        os.tryrm(entitlements)
    end
end

