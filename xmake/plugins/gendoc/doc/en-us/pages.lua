function main()
    return {
        {
            title = "index",
            pages = {
                {
                    name = "index",
                    path = "index.html",
                    docdir = ".",
                    title = "index",
                },
            },
        },
        {
            title = "API Manual (Description Scope)", -- "API手册（描述域）",
            pages = {
                {
                    name = "conditions",
                    path = "api/conditions.html",
                    docdir = "api/conditions",
                    title = "Conditions",
                },
                {
                    name = "exceptions",
                    path = "api/builtin_modules/exceptions.html",
                    docdir = "api/builtin_modules/exceptions",
                    title = "Exceptions",
                },
                {
                    name = "os",
                    path = "api/builtin_modules/os.html",
                    docdir = "api/builtin_modules/os",
                    title = "os",
                },
            },
        },
    }
end
