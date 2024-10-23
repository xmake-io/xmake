#include <linux/init.h>
#include <linux/module.h>
#include "add.h"
MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Ruki");
MODULE_DESCRIPTION("A simple Hello World Module");
MODULE_ALIAS("a simplest module");

static int hello_init(void)
{
    printk(KERN_INFO "Hello World: %d\n", add(1, 2));
    return 0;
}

static void hello_exit(void)
{
    printk(KERN_INFO "Goodbye World\n");
}

module_init(hello_init);
module_exit(hello_exit);
