import core.sys.windows.windows;
import core.sys.windows.dll;

version(Windows)
mixin SimpleDllMain;

extern(C) int add(int a, int b) {
    return a + b;
}

extern(C) int sub(int a, int b) {
    return a - b;
}

