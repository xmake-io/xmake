import importlib.util
import sys
from types import SimpleNamespace

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("xmake_generator", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

cpp_info = SimpleNamespace(**{
    "_" + field: [] for field in (
        "includedirs", "libdirs", "bindirs", "resdirs", "srcdirs",
        "frameworkdirs", "libs", "frameworks", "system_libs", "defines",
        "cxxflags", "cflags", "sharedlinkflags", "exelinkflags",
    )
})
cpp_info._includedirs = [r'C:\Program Files\quoted\include']
cpp_info._defines = [r'ROOT=C:\new\test', 'NAME="hello world"']
cpp_info._cflags = ['-O2', '-DNAME="hello world"']
cpp_info._cxxflags = [r'/FI"C:\new folder\test.h"']
cpp_info._sharedlinkflags = ['-Wl,-rpath,"/opt/my libs"']
cpp_info._exelinkflags = [r'/LIBPATH:"C:\new folder\lib"']
cpp_info.aggregated_components = lambda: cpp_info


class Requirements:
    def items(self):
        return [(SimpleNamespace(ref=SimpleNamespace(name="quoted")),
                 SimpleNamespace(cpp_info=cpp_info))]


module.XmakeGenerator(SimpleNamespace(
    dependencies=SimpleNamespace(host=Requirements(), test={}, build={}),
    settings=SimpleNamespace(os="Windows", arch="x86_64", build_type="Release"),
)).generate()
