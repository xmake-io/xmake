#include <stdio.h>

static unsigned char g_bin_data[] = {
    #include "data.bin.h"
};

static unsigned char g_png_data[] = {
    #include "image.png.h"
};

int main(int argc, char** argv)
{
    printf("data.bin: %s, size: %d\n", g_bin_data, (int)sizeof(g_bin_data));
    printf("image.png: %s, size: %d\n", g_png_data, (int)sizeof(g_png_data));
    return 0;
}
