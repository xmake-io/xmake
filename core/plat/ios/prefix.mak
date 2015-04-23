# architecture makefile configure

# prefix & suffix
BIN_PREFIX 			= 
BIN_SUFFIX 			= .b

OBJ_PREFIX 			= 
OBJ_SUFFIX 			= .o
	
LIB_PREFIX 			= lib
LIB_SUFFIX 			= .a
	
DLL_PREFIX 			= lib
DLL_SUFFIX 			= .dylib

ASM_SUFFIX 			= .S

# prefix
PRE_ 				:= $(if $(BIN),$(BIN)/$(PRE),xcrun -sdk iphoneos )

# toolchain
CC 					= $(PRE_)clang
MM 					= $(PRE_)clang
AR 					= $(PRE_)ar
STRIP 				= $(PRE_)strip
RANLIB 				= $(PRE_)ranlib
LD 					= $(PRE_)clang
AS					= $(TOOL_DIR)/gas-preprocessor.pl $(PRE_)clang
RM 					= rm -f
RMDIR 				= rm -rf
CP 					= cp
CPDIR 				= cp -r
MKDIR 				= mkdir -p
MAKE 				= make -r

# cxflags: .c/.cc/.cpp files
CXFLAGS_RELEASE 	= -fomit-frame-pointer -fvisibility=hidden
CXFLAGS_DEBUG 		= -g -D__tb_debug__
CXFLAGS 			= \
					-arch $(ARCH) -c -Wall -mthumb $(CPU_CXFLAGS) \
					-Werror -Wno-error=deprecated-declarations -Qunused-arguments \
					-fmessage-length=0 -pipe -fpascal-strings
CXFLAGS-I 			= -I
CXFLAGS-o 			= -o

# cflags: .c files
CFLAGS_RELEASE 		= 
CFLAGS_DEBUG 		= 
CFLAGS 				= -std=gnu99

# ccflags: .cc/.cpp files
CCFLAGS_RELEASE 	= 
CCFLAGS_DEBUG 		= 
CCFLAGS 			= 

# mxflags: .m/.mm files
MXFLAGS_RELEASE 	= -fomit-frame-pointer -fvisibility=hidden
MXFLAGS_DEBUG 		= -g -D__tb_debug__
MXFLAGS 			= \
					-arch $(ARCH) -c -Wall -mthumb \
					-Werror -Wno-error=deprecated-declarations -Qunused-arguments \
					-fmessage-length=0 -pipe -fpascal-strings \
					"-DIBOutlet=__attribute__((iboutlet))" \
					"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))" \
					"-DIBAction=void)__attribute__((ibaction)"
MXFLAGS-I 			= -I
MXFLAGS-o 			= -o

# small
MXFLAGS-$(SMALL) 	+= 

# mflags: .m files
MFLAGS_RELEASE 		= 
MFLAGS_DEBUG 		= 
MFLAGS 				= -std=gnu99

# mmflags: .mm files
MMFLAGS_RELEASE 	= 
MMFLAGS_DEBUG 		=	 
MMFLAGS 			=

# ldflags
LDFLAGS_RELEASE 	= -s
LDFLAGS_DEBUG 		= 
LDFLAGS 			= -arch $(ARCH) -framework Foundation
LDFLAGS-L 			= -L
LDFLAGS-l 			= -l
LDFLAGS-f 			=
LDFLAGS-o 			= -o

# asflags
ASFLAGS_RELEASE 	= 
ASFLAGS_DEBUG 		= 
ASFLAGS 			= -arch $(ARCH) -c -fPIC
ASFLAGS-I 			= -I
ASFLAGS-o 			= -o 

# arflags
ARFLAGS_RELEASE 	= 
ARFLAGS_DEBUG 		= 
ARFLAGS 			= -cr
ARFLAGS-o 			= 

# shflags
SHFLAGS_RELEASE 	= -s
SHFLAGS_DEBUG 		= 
SHFLAGS 			= -arch $(ARCH) -dynamiclib -Wl,-single_module

# cpu
ifeq ($(ARCH),armv6)
CXFLAGS 			+= -mcpu=arm1176jzf-s
MXFLAGS 			+= -mcpu=arm1176jzf-s
endif

ifeq ($(ARCH),armv7)
CXFLAGS 			+= -mcpu=cortex-a8
MXFLAGS 			+= -mcpu=cortex-a8
endif

ifeq ($(ARCH),armv7s)
CXFLAGS 			+= -mcpu=cortex-a8
MXFLAGS 			+= -mcpu=cortex-a8
endif

# optimization
ifeq ($(SMALL),y)
CXFLAGS_RELEASE 	+= -Os
MXFLAGS_RELEASE 	+= -Os
else
CXFLAGS_RELEASE 	+= -O3
MXFLAGS_RELEASE 	+= -O3
endif

# sdk
ifneq ($(SDK),)
CXFLAGS 			+= -isysroot $(SDK) 
MXFLAGS 			+= -isysroot $(SDK) 
LDFLAGS 			+= -isysroot $(SDK) 
SHFLAGS 			+= -isysroot $(SDK) 
endif

# config
include 			$(PLAT_DIR)/config.mak


