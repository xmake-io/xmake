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
-- @file        signal.lua
--

-- define module: signal
local signal = signal or {}

-- load modules
local os = require("base/os")

-- signal code
signal.SIGINT = 2

-- register signal handler
function signal.register(signo, handler)
    os.signal(signo, handler)
end

-- reset signal, SIGDFL
function signal.reset(signo)
    os.signal(signo, 1)
end

-- ignore signal, SIGIGN
function signal.ignore(signo)
    os.signal(signo, 2)
end

-- return module: signal
return signal
