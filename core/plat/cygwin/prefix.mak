# architecture makefile configure

# prefix & suffix
BIN_PREFIX 			= 
BIN_SUFFIX 			= .exe

OBJ_PREFIX 			= 
OBJ_SUFFIX 			= .obj

LIB_PREFIX 			= 
LIB_SUFFIX 			= .lib

DLL_PREFIX 			= 
DLL_SUFFIX 			= .dll

ASM_SUFFIX 			= .S

# prefix
PRE_ 				:= $(if $(BIN),$(BIN)/$(PRE),)

# cc
CC_ 				:= ${shell if [ -f "/usr/bin/clang" ]; then echo "clang"; elif [ -f "/usr/local/bin/clang" ]; then echo "clang"; else echo "gcc"; fi }
CC_ 				:= $(if $(findstring y,$(PROF)),gcc,$(CC_))
CC 					= $(PRE_)$(CC_)

# ld
LD_ 				:= ${shell if [ -f "/usr/bin/clang++" ]; then echo "clang++"; elif [ -f "/usr/local/bin/clang++" ]; then echo "clang++"; else echo "g++"; fi }
LD_ 				:= $(if $(findstring y,$(PROF)),g++,$(LD_))
LD 					= $(PRE_)$(LD_)

# cpu bits
BITS 				:= $(if $(findstring x64,$(ARCH)),64,)
BITS 				:= $(if $(findstring x86,$(ARCH)),32,)
BITS 				:= $(if $(BITS),$(BITS),$(shell getconf LONG_BIT))

# tool
AR 					= $(PRE_)ar
STRIP 				= $(PRE_)strip
RANLIB 				= $(PRE_)ranlib
AS					= yasm
RM 					= rm -f
RMDIR 				= rm -rf
CP 					= cp
CPDIR 				= cp -r
MKDIR 				= mkdir -p
MAKE 				= make -r

# cxflags: .c/.cc/.cpp files
CXFLAGS_RELEASE 	= -freg-struct-return -fvisibility=hidden
CXFLAGS_DEBUG 		= -g -D__tb_debug__
CXFLAGS 			= -m$(BITS) -c -Wall -Werror -Wno-error=deprecated-declarations -Wno-error=cpp -mssse3
CXFLAGS-I 			= -I
CXFLAGS-o 			= -o

# opti
ifeq ($(SMALL),y)
CXFLAGS_RELEASE 	+= -Os
else
CXFLAGS_RELEASE 	+= -O3
endif

# prof
ifeq ($(PROF),y)
CXFLAGS 			+= -g -pg -fno-omit-frame-pointer 
else
CXFLAGS_RELEASE 	+= -fomit-frame-pointer 
CXFLAGS_DEBUG 		+= -fno-omit-frame-pointer 
endif

# cflags: .c files
CFLAGS_RELEASE 		= 
CFLAGS_DEBUG 		= 
CFLAGS 				= \
					-std=c99 \
					-D_GNU_SOURCE=1 -D_REENTRANT \
					-fno-math-errno -fno-signed-zeros -fno-tree-vectorize

# ccflags: .cc/.cpp files
CCFLAGS_RELEASE 	= -fno-rtti
CCFLAGS_DEBUG 		= 
CCFLAGS 			= -D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_POSIX_C_SOURCE=200112 -D_XOPEN_SOURCE=600

# ldflags
LDFLAGS_RELEASE 	= -static
LDFLAGS_DEBUG 		= -rdynamic 
LDFLAGS 			= -m$(BITS) 
LDFLAGS-L 			= -L
LDFLAGS-l 			= -l
LDFLAGS-f 			=
LDFLAGS-o 			= -o

# prof
ifeq ($(PROF),y)
LDFLAGS 			+= -pg 
else
LDFLAGS_RELEASE 	+= -s
LDFLAGS_DEBUG 		+= 
endif

# asflags
ASFLAGS_RELEASE 	= 
ASFLAGS_DEBUG 		= 
ASFLAGS 			= -m$(BITS) -f elf
ASFLAGS-I 			= -I
ASFLAGS-o 			= -o

# arflags
ARFLAGS_RELEASE 	= 
ARFLAGS_DEBUG 		= 
ARFLAGS 			= -cr
ARFLAGS-o 			= 

# shflags
SHFLAGS_RELEASE 	= -s
SHFLAGS 			= -m$(BITS) -shared -Wl,-soname

# include sub-config
include 			$(PLAT_DIR)/config.mak


