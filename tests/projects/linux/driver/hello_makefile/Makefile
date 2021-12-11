ifneq ($(KERNELRELEASE),)
    obj-m := hello.o
	hello-objs := ./src/hello.o ./src/add.o
else
    KERN_DIR ?= /usr/src/linux-headers-5.11.0-41-generic/
    PWD := $(shell pwd)

default:
	$(MAKE) -C $(KERN_DIR) V=1 ARCH=arm64 CROSS_COMPILE=/mnt/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- M=$(PWD) modules
endif

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions
	rm -rf src/*.o src/*~ core src/.depend src/.*.cmd src/*.ko src/*.mod.c src/.tmp_versions

