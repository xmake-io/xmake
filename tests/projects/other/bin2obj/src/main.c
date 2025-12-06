#include <stdio.h>
#include <stdint.h>

extern const uint8_t _binary_data_bin_start[];
extern const uint8_t _binary_data_bin_end[];

extern const uint8_t _binary_image_png_start[];
extern const uint8_t _binary_image_png_end[];

const uint32_t _binary_data_bin_size = (uint32_t)(_binary_data_bin_end - _binary_data_bin_start);
const uint32_t _binary_image_png_size = (uint32_t)(_binary_image_png_end - _binary_image_png_start);

int main(int argc, char** argv) {
    printf("data.bin: %s, size: %u\n", (const char*)_binary_data_bin_start, (unsigned int)_binary_data_bin_size);
    printf("image.png: %s, size: %u\n", (const char*)_binary_image_png_start, (unsigned int)_binary_image_png_size);
    return 0;
}
