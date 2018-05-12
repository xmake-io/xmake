
#include <stddef.h>
#include <stdarg.h>
#define WIN9X_COMPAT_SPINLOCK
#include "ntddk.h"
#include <wdf.h>
#define NTSTRSAFE_LIB
#include <ntstrsafe.h>
#include "ntddser.h"
#include <wmilib.h>
#include <initguid.h> // required for GUID definitions
#include <wmidata.h>
#include "serial.h"
#include "serialp.h"
#include "serlog.h"
#include "log.h"
#include "trace.h"

