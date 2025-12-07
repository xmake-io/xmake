#include <stdio.h>
#include <stdint.h>

extern const uint8_t _binary_test_vs_spv_start[];
extern const uint8_t _binary_test_vs_spv_end[];

extern const uint8_t _binary_test_ps_spv_start[];
extern const uint8_t _binary_test_ps_spv_end[];

int main(int argc, char** argv) {
    const uint32_t vs_size = (uint32_t)(_binary_test_vs_spv_end - _binary_test_vs_spv_start);
    const uint32_t ps_size = (uint32_t)(_binary_test_ps_spv_end - _binary_test_ps_spv_start);
    
    printf("test.vs.spv: size: %u bytes\n", vs_size);
    printf("test.ps.spv: size: %u bytes\n", ps_size);
    
    // Print first few bytes
    if (vs_size > 0) {
        printf("test.vs.spv first 4 bytes: ");
        for (uint32_t i = 0; i < 4 && i < vs_size; i++) {
            printf("%02x ", _binary_test_vs_spv_start[i]);
        }
        printf("\n");
    }
    
    if (ps_size > 0) {
        printf("test.ps.spv first 4 bytes: ");
        for (uint32_t i = 0; i < 4 && i < ps_size; i++) {
            printf("%02x ", _binary_test_ps_spv_start[i]);
        }
        printf("\n");
    }
    
    return 0;
}

