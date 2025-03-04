rule("scan_xyz")
    set_extensions(".xyz")
    on_scan_files(function(target, sourcebatch)
        for _, sourcefile in ipairs(sourcebatch.sourcefiles) do
            local outfile = path.join(target:autogendir(), path.filename(sourcefile) .. ".cpp")
            io.writefile(outfile, [[
               #include <iostream>
               int main() { std::cout << "Hello world" << std::endl; return 0; }
             ]])
            target:add("files", outfile, {always_added = true})
        end
    end)

target("foo")
    add_languages("c++11")
    add_files("src/*.xyz")
    add_rules("scan_xyz")
