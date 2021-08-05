# architecture makefile configure

# prefix & suffix
BIN_PREFIX			=
BIN_SUFFIX			= .b

OBJ_PREFIX			=
OBJ_SUFFIX			= .o

LIB_PREFIX			= lib
LIB_SUFFIX			= .a

DLL_PREFIX			=
DLL_SUFFIX			= .dylib

ASM_SUFFIX			= .S

# target arch
TARGETARCH			:= $(if $(findstring x86_64,$(BUILD_ARCH)),-arch x86_64,$(TARGETARCH))
TARGETARCH			:= $(if $(findstring arm64,$(BUILD_ARCH)),-arch arm64,$(TARGETARCH))
TARGETARCH			:= $(if $(findstring i386,$(BUILD_ARCH)),-arch i386,$(TARGETARCH))
TARGETARCH 			+= -miphoneos-version-min=10.0

# prefix
PRE_				:= $(if $(BIN),$(BIN)/$(PRE),xcrun -sdk iphoneos )

# cc
CC					:= $(if $(CC),$(CC),$(PRE_)clang)
ifeq ($(CXFLAGS_CHECK),)
CC_CHECK			= ${shell if $(CC) $(1) -S -o /dev/null -xc /dev/null > /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi }
CXFLAGS_CHECK		:= $(call CC_CHECK,-ftrapv,)
export CXFLAGS_CHECK
endif

# ld
LD					:= $(if $(CC),$(CC),$(PRE_)clang)
ifeq ($(LDFLAGS_CHECK),)
LD_CHECK			= ${shell if $(LD) $(1) -S -o /dev/null -xc /dev/null > /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi }
LDFLAGS_CHECK		:= $(call LD_CHECK,-ftrapv,)
export LDFLAGS_CHECK
endif

# tool
MM					:= $(if $(CC),$(CC),$(PRE_)clang)
AR					:= $(if $(AR),$(AR),$(PRE_)ar)
STRIP				:= $(if $(STRIP),$(STRIP),$(PRE_)strip)
RANLIB				:= $(if $(RANLIB),$(RANLIB),$(PRE_)ranlib)
AS					= $(PRE_)clang
RM					= rm -f
RMDIR				= rm -rf
CP					= cp
CPDIR				= cp -r
MKDIR				= mkdir -p
MAKE				= make -r

# cxflags: .c/.cc/.cpp files
CXFLAGS_RELEASE		= -fvisibility=hidden
CXFLAGS_DEBUG		= -g -D__tb_debug__
CXFLAGS				= $(TARGETARCH) -c -Wall -Werror -Wno-error=deprecated-declarations -Qunused-arguments
CXFLAGS-I			= -I
CXFLAGS-o			= -o

# opti
ifeq ($(SMALL),y)
CXFLAGS_RELEASE		+= -Os
else
CXFLAGS_RELEASE		+= -O3
endif

# prof
ifeq ($(PROF),y)
CXFLAGS				+= -g -fno-omit-frame-pointer
else
CXFLAGS_RELEASE		+= -fomit-frame-pointer
CXFLAGS_DEBUG		+= -fno-omit-frame-pointer $(CXFLAGS_CHECK)
endif

# cflags: .c files
CFLAGS_RELEASE		=
CFLAGS_DEBUG		=
CFLAGS				= \
					-std=c99 \
					-D_GNU_SOURCE=1 -D_REENTRANT \
					-fno-math-errno -fno-tree-vectorize

# ccflags: .cc/.cpp files
CCFLAGS_RELEASE		=
CCFLAGS_DEBUG		=
CCFLAGS				= \
					-D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE \
					-D_POSIX_C_SOURCE=200112 -D_XOPEN_SOURCE=600

# mxflags: .m/.mm files
MXFLAGS_RELEASE		= -fvisibility=hidden
MXFLAGS_DEBUG		= -g -D__tb_debug__
MXFLAGS				= \
					$(TARGETARCH) -c -Wall -Werror -Wno-error=deprecated-declarations -Qunused-arguments \
					$(ARCH_CXFLAGS) -fmessage-length=0 -pipe -fpascal-strings \
					"-DIBOutlet=__attribute__((iboutlet))" \
					"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))" \
					"-DIBAction=void)__attribute__((ibaction)"
MXFLAGS-I			= -I
MXFLAGS-o			= -o

# opti
ifeq ($(SMALL),y)
MXFLAGS_RELEASE		+= -Os
else
MXFLAGS_RELEASE		+= -O3
endif

# prof
ifeq ($(PROF),y)
MXFLAGS				+= -g -fno-omit-frame-pointer
else
MXFLAGS_RELEASE		+= -fomit-frame-pointer
MXFLAGS_DEBUG		+= -fno-omit-frame-pointer $(LDFLAGS_CHECK)
endif

# mflags: .m files
MFLAGS_RELEASE		=
MFLAGS_DEBUG		=
MFLAGS				= -std=c99

# mmflags: .mm files
MMFLAGS_RELEASE		=
MMFLAGS_DEBUG		=
MMFLAGS				=

# ldflags
LDFLAGS_ARCH		:= $(if $(findstring arm64,$(BUILD_ARCH)),,-pagezero_size 10000 -image_base 100000000)
LDFLAGS_RELEASE		=
LDFLAGS_DEBUG		=
LDFLAGS				= $(TARGETARCH) -all_load $(LDFLAGS_ARCH) -framework CoreFoundation -framework Foundation
LDFLAGS-L			= -L
LDFLAGS-l			= -l
LDFLAGS-f			=
LDFLAGS-o			= -o

# prof
ifeq ($(PROF),y)
else
LDFLAGS_RELEASE		+= -s
LDFLAGS_DEBUG		+= -ftrapv
endif

# asflags
ASFLAGS_RELEASE		=
ASFLAGS_DEBUG		=
ASFLAGS				= $(TARGETARCH) -c -Wall
ASFLAGS-I			= -I
ASFLAGS-o			= -o

# arflags
ARFLAGS_RELEASE		=
ARFLAGS_DEBUG		=
ARFLAGS				= -cr
ARFLAGS-o			=

# shflags
SHFLAGS_RELEASE		= -s
SHFLAGS				= $(ARCH_LDFLAGS) -dynamiclib

# config
include				$(PLAT_DIR)/config.mak


