package("example-functions")
    set_kind("addon")
    set_description("The standalone functions example.")
    set_license("Apache-2.0")

    -- Resolve against the recipe, not the caller's current working directory.
    set_sourcedir(path.join(os.scriptdir(), "../../../../addon"))
