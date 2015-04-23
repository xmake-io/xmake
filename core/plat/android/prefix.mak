# architecture makefile configure

# prefix & suffix
BIN_PREFIX 			= 
BIN_SUFFIX 			= .b

OBJ_PREFIX 			= 
OBJ_SUFFIX 			= .o

LIB_PREFIX 			= lib
LIB_SUFFIX 			= .a

DLL_PREFIX 			= lib
DLL_SUFFIX 			= .so

ASM_SUFFIX 			= .S

# tool
PRE_ 				:= $(if $(PRE),$(PRE),arm-linux-androideabi-)
PRE_ 				:= $(if $(BIN),$(BIN)/$(PRE_),$(PRE_))
CC 					= $(PRE_)gcc
AR 					= $(PRE_)ar
STRIP 				= $(PRE_)strip
RANLIB 				= $(PRE_)ranlib
LD 					= $(PRE_)g++
AS					= 
RM 					= rm -f
RMDIR 				= rm -rf
CP 					= cp
CPDIR 				= cp -r
MKDIR 				= mkdir -p
MAKE 				= make -r

# cxflags: .c/.cc/.cpp files
CXFLAGS_RELEASE 	= -freg-struct-return -fno-bounds-check -fvisibility=hidden
CXFLAGS_DEBUG 		= -g -D__tb_debug__
CXFLAGS 			= -c -Wall -fomit-frame-pointer -march=$(ARCH) \
					  -I$(SDK)/platforms/android-8/arch-arm/usr/include 
CXFLAGS-I 			= -I
CXFLAGS-o 			= -o

# opti
ifeq ($(SMALL),y)
CXFLAGS_RELEASE 	+= -Os
else
CXFLAGS_RELEASE 	+= -O3
endif

# cflags: .c files
CFLAGS_RELEASE 		= 
CFLAGS_DEBUG 		= 
CFLAGS 				= \
					-std=c99 \
					-D_GNU_SOURCE=1 -D_REENTRANT \
					-Wno-parentheses \
					-Wno-switch -Wno-format-zero-length -Wdisabled-optimization \
					-Wpointer-arith -Wredundant-decls -Wno-pointer-sign -Wwrite-strings \
					-Wtype-limits -Wundef -Wmissing-prototypes -Wno-pointer-to-int-cast \
					-Wstrict-prototypes -fno-math-errno -fno-signed-zeros -fno-tree-vectorize \
					-Werror=implicit-function-declaration -Werror=missing-prototypes 

# ccflags: .cc/.cpp files
CCFLAGS_RELEASE 	=
CCFLAGS_DEBUG 		= 
CCFLAGS 			= \
					-D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE \
					-D_POSIX_C_SOURCE=200112 -D_XOPEN_SOURCE=600 \
					-I$(SDK)/sources/cxx-stl/stlport/stlport

# ldflags
LDFLAGS_RELEASE 	= -s
LDFLAGS_DEBUG 		= 
LDFLAGS 			= -nostdlib \
					-L$(SDK)/platforms/android-8/arch-arm/usr/lib/ \
					$(SDK)/platforms/android-8/arch-arm/usr/lib/crtbegin_dynamic.o \
					$(SDK)/platforms/android-8/arch-arm/usr/lib/crtend_android.o
LDFLAGS-L 			= -L
LDFLAGS-l 			= -l
LDFLAGS-f 			=
LDFLAGS-o 			= -o

# asflags
ASFLAGS_RELEASE 	= 
ASFLAGS_DEBUG 		= 
ASFLAGS 			= 
ASFLAGS-I 			= -I
ASFLAGS-o 			= -o

# arflags
ARFLAGS_RELEASE 	= 
ARFLAGS_DEBUG 		= 
ARFLAGS 			= -cr
ARFLAGS-o 			= 

# shflags
SHFLAGS_RELEASE 	= -s
SHFLAGS 			= -march=$(ARCH) -shared -Wl,-soname -nostdlib \
					-L$(SDK)/platforms/android-8/arch-arm/usr/lib/ \
					$(SDK)/platforms/android-8/arch-arm/usr/lib/crtbegin_so.o \
					$(SDK)/platforms/android-8/arch-arm/usr/lib/crtend_so.o

# include sub-config
include 			$(PLAT_DIR)/config.mak


