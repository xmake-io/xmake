import("core.language.language")

function _write_asc_file(name, source)
    local sourcefile = os.tmpfile(name) .. ".asc"
    io.writefile(sourcefile, source)
    return sourcefile
end

function test_check_main(t)
    local instance = language.load("ascendc")
    t:require(instance)

    local check_main = instance:get("check_main")
    t:require(check_main)

    local mainfile = _write_asc_file("ascendc_check_main", [[
#include "acl/acl.h"

int32_t main(int argc, char const *argv[]) {
    return 0;
}
]])
    t:are_equal(check_main(mainfile), true)

    local commentfile = _write_asc_file("ascendc_check_main_comment", [[
// int main() { return 0; }
/*
int main() { return 1; }
*/
__global__ __vector__ void kernel() {
}
]])
    t:are_equal(check_main(commentfile), false)
end
