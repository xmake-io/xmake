#import "hello.h"

@implementation Hello

+ (void)say:(NSString*)s
{
    NSLog(@"%@\n", s);
}

@end
