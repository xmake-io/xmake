#import <AppKit/AppKit.h>

int extfoo_value(void);

int main(void) {
    return extfoo_value() == 7 ? 0 : 1;
}
