#import <Foundation/Foundation.h>
#import <test/test.h>

int main(int argc, char** argv)
{
    @autoreleasepool
    {
        NSLog(@"add(1, 2): %d", add(1, 2));
        Test* t = [[Test alloc] init];
        [t hello];
    }
    return 0;
}
