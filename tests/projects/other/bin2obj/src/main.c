#include <stdio.h>
#include <stdint.h>
#include <ctype.h>

extern const uint8_t _binary_data_bin_start[];
extern const uint8_t _binary_data_bin_end[];

extern const uint8_t _binary_image_png_start[];
extern const uint8_t _binary_image_png_end[];

static void hexdump(const char* name, const uint8_t* data, uint32_t size) {
    printf("%s: size: %u bytes\n", name, (unsigned int)size);
    if (size == 0) {
        return;
    }
    for (uint32_t offset = 0; offset < size; offset += 16) {
        // print offset
        printf("%08x  ", (unsigned int)offset);
        
        // print hex bytes (8 bytes, space, 8 bytes)
        for (uint32_t i = 0; i < 16; i++) {
            if (offset + i < size) {
                printf("%02x ", data[offset + i]);
            } else {
                printf("   ");
            }
            if (i == 7) {
                printf(" ");
            }
        }
        
        // print ASCII representation
        printf(" |");
        for (uint32_t i = 0; i < 16 && offset + i < size; i++) {
            uint8_t c = data[offset + i];
            printf("%c", isprint(c) ? c : '.');
        }
        printf("|\n");
    }
}

int main(int argc, char** argv) {
    const uint32_t _binary_data_bin_size = (uint32_t)(_binary_data_bin_end - _binary_data_bin_start);
    const uint32_t _binary_image_png_size = (uint32_t)(_binary_image_png_end - _binary_image_png_start);

    hexdump("data.bin", _binary_data_bin_start, _binary_data_bin_size);
    printf("\n");
    hexdump("image.png", _binary_image_png_start, _binary_image_png_size);
    return 0;
}
