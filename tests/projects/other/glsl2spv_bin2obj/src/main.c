#include <stdio.h>
#include <stdint.h>

extern const uint8_t _binary_test_vert_spv_start[];
extern const uint8_t _binary_test_vert_spv_end[];

extern const uint8_t _binary_test_frag_spv_start[];
extern const uint8_t _binary_test_frag_spv_end[];

int main(int argc, char** argv) {
    const uint32_t vert_size = (uint32_t)(_binary_test_vert_spv_end - _binary_test_vert_spv_start);
    const uint32_t frag_size = (uint32_t)(_binary_test_frag_spv_end - _binary_test_frag_spv_start);
    
    printf("test.vert.spv: size: %u bytes\n", vert_size);
    printf("test.frag.spv: size: %u bytes\n", frag_size);
    
    // Print first few bytes
    if (vert_size > 0) {
        printf("test.vert.spv first 4 bytes: ");
        for (uint32_t i = 0; i < 4 && i < vert_size; i++) {
            printf("%02x ", _binary_test_vert_spv_start[i]);
        }
        printf("\n");
    }
    
    if (frag_size > 0) {
        printf("test.frag.spv first 4 bytes: ");
        for (uint32_t i = 0; i < 4 && i < frag_size; i++) {
            printf("%02x ", _binary_test_frag_spv_start[i]);
        }
        printf("\n");
    }
    
    return 0;
}

