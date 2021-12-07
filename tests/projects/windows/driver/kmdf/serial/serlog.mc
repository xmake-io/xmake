;/*++ BUILD Version: 0001    // Increment this if a change has global effects
;
;Copyright (c) 1992, 1993  Microsoft Corporation
;
;Module Name:
;
;    ntiologc.h
;
;Abstract:
;
;    Constant definitions for the I/O error code log values.
;
;--*/
;
;#ifndef _SERLOG_
;#define _SERLOG_
;
;//
;//  Status values are 32 bit values layed out as follows:
;//
;//   3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1
;//   1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
;//  +---+-+-------------------------+-------------------------------+
;//  |Sev|C|       Facility          |               Code            |
;//  +---+-+-------------------------+-------------------------------+
;//
;//  where
;//
;//      Sev - is the severity code
;//
;//          00 - Success
;//          01 - Informational
;//          10 - Warning
;//          11 - Error
;//
;//      C - is the Customer code flag
;//
;//      Facility - is the facility code
;//
;//      Code - is the facility's status code
;//
;
MessageIdTypedef=NTSTATUS

SeverityNames=(Success=0x0:STATUS_SEVERITY_SUCCESS
               Informational=0x1:STATUS_SEVERITY_INFORMATIONAL
               Warning=0x2:STATUS_SEVERITY_WARNING
               Error=0x3:STATUS_SEVERITY_ERROR
              )

FacilityNames=(System=0x0
               RpcRuntime=0x2:FACILITY_RPC_RUNTIME
               RpcStubs=0x3:FACILITY_RPC_STUBS
               Io=0x4:FACILITY_IO_ERROR_CODE
               Serial=0x6:FACILITY_SERIAL_ERROR_CODE
              )


MessageId=0x0001 Facility=Serial Severity=Informational SymbolicName=SERIAL_KERNEL_DEBUGGER_ACTIVE
Language=English
The kernel debugger is already using %2.
.

MessageId=0x0002 Facility=Serial Severity=Informational SymbolicName=SERIAL_FIFO_PRESENT
Language=English
While validating that %2 was really a serial port, a fifo was detected. The fifo will be used.
.

MessageId=0x0003 Facility=Serial Severity=Informational SymbolicName=SERIAL_USER_OVERRIDE
Language=English
User configuration data for parameter %2 overriding firmware configuration data.
.

MessageId=0x0004 Facility=Serial Severity=Warning SymbolicName=SERIAL_NO_SYMLINK_CREATED
Language=English
Unable to create the symbolic link for %2.
.

MessageId=0x0005 Facility=Serial Severity=Warning SymbolicName=SERIAL_NO_DEVICE_MAP_CREATED
Language=English
Unable to create the device map entry for %2.
.

MessageId=0x0006 Facility=Serial Severity=Warning SymbolicName=SERIAL_NO_DEVICE_MAP_DELETED
Language=English
Unable to delete the device map entry for %2.
.

MessageId=0x0007 Facility=Serial Severity=Error SymbolicName=SERIAL_UNREPORTED_IRQL_CONFLICT
Language=English
Another driver on the system, which did not report its resources, has already claimed the interrupt used by %2.
.

MessageId=0x0008 Facility=Serial Severity=Error SymbolicName=SERIAL_INSUFFICIENT_RESOURCES
Language=English
Not enough resources were available for the driver.
.

MessageId=0x0009 Facility=Serial Severity=Error SymbolicName=SERIAL_UNSUPPORTED_CLOCK_RATE
Language=English
The baud clock rate configuration is not supported on device %2.
.

MessageId=0x000A Facility=Serial Severity=Error SymbolicName=SERIAL_REGISTERS_NOT_MAPPED
Language=English
The hardware locations for %2 could not be translated to something the memory management system could understand.
.

MessageId=0x000B Facility=Serial Severity=Error SymbolicName=SERIAL_RESOURCE_CONFLICT
Language=English
The hardware resources for %2 are already in use by another device.
.

MessageId=0x000C Facility=Serial Severity=Error SymbolicName=SERIAL_NO_BUFFER_ALLOCATED
Language=English
No memory could be allocated in which to place new data for %2.
.

MessageId=0x000D Facility=Serial Severity=Error SymbolicName=SERIAL_IER_INVALID
Language=English
While validating that %2 was really a serial port, the interrupt enable register contained enabled bits in a must be zero bitfield.
The device is assumed not to be a serial port and will be deleted.
.

MessageId=0x000E Facility=Serial Severity=Error SymbolicName=SERIAL_MCR_INVALID
Language=English
While validating that %2 was really a serial port, the modem control register contained enabled bits in a must be zero bitfield.
The device is assumed not to be a serial port and will be deleted.
.

MessageId=0x000F Facility=Serial Severity=Error SymbolicName=SERIAL_IIR_INVALID
Language=English
While validating that %2 was really a serial port, the interrupt id register contained enabled bits in a must be zero bitfield.
The device is assumed not to be a serial port and will be deleted.
.

MessageId=0x0010 Facility=Serial Severity=Error SymbolicName=SERIAL_DL_INVALID
Language=English
While validating that %2 was really a serial port, the baud rate register could not be set consistantly.
The device is assumed not to be a serial port and will be deleted.
.

MessageId=0x0011 Facility=Serial Severity=Error SymbolicName=SERIAL_NOT_ENOUGH_CONFIG_INFO
Language=English
Some firmware configuration information was incomplete.
.

MessageId=0x0012 Facility=Serial Severity=Error SymbolicName=SERIAL_NO_PARAMETERS_INFO
Language=English
No Parameters subkey was found for user defined data.  This is odd, and it also means no user configuration can be found.
.

MessageId=0x0013 Facility=Serial Severity=Error SymbolicName=SERIAL_UNABLE_TO_ACCESS_CONFIG
Language=English
Specific user configuration data is unretrievable.
.

MessageId=0x0014 Facility=Serial Severity=Error SymbolicName=SERIAL_INVALID_PORT_INDEX
Language=English
On parameter %2 which indicates a multiport card, must have a port index specified greater than 0.
.

MessageId=0x0015 Facility=Serial Severity=Error SymbolicName=SERIAL_PORT_INDEX_TOO_HIGH
Language=English
On parameter %2 which indicates a multiport card, the port index for the multiport card is too large.
.

MessageId=0x0016 Facility=Serial Severity=Error SymbolicName=SERIAL_UNKNOWN_BUS
Language=English
The bus type for %2 is not recognizable.
.

MessageId=0x0017 Facility=Serial Severity=Error SymbolicName=SERIAL_BUS_NOT_PRESENT
Language=English
The bus type for %2 is not available on this computer.
.

MessageId=0x0018 Facility=Serial Severity=Error SymbolicName=SERIAL_BUS_INTERRUPT_CONFLICT
Language=English
The bus specified for %2 does not support the specified method of interrupt.
.

MessageId=0x0019 Facility=Serial Severity=Error SymbolicName=SERIAL_INVALID_USER_CONFIG
Language=English
User configuration for parameter %2 must have %3.
.

MessageId=0x001A Facility=Serial Severity=Error SymbolicName=SERIAL_DEVICE_TOO_HIGH
Language=English
The user specified port for %2 is way too high in physical memory.
.

MessageId=0x001B Facility=Serial Severity=Error SymbolicName=SERIAL_STATUS_TOO_HIGH
Language=English
The status port for %2 is way too high in physical memory.
.

MessageId=0x001C Facility=Serial Severity=Error SymbolicName=SERIAL_STATUS_CONTROL_CONFLICT
Language=English
The status port for %2 overlaps the control registers for the device.
.

MessageId=0x001D Facility=Serial Severity=Error SymbolicName=SERIAL_CONTROL_OVERLAP
Language=English
The control registers for %2 overlaps with the %3 control registers.
.

MessageId=0x001E Facility=Serial Severity=Error SymbolicName=SERIAL_STATUS_OVERLAP
Language=English
The status register for %2 overlaps the %3 control registers.
.

MessageId=0x001F Facility=Serial Severity=Error SymbolicName=SERIAL_STATUS_STATUS_OVERLAP
Language=English
The status register for %2 overlaps with the %3 status register.
.

MessageId=0x0020 Facility=Serial Severity=Error SymbolicName=SERIAL_CONTROL_STATUS_OVERLAP
Language=English
The control registers for %2 overlaps the %3 status register.
.

MessageId=0x0021 Facility=Serial Severity=Error SymbolicName=SERIAL_MULTI_INTERRUPT_CONFLICT
Language=English
Two ports, %2 and %3, on a single multiport card can't have two different interrupts.
.

MessageId=0x0022 Facility=Serial Severity=Informational SymbolicName=SERIAL_DISABLED_PORT
Language=English
Disabling %2 as requested by the configuration data.
.

MessageId=0x0023 Facility=Serial Severity=Error SymbolicName=SERIAL_GARBLED_PARAMETER
Language=English
Parameter %2 data is unretrievable from the registry.
.

MessageId=0x0024 Facility=Serial Severity=Error SymbolicName=SERIAL_DLAB_INVALID
Language=English
While validating that %2 was really a serial port, the contents of the divisor latch register was identical to the interrupt enable and the receive registers.
The device is assumed not to be a serial port and will be deleted.
.

MessageId=0x0025 Facility=Serial Severity=Error SymbolicName=SERIAL_NO_TRANSLATE_PORT
Language=English
Could not translate the user reported I/O port for %2.
.

MessageId=0x0026 Facility=Serial Severity=Error SymbolicName=SERIAL_NO_GET_INTERRUPT
Language=English
Could not get the user reported interrupt for %2 from the HAL.
.

MessageId=0x0027 Facility=Serial Severity=Error SymbolicName=SERIAL_NO_TRANSLATE_ISR
Language=English
Could not translate the user reported Interrupt Status Register for %2.
.

MessageId=0x0028 Facility=Serial Severity=Error SymbolicName=SERIAL_NO_DEVICE_REPORT
Language=English
Could not report the discovered legacy device %2 to the IO subsystem.
.

MessageId=0x0029 Facility=Serial Severity=Error SymbolicName=SERIAL_REGISTRY_WRITE_FAILED
Language=English
Error writing to the registry.
.

MessageId=0x002A Facility=Serial Severity=Warning SymbolicName=SERIAL_MOUSE_CONFLICT_IRQ
Language=English
There is a serial mouse using the same interrupt as %2.  Therefore, %2 will not be started.
.

MessageId=0x002B Facility=Serial Severity=Warning SymbolicName=SERIAL_MOUSE_ON_PORT
Language=English
There was a serial mouse found on %2.  Therefore, %2 will be assigned to the mouse.
.

MessageId=0x002C Facility=Serial Severity=Error SymbolicName=SERIAL_NO_DEVICE_REPORT_RES
Language=English
Could not report device %2 to IO subsystem due to a resource conflict.
.

MessageId=0x002D Facility=Serial Severity=Error SymbolicName=SERIAL_HARDWARE_FAILURE
Language=English
The serial driver detected a hardware failure on device %2 and will disable this device.
.

;#endif /* _NTIOLOGC_ */

