#include <stdio.h>
#include <zlib.h>
#include <plist/plist.h>

int main(int argc, char** argv)
{
    printf("hello world!\n");
    inflate(0, 0);
    plist_new_dict();
    return 0;
}
