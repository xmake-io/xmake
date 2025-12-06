#include <stdio.h>
#include <stdint.h>

extern const uint8_t _binary_data_bin_start[];
extern const uint8_t _binary_data_bin_end[];
extern const uint32_t _binary_data_bin_size;

extern const uint8_t _binary_image_png_start[];
extern const uint8_t _binary_image_png_end[];
extern const uint32_t _binary_image_png_size;

int main(int argc, char** argv) {
    printf("data.bin size: %u\n", (unsigned int)_binary_data_bin_size);
    printf("data.bin start: %p\n", _binary_data_bin_start);
    printf("data.bin end: %p\n", _binary_data_bin_end);
    
    printf("image.png size: %u\n", (unsigned int)_binary_image_png_size);
    printf("image.png start: %p\n", _binary_image_png_start);
    printf("image.png end: %p\n", _binary_image_png_end);
    
    // print first few bytes of data.bin
    if (_binary_data_bin_size > 0) {
        printf("data.bin first byte: 0x%02x\n", _binary_data_bin_start[0]);
    }
    if (_binary_data_bin_size > 1) {
        printf("data.bin second byte: 0x%02x\n", _binary_data_bin_start[1]);
    }
    
    // print first few bytes of image.png
    if (_binary_image_png_size > 0) {
        printf("image.png first byte: 0x%02x\n", _binary_image_png_start[0]);
    }
    if (_binary_image_png_size > 1) {
        printf("image.png second byte: 0x%02x\n", _binary_image_png_start[1]);
    }
    
    return 0;
}
