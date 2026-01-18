#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

int main(int argc, char** argv) {
    printf("zlib version: %s\n", zlibVersion());
    
    // simple compression test
    const char* source = "Hello, zlib requires lock test!";
    uLong sourceLen = strlen(source) + 1;
    uLong destLen = compressBound(sourceLen);
    Bytef* dest = (Bytef*)malloc(destLen);
    
    if (compress(dest, &destLen, (const Bytef*)source, sourceLen) == Z_OK) {
        printf("Compression successful, compressed size: %lu\n", destLen);
        
        // decompression test
        uLong decompLen = sourceLen;
        Bytef* decomp = (Bytef*)malloc(decompLen);
        if (uncompress(decomp, &decompLen, dest, destLen) == Z_OK) {
            printf("Decompression successful: %s\n", (char*)decomp);
        }
        free(decomp);
    }
    free(dest);
    
    return 0;
}
