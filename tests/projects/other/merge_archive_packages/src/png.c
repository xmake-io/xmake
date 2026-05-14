#include "png.h"

char const* get_png_version() {
    return png_get_libpng_ver(NULL);
}
