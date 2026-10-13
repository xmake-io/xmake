# Xmake development conventions

This file guides coding agents working in this repository. Follow the user's task, keep changes focused, and follow the conventions of the surrounding code. Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing public APIs or preparing a contribution.

## Repository layout and execution environments

Xmake has a native C runtime, internal Lua modules, and sandboxed Lua scripts. These environments have different module and error-handling conventions. Identify the environment before editing a file; do not infer it solely from an imported module's name.

| Location | Purpose and conventions |
| --- | --- |
| `core/src/xmake/` | Native C implementation of the engine and Lua bindings. |
| `core/src/cli/` | Native command-line entry point. |
| `core/src/tbox/`, `core/src/lua/`, `core/src/luajit/`, and other bundled libraries | Dependencies and integration code. Avoid unrelated changes to upstream sources. |
| `xmake/core/` | Internal Lua implementation. Typically uses `require`, explicit module tables, and explicit return-value error handling. |
| `xmake/core/base/` | Base Lua APIs, including internal `os`, `io`, `table`, and process utilities. |
| `xmake/core/sandbox/modules/` | Implementation of sandbox built-ins and adapters. These files themselves use internal module conventions. |
| `xmake/core/sandbox/modules/import/` | Adapters exposed through sandbox `import`, including `core.base.*`, `core.project.*`, and `core.tool.*`. These adapters are loaded without a sandbox and use internal module conventions. |
| `xmake/modules/` | Sandboxed extension modules. This includes `private/`: private extension modules still use sandbox conventions. |
| `xmake/actions/`, `xmake/plugins/` | Built-in actions and plugins, generally implemented as sandbox scripts. |
| `xmake/rules/`, `xmake/toolchains/`, `xmake/platforms/`, `xmake/languages/`, `xmake/templates/`, `xmake/includes/` | Declarative definitions and their script callbacks. Match the existing scope and loading mechanism. |
| `tests/` | Lua regression tests and build-project fixtures. |

In a source checkout, `os.programdir()` points to the repository's `xmake/` directory when the source environment is configured. It does not point to the repository root or the user's project directory.

## Internal Lua modules

Internal modules use slash-separated `require` paths relative to `xmake/core/`. For example, `require("base/os")` loads `xmake/core/base/os.lua`, and `require("project/project")` loads `xmake/core/project/project.lua`.

Use an explicit module table, attach functions to it, and return it. Preserve existing instance/metatable patterns when extending a class-like module.

```lua
-- define module
local example = example or {}

-- load modules
local os = require("base/os")

-- copy a file
function example.copy(srcfile, dstfile)
    local ok, errors = os.cp(srcfile, dstfile)
    if not ok then
        return false, errors
    end
    return true
end

-- return module
return example
```

- Follow the actual API's return contract. Internal operations commonly return `ok, errors` or `result, errors`; do not replace these checks with sandbox-style assumptions.
- Internal `ipairs` and `pairs` do not generally have the sandbox's automatic nil/scalar normalization. Use `table.wrap(values)` when an API legitimately accepts nil, a scalar, or a list; omit it when the value is already guaranteed to be a list.
- Sandbox adapters bridge the two contracts: call the internal API, inspect its result, and raise on failure when that is the adapter's public contract. Such checks belong in the adapter, rather than being duplicated in every sandbox caller.
- Use the internal protected-call facilities, such as `utils.trycall`, where the surrounding implementation requires them. Do not assume sandbox `try`, `catch`, or `finally` are available as globals here.

## External sandbox modules and scripts

Sandbox extension modules use dot-separated `import` names. For example, `import("private.utils.target")` resolves to `xmake/modules/private/utils/target.lua` in the built-in extension directory. `import("core.base.task")` resolves to the sandbox adapter under `xmake/core/sandbox/modules/import/core/base/task.lua`, not directly to `xmake/core/base/task.lua`.

Custom modules can be resolved from the calling script's directory or an explicit `{rootdir = ...}`. Additional module directories and addons participate in lookup; see the loader before changing resolution behavior.

Define exported functions at the script's top level. Prefix private helpers with `_`. A `main` function makes an imported module callable. Do not convert a normal sandbox module into a `require`-style module table with a final `return`.

```lua
-- imports
import("core.base.task")

-- private helper
function _copy_files(files, outputdir)
    for _, file in ipairs(files) do
        os.cp(file, outputdir)
    end
end

-- module entry
function main(files, outputdir)
    _copy_files(files, outputdir)
    task.run("build")
end
```

- Sandbox built-ins such as `os`, `io`, `path`, `table`, `string`, `raise`, and `try` are already available. Do not `require("base/os")` to bypass the sandbox's API semantics.
- Use `{alias = "name"}` to resolve import naming conflicts. Use `{anonymous = true}` when only the returned module reference is needed. Use `{try = true}` only for an intentionally optional import.
- Sandbox `ipairs(values)` and `pairs(values)` accept nil and scalar values as well as tables. Prefer `ipairs(values)` over `ipairs(table.wrap(values))` for ordinary optional scalar/list inputs. Keep explicit wrapping when it changes semantics, such as a wrap-locked table, or when another API needs a concrete array.
- `table.wrap` is not forbidden: array indexing, length checks, mutation, and passing an array to a strict API may require it. Do not add or remove it mechanically.
- Default sandbox operations such as `os.cp`, `os.runv`, and `task.run` raise on failure. Call them directly; do not add `local ok, errors = ...; if not ok then raise(errors) end` around a raising API. Successful operations may return no value at all.
- Sandbox `os.iorunv` returns `stdout, stderr`, rather than the internal API's success flag followed by output. Nonempty stderr alone does not imply failure.
- Use `try`/`catch` only when recovery, fallback, or context is needed. Let ordinary failures propagate. Do not silently swallow an unexpected failure.
- The presence of `import("core....")` does not mean every function or returned object's method raises. Predicates, discovery functions, explicitly non-raising options such as `os.execv(..., {try = true})`, and some instance methods retain return-value contracts. Check the adapter and the underlying implementation when uncertain.

Use the project's block layout for exception handling:

```lua
try
{
    function ()
        os.runv(program, argv)
    end,
    catch
    {
        function (errors)
            -- Perform the required recovery, or add context and rethrow.
            raise(errors)
        end
    }
}
```

`try` returns the protected function's results on success and nil on failure; it is not an implicit boolean success test. If a caller needs a success boolean, explicitly return `true` from the protected function. A `finally` callback receives the protected call's success flag and results/error. Inspect the implementation before relying on cleanup ordering, especially when a catch handler itself raises.

## Lua style

- Use four spaces, never tabs. Match nearby formatting rather than reformatting unrelated code.
- Use descriptive names following existing conventions: `sourcefile`, `objectfile`, `targetfile`, `sourcekind`, `argv`, `opt`, and `errors`. Use `_` prefixes for private helpers; preserve established module/class names.
- Prefer double-quoted strings and `function ()` for anonymous callbacks. Use `..` for string concatenation and the existing `if`/`elseif`/`end` layout.
- Initialize optional option tables with `opt = opt or {}`. Avoid redundant checks for mandatory arguments or APIs guaranteed by this repository's supported runtime.
- Use existing helpers such as `path.join`, `path.absolute`, `table.join`, `table.join2`, and the extended string APIs before introducing replacements. `table.join` creates a result; `table.join2` appends to its first table. Check mutation/ownership before substituting one for the other.
- Use plain string matching when matching literal text, e.g. `value:find(text, 1, true)` or `value:split(separator, {plain = true})`. Escape user-controlled text when constructing a Lua pattern.
- Add English comments that explain constraints, non-obvious behavior, or why a workaround is necessary. Include an issue URL when it explains a regression or compatibility requirement. Avoid comments that merely repeat the statement.
- Distinguish the declarative scope in `xmake.lua` from script callbacks such as `on_load`, `on_config`, and `on_build`. Keep build-time operations in the appropriate callback; do not assume script-domain APIs are available in the description scope.

## Description-domain APIs and API design

The description domain declares configuration in `xmake.lua`; the script domain implements behavior in callbacks and imported modules. Keep that boundary explicit. Description APIs should record settings, relationships, and scripts without performing build work or eagerly loading the whole project. Read-only conditions used during declaration must respect the state available at that phase.

### Naming and call conventions

Follow the [description API specification](https://xmake.io/api/description/specification) and established neighboring APIs:

| Form | Intended contract |
| --- | --- |
| `target("name")`, `rule("name")`, `toolchain("name")`, etc. | Enter a named description scope. |
| `set_<property>(...)` | Set/override the property, including the interpreter's override semantics. |
| `add_<properties>(...)` | Append values using the property's existing ordering and deduplication behavior. |
| `remove_<properties>(...)` | Remove values where that API is supported; do not introduce new deprecated `del_*` forms. |
| `is_*` / `has_*` | Query a condition or availability; do not use these names for configuration mutation. |
| `on_<event>(...)` | Register the event's implementation callback. |
| `before_<event>(...)` / `after_<event>(...)` | Register callbacks around the corresponding operation. |

- Use plural property names for list-valued APIs accepting multiple entries, as in `add_files("src/*.c", "extra.cpp")`. Follow existing spelling rather than inventing a second name for the same concept.
- Keep the usual positional values followed by an optional named configuration table, e.g. `add_includedirs("include", {public = true})`. Avoid positional boolean switches and incompatible overloads when a named option expresses the behavior clearly.
- Define supported scalar/list forms, nil/default behavior, valid values, and return semantics explicitly. Do not assume all DSL APIs accept arbitrary Lua tables just because their syntax looks similar.
- Preserve the distinction between property values and per-item extra configuration. Read item metadata through `extraconf`/file configuration APIs rather than encoding metadata into value strings or keeping a parallel global table.
- Respect the scope: root defaults, target settings, rule settings, toolchain settings, and per-file overrides have different meanings. Do not expose a setting globally merely because a scoped implementation is less convenient.
- Honor established visibility/inheritance options such as `public` and `interface` where supported. They affect propagation to dependents, not just the current target. Preserve declaration order where link flags, libraries, or rule dependencies depend on it.
- File/directory properties must use the interpreter's path handling, including the declaring script's directory and existing variable expansion rules. A new path API must not resolve relative paths against an arbitrary current working directory.
- Do not add build outputs, compiler probes, repository updates, or package installation as hidden side effects of a declaration setter. Let the appropriate lifecycle stage consume the stored configuration.

### Extending an API end to end

Before introducing a new public API, follow the feature-request and design approval process in `CONTRIBUTING.md`. For an approved extension, trace a comparable existing property from declaration to its consumer and implement the complete path:

1. Choose the existing extension mechanism when it fits: a rule, an option, a namespaced `set_values` setting, or an established policy may avoid adding another global DSL function. If adding a policy, register its type/default/description in `xmake/core/project/policy.lua` rather than treating it as an arbitrary unchecked string.
2. Register a description API in the owning module's `apis()` table, such as `xmake/core/project/target.lua`, `rule.lua`, or `xmake/core/tool/toolchain.lua`. Inspect that scope's interpreter setup; registration in one interpreter does not imply availability in every definition loader.
3. Choose the proper registration category: `values`, `paths`, `keyvalues`, `dictionary`, `groups`, `script`, or `custom`, as applicable. Use `xmake/core/base/interpreter.lua` and the neighboring API as references. Prefer a standard category over custom parsing so source locations, extra configuration, override behavior, path translation, and scope handling remain consistent.
4. Add instance accessors or sandbox adapters only where needed. Preserve internal return-value contracts and sandbox raising contracts; do not expose raw internal APIs merely to make the new setting reachable.
5. Update the actual consumer. For compile/link properties, check language `nameflags` mappings, toolchain/target/file configuration merging, compiler flag translation, and project exporters where relevant. Merely storing a property does not make it influence compilation.
6. Include the new setting in relevant cache keys and rebuild dependency values if it changes output. Preserve correct invalidation when the setting changes between invocations or targets. Avoid rescanning every file to retrieve configuration already available on the instance.
7. Test declaration parsing and observable behavior, including the relevant defaults, set/add behavior, inheritance, per-file overrides, and configuration changes. Document supported scope, arguments, defaults, and a minimal example on the public documentation site.

Preserve backward compatibility when extending argument tables or callback signatures. Keep existing defaults unless a behavior change is explicitly intended. Use the project's deprecation mechanisms for an approved replacement; avoid adding compatibility branches for undocumented behavior without evidence that they are required.

## Configuration definitions and lifecycle

Definitions such as `rule`, `toolchain`, `platform`, `language`, `option`, `target`, and `task` use Xmake's declarative DSL, not ordinary module exports. Start the named scope at the outer indentation level and indent its settings and callbacks by four spaces. Follow nearby definitions for multiline tables and menus; do not normalize their layout as part of a functional change.

- Use `set_*` to define or replace a value and `add_*` to extend it. The instance equivalents are `instance:set(...)` and `instance:add(...)`. Choose deliberately: replacing a user's flags or appending the same defaults repeatedly changes behavior.
- Prefer semantic configuration (`defines`, `includedirs`, `links`, `languages`, etc.) to compiler-specific raw flags when an equivalent supported API exists. Restrict raw flags to the relevant tool/platform and compile/link stage.
- Keep definitions cheap to evaluate. Declarations may be loaded for configuration, project generation, queries, and other commands, not just compilation. Defer SDK searches, program execution, and build outputs to the appropriate callbacks.
- Keep state on the appropriate target, rule, or toolchain instance. Use namespaced `target:data_set("rule.name.key", value)` for transient rule state and established configuration APIs for persisted configuration. Do not store target-specific mutable state in module globals shared by multiple targets.

### Rules

- Put built-in definitions under `xmake/rules/<name>/xmake.lua`. Use existing hierarchical names such as `utils.*` or `platform.*` where appropriate, and compose behavior with `add_deps` instead of duplicating another rule's implementation.
- Use `set_extensions` for file-extension dispatch or `set_sourcekinds` for language source-kind dispatch, according to the rule's purpose. Do not scan every target source manually when source batches already provide the matching files.
- Keep short callbacks in the definition. Move substantial implementation into sibling sandbox modules and use the existing script reference or callback import pattern. Use `{rootdir = os.programdir()}` when importing a built-in implementation through a path such as `toolchains.clang.load`; do not confuse that path with an extension under `xmake/modules/`.
- Use `on_load` for early target setup and `after_load` when setup depends on the loaded target/dependency structure. Use `on_config` for configuration that must happen after configuration checks. Avoid requesting final compiler flags, packages, or toolchain state before they are available.
- Use build/link hooks for executing build work. `on_*` hooks can replace default work, while `before_*`/`after_*` hooks augment the corresponding stage; check the dispatch implementation before replacing a standard compilation/link action.
- Choose `on_build_file` for per-file work and `on_build_files` for source-batch work. When work can be represented as commands, consider `on_buildcmd_file(s)` and `batchcmds` to integrate with dependency tracking and project exporters.
- Register actual inputs, generated outputs, tool/flag values, and dependency-cache information with the existing `depend` or `batchcmds` APIs. Handle missing outputs and explicit rebuilds. A build hook does not automatically make a custom command incremental.
- Rule composition does not imply sequential execution of build jobs. Add `{order = true}` or job-graph dependencies only when a real producer/consumer relationship requires them. Preserve parallelism between independent files and targets.
- Generated sources/headers must be registered early enough for compilation and given collision-free output paths under the target's build directories. A basename alone is insufficient when different source directories contain equally named files.
- Do not add `{batch = true}`, `{jobgraph = true}`, or distribution support unless the callback implements that contract. Follow a comparable built-in rule and its scheduler integration.

Typical definition layout:

```lua
rule("example.defaults")
    on_config(function (target)
        if not target:get("warnings") then
            target:set("warnings", "all")
        end
    end)
```

### Toolchains and tool implementations

- Put definitions under `xmake/toolchains/<name>/xmake.lua`. Keep discovery/checking separate from loading flags and environments, commonly in sibling `check.lua` and `load.lua` sandbox modules.
- Declare `set_kind("standalone")` only for a complete standalone toolchain. Auxiliary toolchains should use the appropriate existing kind, rather than accidentally replacing the platform's primary compiler/linker selection.
- Declare tool roles with `set_toolset` (`cc`, `cxx`, `ld`, `sh`, `ar`, etc.). Candidate order expresses preference; preserve C++ linker/runtime requirements and cross-compilation prefixes. Reuse shared/versioned toolchain definitions rather than cloning them.
- Use `on_check` to discover availability with the existing `find_tool`, `find_program`, and SDK detection helpers. Return false/nil for an unavailable automatic candidate; raising there aborts configuration and can prevent fallback to other toolchains. Required tools/SDKs must still fail clearly when the selected target actually needs them.
- Keep `on_check`'s availability result explicit. Unlike ordinary raising sandbox operations, this callback has a meaningful return value consumed by toolchain selection.
- Store discovered paths/SDK metadata with `toolchain:config_set` when appropriate and read them during load. Respect user-specified SDK, bindir, compiler, environment, and architecture settings; do not rediscover or overwrite them without a reason.
- Use `on_load` to apply toolchain configuration, flags, and run environments. Prefer toolchain-scoped environment APIs to process-wide `os.setenv`; a project can contain multiple toolchains.
- Compiler flag translation and command construction normally belong under `xmake/modules/core/tools/`, with detection helpers under `xmake/modules/lib/detect/` and `xmake/modules/detect/`. Toolchain declarations select/configure tools; do not duplicate shared compiler-driver logic there.
- Preserve detection caches and avoid `{force = true}` or version probes unless fresh/version information is actually needed. Do not run the same tool/SDK probe once per source file.

### Platforms, languages, options, and tasks

- Platform definitions under `xmake/platforms/` declare target OS, supported hosts/architectures, output formats, menus, and toolchain candidates. Candidate order affects selection. Use target platform/architecture checks for output behavior and host checks for programs that run locally; cross compilation makes them different.
- Language definitions under `xmake/languages/` register source kinds/extensions, compile/link flag categories, target/tool kinds, mixing rules, and name-flag mappings. Keep these mappings consistent with the build rules and compiler tools when adding a language or configuration field.
- Use `option` definitions for user-facing feature configuration and existing policies for established build behavior. Define defaults, descriptions, dependencies, and menu visibility deliberately. An option with a default does not necessarily execute `on_check`; inspect the option lifecycle before adding detection there.
- Task/plugin definitions should declare their category, menu, and execution hook, with substantial work delegated to sandbox scripts. Avoid performing task work while its `xmake.lua` definition is being loaded.
- Package definitions and repository work must preserve the separation between host tools and target libraries, declared requirements, build configuration, and installation outputs. Reuse package/toolchain APIs rather than changing global project configuration for one package.

## License and file headers

Preserve existing license, copyright, and attribution headers. New production Lua/C files should copy the complete Apache 2.0 header from a nearby first-party file of the same kind. Update `@file` to the actual filename; use accurate author attribution rather than copying another author's identity. Test fixtures and small scripts may follow their directory's existing header convention.

The standard Lua header is:

```lua
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
-- @author      <actual author>
-- @file        example.lua
--
```

C files use the same full text in a `/*!A cross-platform ...` block with ` *` lines and a closing ` */`. Preserve the native source's section comments for `trace`, `includes`, `macros`, `types`, and `implementation` when applicable.

## Native C style and bindings

The root [.clang-format](.clang-format) is authoritative for first-party native code. The current style attaches opening braces to the preceding line, including functions, structs, and control statements; do not impose an older Allman layout.

```c
tb_int_t xm_os_example(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    tb_char_t const *value = luaL_checkstring(lua, 1);
    if (value) {
        lua_pushboolean(lua, tb_true);
    } else {
        lua_pushboolean(lua, tb_false);
    }
    return 1;
}
```

- Four-space indentation, no tabs, 120-column formatting limit, `} else {`, and no single-line function/control blocks. Preserve include order: the formatter does not sort includes.
- Use established Tbox types and constants, e.g. `tb_int_t`, `tb_size_t`, `tb_char_t const *`, `tb_bool_t`, `tb_true`, `tb_false`, and `tb_null`. Follow existing `xm_` function names and `XM_` guards/macros.
- Use the existing `prefix.h` hierarchy, platform macros, allocation helpers, assertions, and trace facilities instead of adding parallel abstractions.
- Validate Lua arguments with the appropriate Lua C API; keep stack pushes/pops and the declared number of returned values consistent. Preserve userdata ownership and resource cleanup on failure. A Lua error can bypass normal C cleanup; account for this before raising after allocation.
- Maintain supported Lua/LuaJIT and platform compatibility. Do not introduce a version-specific Lua API or OS API without following existing compatibility guards.
- Format only files/sections relevant to the task. Do not reformat bundled third-party code using the root configuration.

## Correctness, performance, and scope

- Fix the producer or the appropriate abstraction boundary when possible. Avoid compensating with repeated downstream filtering, output parsing, or duplicated validation.
- Build paths with `path` APIs and identify their base explicitly: script directory, project directory, program directory, or build directory. Prefer per-process `{curdir = ...}` to changing global cwd. Restore temporary environment/global-state changes on all supported exit paths.
- Prefer argument-vector process APIs (`os.runv`, `os.vrunv`, `os.iorunv`) to shell command concatenation. Avoid extra process launches and filesystem traversals in per-file/per-target hot paths when existing information suffices.
- Cache only with correct inputs and lifetime. Account for compiler, flags, configuration, dependencies, and mutation; do not trade incremental-build correctness for a benchmark improvement.
- Keep dependency ordering and rebuild invalidation distinct. Scheduling a dependency first does not automatically mean its output should invalidate every dependent build action.
- Preserve intentional user flags and cross-platform behavior. Avoid compiler/platform-specific assumptions in shared code.
- Keep changes limited to the requested issue. Do not delete unrelated tests, revert the user's edits, alter submodules, or stage/commit unrelated work.

Consider performance in every implementation, particularly in configuration loading, dependency scanning, flag construction, and job scheduling:

- Identify the work's frequency: per invocation, per configuration/toolchain, per target, per source file, or per dependency. Move invariant work to the narrowest reusable scope with a valid lifetime; do not turn a once-per-target operation into per-file work.
- Take cheap early exits before importing optional helpers, traversing dependencies, allocating large tables, or launching processes. Keep optional-feature work behind the corresponding policy/configuration check.
- Reuse existing source batches, ordered dependencies, resolved tools, and cached configuration rather than enumerating or rediscovering them. Avoid nested whole-project scans that turn linear work into quadratic work.
- Avoid unnecessary `table.wrap`, `table.clone`, repeated `table.join`, sorting, deduplication, and string/path transformations inside loops. Append to an owned result table where appropriate; do not mutate a cached/shared table merely to save an allocation.
- Cache repeated derived values when profiling or call frequency justifies it. Use the project's cache facilities and include all context that affects the result. Distinguish an unchecked value from a cached negative result; do not assume nil alone can represent both.
- Do not indefinitely cache mutable filesystem existence/mtime or tool results across stages that can change them. In particular, a compilation-stage timestamp cache may be invalid once build jobs produce new objects.
- Keep dependency checks ahead of command execution and progress output for skipped work. Avoid rewriting unchanged generated files, which can trigger unnecessary downstream compilation.
- Keep diagnostic formatting and expensive logging behind their verbosity/diagnosis conditions. Do not construct large messages in a hot loop only to discard them.
- Use the existing asynchronous process/scheduler interfaces for parallel build work. Avoid global cwd/environment mutation, blocking polling, and extra dependency edges that serialize independent jobs. A scheduler optimization must preserve readiness, completion, and error propagation.
- Prefer a simple change with a clear cost reduction over speculative micro-optimizations or a new cache layer. For performance claims, compare representative clean, no-op, and incremental builds as relevant, using the same compiler/configuration/job count and comparable cache state. Report measured results without implying a microbenchmark proves overall build speed.

## Development and verification

Use the checkout's Lua scripts and executable, not an installed copy. From the repository root on Linux/macOS:

```sh
source scripts/srcenv.profile
xmake --version
xmake lua tests/run.lua modules/path
```

The source environment sets both `XMAKE_PROGRAM_DIR` and `XMAKE_PROGRAM_FILE`. For noninteractive automation, use explicit environment variables and the actual built binary rather than relying on shell alias expansion:

```sh
XMAKE_PROGRAM_DIR="$PWD/xmake" XMAKE_PROGRAM_FILE="$PWD/build/xmake" \
    ./build/xmake lua tests/run.lua modules/path
```

The executable may instead be under `core/build/`; inspect the checkout. On Windows, use `scripts/srcenv.bat`. Lua-only edits usually need no rebuild; C edits require rebuilding the native executable. See `CONTRIBUTING.md` for `./configure && make` on Linux/macOS and building from `core/` with Xmake on Windows.

- Choose focused tests under `tests/modules/`, `tests/actions/`, `tests/plugins/`, or an appropriate build fixture. The runner discovers `test.lua` files and exported `test_*` functions; follow nearby tests using the supplied test context.
- For a bug fix, prefer a regression test that fails before the fix and checks observable behavior. For build changes, verify the affected full/incremental builds and relevant invalidation cases rather than only comparing generated strings.
- Skip platform/toolchain-specific cases explicitly when unavailable. Report what actually ran, what was skipped, and any remaining validation limit; do not claim native Windows/MSVC or a particular Clang version was tested through mocks.
- Review the final diff for unrelated changes and whitespace errors. Do not run the entire test suite repeatedly when focused checks already cover an unchanged patch.
- Contributions target `dev` according to `CONTRIBUTING.md`; commit messages must be in English. Public API additions/changes require the feature-request/design process described there. Existing task authorization does not require repeated approval for routine implementation work.

## Reference sources

Use current source as the final authority when documentation examples differ from the implementation.

- [Contribution and development guide](CONTRIBUTING.md)
- [Sandbox module loader](xmake/core/sandbox/modules/import/core/sandbox/module.lua)
- [Sandbox iteration](xmake/core/sandbox/modules/ipairs.lua) and [base table helpers](xmake/core/base/table.lua)
- [Sandbox OS adapter](xmake/core/sandbox/modules/os.lua) and [task adapter](xmake/core/sandbox/modules/import/core/base/task.lua)
- [Sandbox exception handling](xmake/core/sandbox/modules/try.lua)
- [Native formatting configuration](.clang-format)
- API implementation references: [description interpreter](xmake/core/base/interpreter.lua), [target APIs](xmake/core/project/target.lua), [project interpreter setup](xmake/core/project/project.lua), and [policy registry](xmake/core/project/policy.lua).
- Definition examples: [C/C++ rules](xmake/rules/c++/xmake.lua), [Clang toolchain](xmake/toolchains/clang/xmake.lua), [Linux platform](xmake/platforms/linux/xmake.lua), and [C++ language](xmake/languages/c++/xmake.lua).
- Public documentation: [description API specification](https://xmake.io/api/description/specification), [custom rules](https://xmake.io/api/description/custom-rule), [custom toolchains](https://xmake.io/api/description/custom-toolchain), [configuration options](https://xmake.io/api/description/configuration-option), and [built-in policies](https://xmake.io/api/description/builtin-policies).
- Sandbox documentation: [import](https://xmake.io/api/scripts/builtin-modules/import), [try/catch/finally](https://xmake.io/api/scripts/builtin-modules/try-catch-finally), and [plugin development](https://xmake.io/guide/extensions/plugin-development).
- [Xmake Skills](https://github.com/xmake-io/xmake-skills) provides optional, focused guidance for agents using Xmake. Consult the relevant skill when useful; it is not a required local checkout or dependency of this repository. Match its examples to the current source and this repository's development conventions.

Use repository-relative links for files in this checkout and public URLs for external documentation and skills. Do not assume a developer's absolute paths or sibling repositories are available to other contributors.
