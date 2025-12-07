#include <stdio.h>

static unsigned char g_test_vert_spv_data[] = {
    #include "test.vert.spv.h"
};

static unsigned char g_test_frag_spv_data[] = {
    #include "test.frag.spv.h"
};

int main(int argc, char** argv) {
    printf("test.vert.spv: %s, size: %d\n", g_test_vert_spv_data, (int)sizeof(g_test_vert_spv_data));
    printf("test.frag.spv: %s, size: %d\n", g_test_frag_spv_data, (int)sizeof(g_test_frag_spv_data));
    return 0;
}
