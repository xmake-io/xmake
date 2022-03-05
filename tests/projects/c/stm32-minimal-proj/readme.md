## Build Stm32 Demo Firmware with xmake

This is a demo project from [arm-mini-os](https://github.com/jserv/mini-arm-os/tree/master/01-HelloWorld) to demenstrate how to compile embedded system using xmake.  

The origin Makefile is [here](https://github.com/jserv/mini-arm-os/blob/master/01-HelloWorld/Makefile).


All the compiling settings are in armgcc.lua.


### Step 1: Obtain the cross compile toolchain 
1. Download Arm gcc tool   
https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads

2. Put tool path to PATH  
```
export ARM_GCC_TOOL=/work/tool/arm-gcc-eabi-none/
export PATH=${ARM_GCC_TOOL}:${PATH}
```

### Step 2: Compile and Run
Compile:
```
$ xmake b -vD
```

2. Run in qemu:  
Download and compile qemu-arm-stm32_v0.1.3 (only works on this version)  

```
wget https://github.com/beckus/qemu_stm32/archive/refs/tags/stm32_v0.1.3.zip
unzip stm32_v0.1.3.zip
cd qemu_stm32-stm32_v0.1.3/
./configure --disable-werror --enable-debug \
    --target-list="arm-softmmu" \
    --extra-cflags=-DSTM32_UART_NO_BAUD_DELAY \
    --extra-cflags=-DSTM32_UART_ENABLE_OVERRUN \
    --disable-gtk
make
```

Launch qemu via xmake task plugin.
```
$ xmake qemu
Run binary in Qemu!

(process:1411): GLib-WARNING **: 22:07:02.449: ../glib/gmem.c:497: custom memory allocation vtable not supported
LED Off
Hello Xmake!
```