# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= tbox

# module type
tbox_TYPE 				= LIB

# config
tbox_CONFIG 			= n

# core files
tbox_C_FILES 			+= \
						src/tbox/tbox \
						src/tbox/hash/bkdr \
						src/tbox/hash/fnv32 \
						src/tbox/hash/adler32 \
						src/tbox/math/impl/math \
						src/tbox/math/random/linear \
						src/tbox/math/random/random \
						src/tbox/libc/impl/libc \
						src/tbox/libc/misc/time/gmmktime \
						src/tbox/libc/misc/time/gmtime \
						src/tbox/libc/misc/time/localtime \
						src/tbox/libc/misc/time/mktime \
						src/tbox/libc/misc/time/time \
						src/tbox/libc/stdio/printf \
						src/tbox/libc/stdio/printf_object \
						src/tbox/libc/stdio/puts \
						src/tbox/libc/stdio/snprintf \
						src/tbox/libc/stdio/sprintf \
						src/tbox/libc/stdio/swprintf \
						src/tbox/libc/stdio/vsnprintf \
						src/tbox/libc/stdio/vswprintf \
						src/tbox/libc/stdio/wprintf \
						src/tbox/libc/stdio/wputs \
						src/tbox/libc/stdlib/mbstowcs \
						src/tbox/libc/stdlib/random \
						src/tbox/libc/stdlib/stdlib \
						src/tbox/libc/stdlib/wcstombs \
						src/tbox/libc/string/memcmp \
						src/tbox/libc/string/memcpy \
						src/tbox/libc/string/memdup \
						src/tbox/libc/string/memmem \
						src/tbox/libc/string/memmov \
						src/tbox/libc/string/memset \
						src/tbox/libc/string/strcat \
						src/tbox/libc/string/strchr \
						src/tbox/libc/string/strcmp \
						src/tbox/libc/string/strcpy \
						src/tbox/libc/string/strdup \
						src/tbox/libc/string/strichr \
						src/tbox/libc/string/stricmp \
						src/tbox/libc/string/strirchr \
						src/tbox/libc/string/strirstr \
						src/tbox/libc/string/stristr \
						src/tbox/libc/string/strlcpy \
						src/tbox/libc/string/strlen \
						src/tbox/libc/string/strncat \
						src/tbox/libc/string/strncmp \
						src/tbox/libc/string/strncpy \
						src/tbox/libc/string/strndup \
						src/tbox/libc/string/strnicmp \
						src/tbox/libc/string/strnirchr \
						src/tbox/libc/string/strnirstr \
						src/tbox/libc/string/strnistr \
						src/tbox/libc/string/strnlen \
						src/tbox/libc/string/strnrchr \
						src/tbox/libc/string/strnrstr \
						src/tbox/libc/string/strnstr \
						src/tbox/libc/string/strrchr \
						src/tbox/libc/string/strrstr \
						src/tbox/libc/string/strstr \
						src/tbox/libc/string/wcscat \
						src/tbox/libc/string/wcschr \
						src/tbox/libc/string/wcscmp \
						src/tbox/libc/string/wcscpy \
						src/tbox/libc/string/wcsdup \
						src/tbox/libc/string/wcsichr \
						src/tbox/libc/string/wcsicmp \
						src/tbox/libc/string/wcsirchr \
						src/tbox/libc/string/wcsirstr \
						src/tbox/libc/string/wcsistr \
						src/tbox/libc/string/wcslcpy \
						src/tbox/libc/string/wcslen \
						src/tbox/libc/string/wcsncat \
						src/tbox/libc/string/wcsncmp \
						src/tbox/libc/string/wcsncpy \
						src/tbox/libc/string/wcsndup \
						src/tbox/libc/string/wcsnicmp \
						src/tbox/libc/string/wcsnirchr \
						src/tbox/libc/string/wcsnirstr \
						src/tbox/libc/string/wcsnlen \
						src/tbox/libc/string/wcsnrchr \
						src/tbox/libc/string/wcsnrstr \
						src/tbox/libc/string/wcsrchr \
						src/tbox/libc/string/wcsrstr \
						src/tbox/libc/string/wcsstr \
						src/tbox/utils/base32 \
						src/tbox/utils/base64 \
						src/tbox/utils/bits \
						src/tbox/utils/dump \
						src/tbox/utils/lock_profiler \
						src/tbox/utils/singleton \
						src/tbox/utils/trace \
						src/tbox/utils/url \
						src/tbox/utils/used \
						src/tbox/prefix/state \
						src/tbox/memory/allocator \
						src/tbox/memory/buffer \
						src/tbox/memory/default_allocator \
						src/tbox/memory/fixed_pool \
						src/tbox/memory/impl/memory \
						src/tbox/memory/impl/native_large_allocator \
						src/tbox/memory/impl/prefix \
						src/tbox/memory/impl/static_fixed_pool \
						src/tbox/memory/impl/static_large_allocator \
						src/tbox/memory/large_allocator \
						src/tbox/memory/native_allocator \
						src/tbox/memory/queue_buffer \
						src/tbox/memory/small_allocator \
						src/tbox/memory/static_allocator \
						src/tbox/memory/static_buffer \
						src/tbox/memory/string_pool \
						src/tbox/string/static_string \
						src/tbox/string/string \
						src/tbox/stream/filter \
						src/tbox/stream/impl/filter/cache \
						src/tbox/stream/impl/filter/chunked \
						src/tbox/stream/impl/stream/data \
						src/tbox/stream/impl/stream/file \
						src/tbox/stream/impl/stream/filter \
						src/tbox/stream/impl/stream/http \
						src/tbox/stream/impl/stream/sock \
						src/tbox/stream/static_stream \
						src/tbox/stream/stream \
						src/tbox/stream/transfer \
						src/tbox/network/cookies \
						src/tbox/network/dns/cache \
						src/tbox/network/dns/looker \
						src/tbox/network/dns/server \
						src/tbox/network/http \
						src/tbox/network/hwaddr \
						src/tbox/network/impl/http/date \
						src/tbox/network/impl/http/method \
						src/tbox/network/impl/http/option \
						src/tbox/network/impl/http/status \
						src/tbox/network/impl/network \
						src/tbox/network/ipaddr \
						src/tbox/network/ipv4 \
						src/tbox/network/ipv6 \
						src/tbox/network/url \
						src/tbox/algorithm/binary_find \
						src/tbox/algorithm/binary_find_if \
						src/tbox/algorithm/bubble_sort \
						src/tbox/algorithm/count \
						src/tbox/algorithm/count_if \
						src/tbox/algorithm/distance \
						src/tbox/algorithm/find \
						src/tbox/algorithm/find_if \
						src/tbox/algorithm/heap_sort \
						src/tbox/algorithm/insert_sort \
						src/tbox/algorithm/predicate \
						src/tbox/algorithm/quick_sort \
						src/tbox/algorithm/remove \
						src/tbox/algorithm/remove_first \
						src/tbox/algorithm/remove_first_if \
						src/tbox/algorithm/remove_if \
						src/tbox/algorithm/rfind \
						src/tbox/algorithm/rfind_if \
						src/tbox/algorithm/rwalk \
						src/tbox/algorithm/sort \
						src/tbox/algorithm/walk \
						src/tbox/container/bloom_filter \
						src/tbox/container/circle_queue \
						src/tbox/container/element/hash \
						src/tbox/container/element/long \
						src/tbox/container/element/mem \
						src/tbox/container/element/null \
						src/tbox/container/element/ptr \
						src/tbox/container/element/size \
						src/tbox/container/element/str \
						src/tbox/container/element/true \
						src/tbox/container/element/uint16 \
						src/tbox/container/element/uint32 \
						src/tbox/container/element/uint8 \
						src/tbox/container/hash_map \
						src/tbox/container/hash_set \
						src/tbox/container/heap \
						src/tbox/container/iterator/long \
						src/tbox/container/iterator/mem \
						src/tbox/container/iterator/ptr \
						src/tbox/container/iterator/size \
						src/tbox/container/iterator/str \
						src/tbox/container/iterator \
						src/tbox/container/list \
						src/tbox/container/list_entry \
						src/tbox/container/priority_queue \
						src/tbox/container/queue \
						src/tbox/container/single_list \
						src/tbox/container/single_list_entry \
						src/tbox/container/stack \
						src/tbox/container/vector \
						src/tbox/libm/impl/libm \
						src/tbox/libm/ilog2i \
						src/tbox/libm/isqrti \
						src/tbox/libm/idivi8 \
						src/tbox/platform/addrinfo \
						src/tbox/platform/atomic64 \
						src/tbox/platform/backtrace \
						src/tbox/platform/cache_time \
						src/tbox/platform/directory \
						src/tbox/platform/dynamic \
						src/tbox/platform/environment \
						src/tbox/platform/event \
						src/tbox/platform/file \
						src/tbox/platform/hostname \
						src/tbox/platform/ifaddrs \
						src/tbox/platform/ltimer \
						src/tbox/platform/memory \
						src/tbox/platform/mutex \
						src/tbox/platform/page \
						src/tbox/platform/path \
						src/tbox/platform/poller \
						src/tbox/platform/print \
						src/tbox/platform/process \
						src/tbox/platform/processor \
						src/tbox/platform/sched \
						src/tbox/platform/semaphore \
						src/tbox/platform/socket \
						src/tbox/platform/syserror \
						src/tbox/platform/thread \
						src/tbox/platform/thread_local \
						src/tbox/platform/time \
						src/tbox/platform/timer \
						src/tbox/platform/impl/dns \
						src/tbox/platform/impl/platform \
						src/tbox/libm/isfin \
						src/tbox/libm/isfinf \
						src/tbox/libm/isinf \
						src/tbox/libm/isinff \
						src/tbox/libm/isnan \
						src/tbox/libm/isnanf \
						src/tbox/libm/pow \
						src/tbox/libm/cos \
						src/tbox/libm/cosf \
						src/tbox/libm/sqrtf \
						src/tbox/hash/sha \
						src/tbox/hash/uuid \
						src/tbox/charset/charset \
						src/tbox/charset/ascii \
						src/tbox/charset/gb2312 \
						src/tbox/charset/utf8 \
						src/tbox/charset/utf16 \
						src/tbox/charset/utf32 \
						src/tbox/charset/ucs2 \
						src/tbox/charset/ucs4 \
						src/tbox/charset/iso8859 


ifeq ($(PLAT),windows)
tbox_C_FILES 			+= \
						src\tbox\platform\windows\socket_pool
						src\tbox\platform\windows\interface\dbghelp
						src\tbox\platform\windows\interface\interface
						src\tbox\platform\windows\interface\iphlpapi
						src\tbox\platform\windows\interface\kernel32
						src\tbox\platform\windows\interface\mswsock
						src\tbox\platform\windows\interface\ole32
						src\tbox\platform\windows\interface\shell32
						src\tbox\platform\windows\interface\user32
						src\tbox\platform\windows\interface\ws2_32
endif

# includes
tbox_INC_DIRS 			+= \
						src \
						inc/$(PLAT)

										
# suffix
include $(PRO_DIR)/suffix.mak

