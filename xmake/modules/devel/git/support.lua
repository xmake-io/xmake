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
-- @file        support.lua
--

-- imports
import("core.base.option")
import("core.base.semver")
import("lib.detect.find_tool")

-- Locate this repository's metadata without discovering a parent repository (#7793).
-- @see https://github.com/xmake-io/xmake/issues/7793
function repository_gitdir(repodir)
    if not os.isdir(repodir) then
        return
    end
    repodir = path.absolute(repodir)
    local gitdir = path.join(repodir, ".git")
    -- Git itself resolves .git files used by worktrees/submodules and rejects damaged metadata.
    if os.isfile(gitdir) or os.isfile(path.join(gitdir, "HEAD")) then
        return gitdir
    end
    -- Bare repositories store their metadata directly in repodir.
    if os.isfile(path.join(repodir, "HEAD")) and os.isdir(path.join(repodir, "objects")) and os.isdir(path.join(repodir, "refs")) then
        return repodir
    end
end

-- Guard modifying commands when a repository directory is explicitly supplied.
function init_argv(argv, opt)
    local repodir = opt and opt.repodir
    if not repodir then
        return
    end
    repodir = path.absolute(repodir)
    local gitdir = repository_gitdir(repodir)
    assert(gitdir, "invalid Git repository directory: %s", repodir)
    -- Let Git enforce the directory change as well as the subprocess curdir option.
    -- Explicit metadata also prevents ancestor discovery if the contents are damaged.
    table.insert(argv, "-C")
    table.insert(argv, repodir)
    table.insert(argv, "--git-dir=" .. gitdir)
end

-- get git version
function _git_version()
    local git_version = _g.git_version
    if git_version == nil then
        local git = assert(find_tool("git", {version = true}), "git not found!")
        if git.version then
            git_version = git.version
        end
        _g.git_version = git_version or false
    end
    return git_version or nil
end

-- can clone tag?
-- @see https://github.com/xmake-io/xmake/issues/4151
function can_clone_tag()
    local can = _g.can_clone_tag
    if can == nil then
        local git_version = _git_version()
        if git_version and semver.compare(git_version, "1.7.10") >= 0 then
            can = true
        end
        _g.can_clone_tag = can or false
    end
    return can or false
end

-- can clone with --shallow-submodules?
-- @see https://github.com/xmake-io/xmake/issues/4151
function can_shallow_submodules()
    local can = _g.can_shallow_submodules
    if can == nil then
        local git_version = _git_version()
        if git_version and semver.compare(git_version, "2.9.0") >= 0 then
            can = true
        end
        _g.can_shallow_submodules = can or false
    end
    return can or false
end

-- can clone with --filter=tree:0?
-- @see https://github.com/xmake-io/xmake/issues/6246
function can_treeless()
    local can = _g.can_treeless
    if can == nil then
        local git_version = _git_version()
        if git_version and semver.compare(git_version, "2.16.0") >= 0 then
            can = true
        end
        _g.can_treeless = can or false
    end
    return can or false
end

-- can sparse checkout?
-- @see https://github.com/xmake-io/xmake/issues/6071
-- https://github.blog/open-source/git/bring-your-monorepo-down-to-size-with-sparse-checkout/
function can_sparse_checkout()
    local can = _g.can_sparse_checkout
    if can == nil then
        local git_version = _git_version()
        if git_version and semver.compare(git_version, "2.25.0") >= 0 then
            can = true
        end
        _g.can_sparse_checkout = can or false
    end
    return can or false
end
