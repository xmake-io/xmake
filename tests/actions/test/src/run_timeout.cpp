#ifdef _MSC_VER
#   include <windows.h>
#else
#   include <unistd.h>
#endif

int main(int argc, char** argv) {
#ifdef _MSC_VER
    Sleep(10 * 1000);
#else
    usleep(10 * 100 * 1000);
#endif
    return 0;
}
