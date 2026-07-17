#include <stdio.h>
#include <stdint.h>
#include <ctype.h>
#include <string.h>

extern const uint8_t _binary_data_bin_start[];
extern const uint8_t _binary_data_bin_end[];

extern const uint8_t _binary_xmake_ico_start[];
extern const uint8_t _binary_xmake_ico_end[];

extern const uint8_t _binary_asset_bin_start[];
extern const uint8_t _binary_asset_bin_end[];

static void hexdump(const char* name, const uint8_t* data, uint32_t size) {
    printf("%s: size: %u bytes\n", name, (unsigned int)size);
    if (size == 0) {
        return;
    }

    // if file is larger than 128 bytes, only dump first 64 and last 64 bytes
    uint32_t dump_size = size;
    uint32_t start_offset = 0;
    uint32_t end_offset = 0;
    uint32_t skip_size = 0;

    if (size > 128) {
        dump_size = 64;
        start_offset = 0;
        end_offset = size - 64;
        skip_size = end_offset - start_offset - dump_size;
    }

    // dump start
    for (uint32_t offset = start_offset; offset < start_offset + dump_size; offset += 16) {
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

    // print skip indicator if needed
    if (skip_size > 0) {
        printf("        ... (skipped %u bytes) ...\n", (unsigned int)skip_size);
    }

    // dump end if needed
    if (size > 128) {
        for (uint32_t offset = end_offset; offset < size; offset += 16) {
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
}

int main(int argc, char** argv) {
    const uint32_t _binary_data_bin_size = (uint32_t)(_binary_data_bin_end - _binary_data_bin_start);
    const uint32_t _binary_xmake_ico_size = (uint32_t)(_binary_xmake_ico_end - _binary_xmake_ico_start);
    const uint32_t _binary_asset_bin_size = (uint32_t)(_binary_asset_bin_end - _binary_asset_bin_start);

    hexdump("data.bin", _binary_data_bin_start, _binary_data_bin_size);
    printf("\n");
    hexdump("xmake.ico", _binary_xmake_ico_start, _binary_xmake_ico_size);
    printf("\n");
    hexdump("asset.bin (transformed)", _binary_asset_bin_start, _binary_asset_bin_size);

    // verify the transform: asset.bin must be the reverse of "hello transform!" (+ zeroend '\0')
    const char* expected = "!mrofsnart olleh";
    if (_binary_asset_bin_size != 17 || memcmp(_binary_asset_bin_start, expected, 16) != 0) {
        printf("asset.bin: transform verification failed!\n");
        return 1;
    }
    printf("asset.bin: transform verification ok\n");
    return 0;
}
