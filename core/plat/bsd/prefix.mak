# architecture makefile configure

# prefix & suffix
BIN_PREFIX			=
BIN_SUFFIX			= .b

OBJ_PREFIX			=
OBJ_SUFFIX			= .o

LIB_PREFIX			= lib
LIB_SUFFIX			= .a

DLL_PREFIX			= lib
DLL_SUFFIX			= .so

ASM_SUFFIX			= .S

# prefix
PRE_				:= $(if $(BIN),$(BIN)/$(PRE),)

# tool
CC					:= $(if $(CC),$(CC),$(PRE_)gcc)
LD					:= $(if $(CC),$(CC),$(PRE_)gcc) # we do not use ld directly
AR					:= $(if $(AR),$(AR),$(PRE_)ar)
STRIP				:= $(if $(STRIP),$(STRIP),$(PRE_)strip)
RANLIB				:= $(if $(RANLIB),$(RANLIB),$(PRE_)ranlib)
AS					:= $(CC)
RM					= rm -f
RMDIR				= rm -rf
CP					= cp
CPDIR				= cp -r
MKDIR				= mkdir -p
MAKE				= gmake -r

# architecture flags
AHFLAGS				:= $(if $(AHFLAGS),$(AHFLAGS),$(if $(findstring x86_64,$(BUILD_ARCH)),-m64,))
AHFLAGS				:= $(if $(AHFLAGS),$(AHFLAGS),$(if $(findstring i386,$(BUILD_ARCH)),-m32,))

# check flags for x64 or x86
ifneq ($(AHFLAGS),)
ifeq ($(CXFLAGS_CHECK),)
CC_CHECK			= ${shell if $(CC) $(1) -S -o /dev/null -xc /dev/null > /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi }
CXFLAGS_CHECK		:=
export CXFLAGS_CHECK
endif

ifeq ($(LDFLAGS_CHECK),)
LD_CHECK			= ${shell if $(LD) $(1) -S -o /dev/null -xc /dev/null > /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi }
LDFLAGS_CHECK		:= $(call LD_CHECK,-no-pie,)
export LDFLAGS_CHECK
endif
endif

# cxflags: .c/.cc/.cpp files
CXFLAGS_RELEASE		=
CXFLAGS_DEBUG		= -g -D__tb_debug__
CXFLAGS				= $(AHFLAGS) $(CXFLAGS_CHECK) -c -Wall
CXFLAGS-I			= -I
CXFLAGS-o			= -o

# suppress warning for ccache + clang bug
CXFLAGS				+= $(if $(findstring clang,$(CC)),-Qunused-arguments,)

# optimization
ifeq ($(SMALL),y)
CXFLAGS_RELEASE		+= -Os
else
CXFLAGS_RELEASE		+= -O3
endif

# profile
ifeq ($(PROF),y)
CXFLAGS				+= -g -pg -fno-omit-frame-pointer
else
CXFLAGS_RELEASE		+= -fomit-frame-pointer
CXFLAGS_DEBUG		+= -fno-omit-frame-pointer
endif

# cflags: .c files
CFLAGS_RELEASE		=
CFLAGS_DEBUG		=
CFLAGS				:= $(CFLAGS) \
					-std=gnu99 \
					-D_GNU_SOURCE=1 -D_REENTRANT \
					-fno-math-errno

# ccflags: .cc/.cpp files
CCFLAGS_RELEASE		= -fno-rtti
CCFLAGS_DEBUG		=
CCFLAGS				:= $(CXXFLAGS) -D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_POSIX_C_SOURCE=200112 -D_XOPEN_SOURCE=600

# ldflags
LDFLAGS_RELEASE		=
LDFLAGS_DEBUG		= -rdynamic -lexecinfo
LDFLAGS				:= $(LDFLAGS) $(AHFLAGS) $(LDFLAGS_CHECK)
LDFLAGS-L			= -L
LDFLAGS-l			= -l
LDFLAGS-f			=
LDFLAGS-o			= -o

# prof
ifeq ($(PROF),y)
LDFLAGS				+= -pg
else
LDFLAGS_RELEASE		+= -s
LDFLAGS_DEBUG		+=
endif

# asflags
ASFLAGS_RELEASE		=
ASFLAGS_DEBUG		=
ASFLAGS				= -c $(AHFLAGS)
ASFLAGS-I			= -I
ASFLAGS-o			= -o

# arflags
ARFLAGS_RELEASE		=
ARFLAGS_DEBUG		=
ARFLAGS				= -cr
ARFLAGS-o			=

# shflags
SHFLAGS_RELEASE		= -s
SHFLAGS				= $(AHFLAGS) -shared -Wl,-soname

# include sub-config
include				$(PLAT_DIR)/config.mak


