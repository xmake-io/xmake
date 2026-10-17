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
-- @file        xmake.lua
--

-- User Configs:
--
-- The following `csharp.*` values can be set via `set_values()` in xmake.lua
-- to customize the auto-generated .csproj file.
--
-- e.g.
--   target("example")
--       add_rules("csharp")
--       add_files("src/*.cs")
--       set_values("csharp.target_framework", "net8.0")
--       set_values("csharp.nullable", "disable")
--       set_values("csharp.allow_unsafe_blocks", "true")
--
-- Project:
--   csharp.sdk                                          - Project Sdk (default: Microsoft.NET.Sdk)
--
-- General:
--   csharp.target_framework                             - e.g. "net8.0", auto-detected from dotnet sdk if not set
--   csharp.target_frameworks                            - multi-target, e.g. {"net8.0", "net9.0"} (list, semicolon-joined)
--   csharp.implicit_usings                              - ImplicitUsings (default: "enable")
--   csharp.nullable                                     - Nullable (default: "enable")
--   csharp.lang_version                                 - LangVersion, e.g. "12.0", "latest"
--   csharp.root_namespace                               - RootNamespace
--   csharp.enable_default_compile_items                 - EnableDefaultCompileItems (default: "false")
--   csharp.enable_default_embedded_resource_items       - EnableDefaultEmbeddedResourceItems
--   csharp.enable_default_none_items                    - EnableDefaultNoneItems
--
-- Build:
--   csharp.generate_assembly_info                       - GenerateAssemblyInfo
--   csharp.deterministic                                - Deterministic
--   csharp.prefer_32bit                                 - Prefer32Bit
--   csharp.allow_unsafe_blocks                          - AllowUnsafeBlocks
--   csharp.check_for_overflow_underflow                 - CheckForOverflowUnderflow
--
-- Analysis:
--   csharp.analysis_level                               - AnalysisLevel
--   csharp.enable_net_analyzers                         - EnableNETAnalyzers
--   csharp.enforce_code_style_in_build                  - EnforceCodeStyleInBuild
--   csharp.warnings_as_errors                           - WarningsAsErrors (list)
--   csharp.warnings_not_as_errors                       - WarningsNotAsErrors (list)
--   csharp.error_log                                    - ErrorLog
--   csharp.generate_documentation_file                  - GenerateDocumentationFile
--   csharp.documentation_file                           - DocumentationFile
--
-- Publish/Runtime:
--   csharp.runtime_identifier                           - RuntimeIdentifier, e.g. "win-x64"
--   csharp.runtime_identifiers                          - RuntimeIdentifiers (list)
--   csharp.self_contained                               - SelfContained
--   csharp.use_app_host                                 - UseAppHost
--   csharp.roll_forward                                 - RollForward
--   csharp.publish_single_file                          - PublishSingleFile
--   csharp.publish_trimmed                              - PublishTrimmed
--   csharp.trim_mode                                    - TrimMode
--   csharp.publish_ready_to_run                         - PublishReadyToRun
--   csharp.invariant_globalization                      - InvariantGlobalization
--   csharp.include_native_libraries_for_self_extract    - IncludeNativeLibrariesForSelfExtract
--   csharp.enable_compression_in_single_file            - EnableCompressionInSingleFile
--   csharp.publish_aot                                  - PublishAot
--   csharp.strip_symbols                                - StripSymbols
--   csharp.enable_trim_analyzer                         - EnableTrimAnalyzer
--   csharp.json_serializer_is_reflection_enabled_by_default - JsonSerializerIsReflectionEnabledByDefault
--   csharp.satellite_resource_languages                 - SatelliteResourceLanguages (list)
--
-- Package Info:
--   csharp.version                                      - Version
--   csharp.assembly_version                             - AssemblyVersion
--   csharp.file_version                                 - FileVersion
--   csharp.informational_version                        - InformationalVersion
--   csharp.package_id                                   - PackageId
--   csharp.authors                                      - Authors
--   csharp.company                                      - Company
--   csharp.product                                      - Product
--   csharp.description                                  - Description
--   csharp.copyright                                    - Copyright
--   csharp.repository_url                               - RepositoryUrl
--   csharp.repository_type                              - RepositoryType
--   csharp.package_license_expression                   - PackageLicenseExpression
--   csharp.package_project_url                          - PackageProjectUrl
--   csharp.neutral_language                             - NeutralLanguage
--   csharp.enable_preview_features                      - EnablePreviewFeatures
--
-- Output:
--   csharp.generate_runtime_configuration_files         - GenerateRuntimeConfigurationFiles
--   csharp.copy_local_lock_file_assemblies              - CopyLocalLockFileAssemblies
--   csharp.append_target_framework_to_output_path       - AppendTargetFrameworkToOutputPath (default: "false")
--   csharp.append_runtime_identifier_to_output_path     - AppendRuntimeIdentifierToOutputPath (default: "false")
--   csharp.produce_reference_assembly                   - ProduceReferenceAssembly
--   csharp.disable_implicit_framework_references        - DisableImplicitFrameworkReferences
--   csharp.generate_target_framework_attribute          - GenerateTargetFrameworkAttribute
--
-- References:
--   csharp.references                                   - add <Reference> entries with HintPath, for prebuilt/external
--                                                         assemblies that aren't NuGet packages or other xmake targets
--                                                         (list), e.g. set_values("csharp.references", "path/to/Foo.dll")
--
-- Custom Properties (for arbitrary csproj properties not listed above):
--   csharp.properties                                   - add custom <PropertyGroup> entries, format: "Name=Value"
--                                                         e.g. set_values("csharp.properties", "MyProp=value", "AnotherProp=value2")
--
rule("csharp.build")
    set_sourcekinds("cs")
    on_load(function (target)
        -- dotnet always outputs .dll for libraries, and no prefix
        if target:is_shared() or target:is_static() then
            target:set("prefixname", "")
            target:set("extension", ".dll")
        end
    end)
    on_config("config")
    on_build("build")
    on_install("install")
    on_installcmd("installcmd")

rule("csharp")
    add_deps("csharp.build")
    add_deps("utils.inherit.links")
