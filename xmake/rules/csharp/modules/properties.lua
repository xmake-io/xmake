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
-- @author      JassJam
-- @file        properties.lua
--

function _has_target_frameworks(context)
    return #table.wrap(context.target:values("csharp.target_frameworks")) > 0
end

local _default_target_framework_cached = {}

function _first(value)
    if type(value) == "table" then
        return value[1]
    end
    return value
end

function _get_target_value(target, name)
    return _first(target:values(name))
end

function _collect_strings(result, value)
    if value == nil then
        return
    end
    if type(value) == "table" then
        for _, item in ipairs(value) do
            _collect_strings(result, item)
        end
    else
        local sval = tostring(value)
        if #sval > 0 then
            table.insert(result, sval)
        end
    end
end

function _extract_define_symbol(define)
    define = tostring(define):trim()
    if #define == 0 then
        return nil
    end
    local symbol = define:split("=", {plain = true})[1]
    if not symbol then
        return nil
    end
    symbol = symbol:trim()
    if symbol:match("^[A-Za-z_][A-Za-z0-9_]*$") then
        return symbol
    end
    return nil
end

function _resolve_define_constants(context)
    local target = context.target
    local constants = {}

    _collect_strings(constants, target:get("defines"))
    local opt_defines = target:get_from("defines", "option::*")
    if opt_defines then
        _collect_strings(constants, opt_defines)
    end

    local symbols = {}
    for _, define in ipairs(constants) do
        local symbol = _extract_define_symbol(define)
        if symbol then
            table.insert(symbols, symbol)
        end
    end
    symbols = table.unique(symbols)
    if #symbols > 0 then
        return table.concat(symbols, ";")
    end
end

function _get_default_target_framework(context)
    local dotnet = _first(context.target:get("toolset.cs")) or "dotnet"
    dotnet = tostring(dotnet)
    local cached = _default_target_framework_cached[dotnet]
    if cached ~= nil then
        return cached
    end

    local major = nil
    local sdks = try { function ()
        return os.iorunv(dotnet, {"--list-sdks"})
    end }
    if sdks then
        for line in sdks:gmatch("[^\r\n]+") do
            local line_major = tonumber(line:match("^%s*(%d+)%.%d+%.%d+"))
            if line_major and (not major or line_major > major) then
                major = line_major
            end
        end
    end
    if not major then
        local version = try { function ()
            return os.iorunv(dotnet, {"--version"})
        end }
        if version then
            major = tonumber(version:match("^%s*(%d+)"))
        end
    end

    local target_framework = major and ("net" .. tostring(major) .. ".0") or "net8.0"
    _default_target_framework_cached[dotnet] = target_framework
    return target_framework
end

function _resolve_target_framework(context)
    local target_framework = _get_target_value(context.target, "csharp.target_framework")
    if target_framework ~= nil and #tostring(target_framework) > 0 then
        return target_framework
    end
    return _get_default_target_framework(context)
end

function _resolve_assembly_name(context)
    local basename = context.target:basename()
    if basename ~= nil and #tostring(basename) > 0 then
        return basename
    end
end

function _resolve_optimize(context)
    local optimize = _first(context.target:get("optimize"))
    if optimize ~= nil then
        return optimize == "none" and "false" or "true"
    end
end

function _resolve_debug_symbols(context)
    local symbols = _first(context.target:get("symbols"))
    if symbols ~= nil then
        return symbols == "none" and "false" or "true"
    end
end

function _resolve_debug_type(context)
    local symbols = _first(context.target:get("symbols"))
    if symbols and symbols ~= "none" then
        return "portable"
    end
end

function _resolve_platform_target(context)
    local arch = (context.target:arch() or ""):lower()
    local mapping = {
        x86_64 = "x64",
        amd64 = "x64",
        x64 = "x64",
        i386 = "x86",
        x86 = "x86",
        arm64 = "arm64",
        arm = "arm",
        armv7 = "arm"
    }
    return mapping[arch]
end

function _resolve_warning_level(context)
    local warnings = _first(context.target:get("warnings"))
    local mapping = {
        none = "0",
        less = "2",
        more = "3",
        all = "4",
        allextra = "4",
        everything = "4",
        error = "4"
    }
    return warnings and mapping[warnings]
end

function _resolve_treat_warnings_as_errors(context)
    local warnings = _first(context.target:get("warnings"))
    if warnings == "error" then
        return "true"
    end
end

function _register_property(register, suffix, xml, default, extra)
    local entry = table.join({
        kind = "property",
        xml = xml,
        lua_key = "csharp." .. suffix,
        default = default
    }, extra or {})
    register(entry)
end

function _register_list_property(register, suffix, xml, extra)
    local entry = table.join({
        kind = "property",
        xml = xml,
        lua_key = "csharp." .. suffix,
        value_type = "list",
        sep = ";"
    }, extra or {})
    register(entry)
end

function main()
    local entries = {}
    function register(entry)
        table.insert(entries, entry)
    end

    register({kind = "project_attribute", attr = "Sdk", lua_key = "csharp.sdk", default = "Microsoft.NET.Sdk"})
    register({kind = "property", xml = "OutputType", resolve = function (context)
        return context.target:is_binary() and "Exe" or "Library"
    end})
    _register_list_property(register, "target_frameworks", "TargetFrameworks", {when = _has_target_frameworks})
    register({kind = "property", xml = "TargetFramework", resolve = _resolve_target_framework, when = function (context)
        return not _has_target_frameworks(context)
    end})

    _register_property(register, "implicit_usings", "ImplicitUsings", "enable")
    _register_property(register, "nullable", "Nullable", "enable")
    _register_property(register, "lang_version", "LangVersion")
    _register_property(register, "enable_default_compile_items", "EnableDefaultCompileItems", "false")
    _register_property(register, "enable_default_embedded_resource_items", "EnableDefaultEmbeddedResourceItems")
    _register_property(register, "enable_default_none_items", "EnableDefaultNoneItems")
    _register_property(register, "root_namespace", "RootNamespace")
    register({kind = "property", xml = "AssemblyName", resolve = _resolve_assembly_name})
    _register_property(register, "generate_assembly_info", "GenerateAssemblyInfo")
    _register_property(register, "deterministic", "Deterministic")
    register({kind = "property", xml = "Optimize", resolve = _resolve_optimize})
    register({kind = "property", xml = "PlatformTarget", resolve = _resolve_platform_target})
    _register_property(register, "prefer_32bit", "Prefer32Bit")
    _register_property(register, "allow_unsafe_blocks", "AllowUnsafeBlocks")
    _register_property(register, "check_for_overflow_underflow", "CheckForOverflowUnderflow")
    register({kind = "property", xml = "WarningLevel", resolve = _resolve_warning_level})
    _register_property(register, "analysis_level", "AnalysisLevel")
    _register_property(register, "enable_net_analyzers", "EnableNETAnalyzers")
    _register_property(register, "enforce_code_style_in_build", "EnforceCodeStyleInBuild")
    register({kind = "property", xml = "TreatWarningsAsErrors", resolve = _resolve_treat_warnings_as_errors})
    _register_list_property(register, "warnings_as_errors", "WarningsAsErrors")
    _register_list_property(register, "warnings_not_as_errors", "WarningsNotAsErrors")
    register({kind = "property", xml = "DefineConstants", resolve = _resolve_define_constants})
    _register_property(register, "error_log", "ErrorLog")
    register({kind = "property", xml = "DebugType", resolve = _resolve_debug_type})
    register({kind = "property", xml = "DebugSymbols", resolve = _resolve_debug_symbols})
    _register_property(register, "generate_documentation_file", "GenerateDocumentationFile")
    _register_property(register, "documentation_file", "DocumentationFile")

    _register_property(register, "runtime_identifier", "RuntimeIdentifier")
    _register_list_property(register, "runtime_identifiers", "RuntimeIdentifiers")
    _register_property(register, "self_contained", "SelfContained")
    _register_property(register, "use_app_host", "UseAppHost")
    _register_property(register, "roll_forward", "RollForward")
    _register_property(register, "publish_single_file", "PublishSingleFile")
    _register_property(register, "publish_trimmed", "PublishTrimmed")
    _register_property(register, "trim_mode", "TrimMode")
    _register_property(register, "publish_ready_to_run", "PublishReadyToRun")
    _register_property(register, "invariant_globalization", "InvariantGlobalization")
    _register_property(register, "include_native_libraries_for_self_extract", "IncludeNativeLibrariesForSelfExtract")
    _register_property(register, "enable_compression_in_single_file", "EnableCompressionInSingleFile")
    _register_property(register, "publish_aot", "PublishAot")
    _register_property(register, "strip_symbols", "StripSymbols")
    _register_property(register, "enable_trim_analyzer", "EnableTrimAnalyzer")
    _register_property(register, "json_serializer_is_reflection_enabled_by_default", "JsonSerializerIsReflectionEnabledByDefault")
    _register_list_property(register, "satellite_resource_languages", "SatelliteResourceLanguages")

    _register_property(register, "version", "Version")
    _register_property(register, "assembly_version", "AssemblyVersion")
    _register_property(register, "file_version", "FileVersion")
    _register_property(register, "informational_version", "InformationalVersion")
    _register_property(register, "package_id", "PackageId")
    _register_property(register, "authors", "Authors")
    _register_property(register, "company", "Company")
    _register_property(register, "product", "Product")
    _register_property(register, "description", "Description")
    _register_property(register, "copyright", "Copyright")
    _register_property(register, "repository_url", "RepositoryUrl")
    _register_property(register, "repository_type", "RepositoryType")
    _register_property(register, "package_license_expression", "PackageLicenseExpression")
    _register_property(register, "package_project_url", "PackageProjectUrl")
    _register_property(register, "neutral_language", "NeutralLanguage")
    _register_property(register, "enable_preview_features", "EnablePreviewFeatures")

    _register_property(register, "generate_runtime_configuration_files", "GenerateRuntimeConfigurationFiles")
    _register_property(register, "copy_local_lock_file_assemblies", "CopyLocalLockFileAssemblies")
    _register_property(register, "append_target_framework_to_output_path", "AppendTargetFrameworkToOutputPath", "false")
    _register_property(register, "append_runtime_identifier_to_output_path", "AppendRuntimeIdentifierToOutputPath", "false")
    _register_property(register, "produce_reference_assembly", "ProduceReferenceAssembly")
    _register_property(register, "disable_implicit_framework_references", "DisableImplicitFrameworkReferences")
    _register_property(register, "generate_target_framework_attribute", "GenerateTargetFrameworkAttribute")
    return entries
end
