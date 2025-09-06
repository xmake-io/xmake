#include <stdio.h>
#include <string.h>

static const unsigned char message_data[] = {
#embed "message.txt"
    , '\0'
};

int main(int argc, char** argv) {
    printf("Embedded message: %s\n", (const char*)message_data);
    printf("Size of embedded data (including null terminator): %zu bytes\n", sizeof(message_data));
    printf("Length of embedded string: %zu characters\n", strlen((const char*)message_data));
    return 0;
}
