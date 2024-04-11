---
isapi: false
key: exceptions_intro
name: try-catch-finally
page: api/builtin_modules/exceptions.html
---

## ${anchor:exceptions_intro}

### Exception capture

Lua native does not provide try-catch syntax to catch exception handling, but provides interfaces such as `pcall/xpcall` to execute lua functions in protected mode.

Therefore, the capture mechanism of the try-catch block can be implemented by encapsulating these two interfaces.

We can look at the packaged try-catch usage first:

```lua
${link:try}
{
    -- try code block
    function ()
        error("error message")
    end,

    -- catch code block
    ${link:catch}
    {
        -- After an exception occurs, it is executed
        function (errors)
            ${link:print}(errors)
        end
    }
}
```

In the above code, an exception is thrown inside the try block, and an error message is thrown, caught in the catch, and the error message is output.

And finally processing, this role is for the `try{}` code block, regardless of whether the execution is successful, will be executed into the finally block

In other words, in fact, the above implementation, the complete support syntax is: `try-catch-finally` mode, where catch and finally are optional, according to their actual needs.

E.g:

```lua
${link:try}
{
    -- try code block
    function ()
        error("error message")
    end,

    -- catch code block
    ${link:catch}
    {
        -- After an exception occurs, it is executed
        function (errors)
            print(errors)
        end
    },

    -- finally block
    ${link:finally}
    {
        -- Finally will be executed here
        function (ok, errors)
            -- If there is an exception in try{}, ok is true, errors is the error message, otherwise it is false, and error is the return value in try
        end
    }
}

```

Or only the finally block:

```lua
${link:try}
{
    -- try code block
    function ()
        return "info"
    end,

    -- finally block
    ${link:finally}
    {
        -- Since there is no exception in this try code, ok is true and errors is the return value: "info"
        function (ok, errors)
        end
    }
}
```

Processing can get the normal return value in try in finally, in fact, in the case of only try, you can also get the return value:

```lua
-- If no exception occurs, result is the return value: "xxxx", otherwise nil
local result = ${link:try}
{
    function ()
        return "xxxx"
    end
}
```

In xmake's custom scripting and plugin development, it is also based entirely on this exception catching mechanism.

This makes the development of the extended script very succinct and readable, eliminating the cumbersome `if err ~= nil then` return value judgment. When an error occurs, xmake will directly throw an exception to interrupt, and then highlight the detailed error. information.

E.g:

```lua
${link:target}("test")
    ${link:set_kind}("binary")
    ${link:add_files}("src/*.c")

    -- After the ios program is compiled, the target program is ldid signed
    ${link:after_build}(function (target))
        os.run("ldid -S %s", target:targetfile())
    end
```

Only one line `os.run` is needed, and there is no need to return a value to determine whether it runs successfully. After the operation fails, xmake will automatically throw an exception, interrupt the program and prompt the error.

If you want to run xmake without running interrupts directly after running, you can do it yourself.Add a try and you will be fine:

```lua
${link:target}("test")
    ${link:set_kind}("binary")
    ${link:add_files}("src/*.c")

    ${link:after_build}(function (target))
        ${link:try}
        {
            function ()
                os.run("ldid -S %s", target:targetfile())
            end
        }
    end
```

If you want to capture the error message, you can add a catch:

```lua
${link:target}("test")
    ${link:set_kind}("binary")
    ${link:add_files}("src/*.c")

    ${link:after_build}(function (target))
        ${link:try}
        {
            function ()
                os.run("ldid -S %s", target:targetfile())
            end,
            ${link:catch}
            {
                function (errors)
                    ${link:print}(errors)
                end
            }
        }
    end
```

However, in general, write custom scripts in xmake, do not need to manually add try-catch, directly call a variety of api, after the error, let xmake default handler to take over, directly interrupted. .

