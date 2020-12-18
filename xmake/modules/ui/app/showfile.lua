--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, showfile 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
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
-- @file        showfile.lua
--

-- imports
import("core.ui.log")
import("core.ui.rect")
import("core.ui.event")
import("core.ui.textdialog")
import("core.ui.application")

-- the application
local app = application()

-- init app
function app:init(argv)

    -- init name
    application.init(self, "app", argv)

    -- init background
    self:background_set("blue")

    -- get file
    local file = argv[1]

    -- read file content
    local content = nil
    if file then
        content = os.isfile(file) and io.readfile(file) or nil
    else
        content = "please input file path!"
    end

    -- init main dialog
    local dialog_main = textdialog:new("dialog.main", rect {1, 1, self:width() - 1, self:height() - 1}, "showfile: " .. (file and path.filename(file) or ""))
    dialog_main:text():text_set(content or string.format("cannot read file(%s)!", file))
    dialog_main:button_add("exit", "< Exit >", function (v) self:quit() end)
    self:insert(dialog_main)
end

-- main entry
function main(...)
    app:run(...)
end
