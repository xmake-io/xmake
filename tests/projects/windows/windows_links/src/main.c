#include <windows.h>
#include <psapi.h>
#include <stdio.h>

__declspec(dllimport) void foo();

int main() {
    PROCESS_MEMORY_COUNTERS pmc;
    printf("Calling GetProcessMemoryInfo...\n");
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
        printf("PageFaultCount: %lu\n", pmc.PageFaultCount);
        printf("WorkingSetSize: %lu\n", pmc.WorkingSetSize);
    } else {
        printf("GetProcessMemoryInfo failed (%lu)\n", GetLastError());
    }
    printf("Calling foo...\n");
    foo();
    printf("Done.\n");
    return 0;
}

