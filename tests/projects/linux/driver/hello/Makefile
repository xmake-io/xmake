ifneq ($(KERNELRELEASE),)
    obj-m := hello.o
else
    KERN_DIR ?= /usr/src/linux-headers-5.11.0-41-generic/
    PWD := $(shell pwd)

default:
	$(MAKE) -C $(KERN_DIR) V=1 M=$(PWD) modules
endif

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions

