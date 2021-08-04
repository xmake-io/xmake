#include <stdio.h>

static unsigned char g_bin_data[] = {
    #include "data.bin.h"
};

int main(int argc, char** argv)
{
    printf("bin2c: %s\n", g_bin_data);
    return 0;
}
