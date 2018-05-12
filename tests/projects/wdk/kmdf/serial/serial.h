/*++

Copyright (c) 1990, 1991, 1992, 1993 - 1997 Microsoft Corporation

Module Name :

    serial.h

Abstract:

    Type definitions and data for the serial port driver

--*/

#define POOL_TAG 'XMOC'


//
// Some default driver values.  We will check the registry for
// them first.
//
#define SERIAL_UNINITIALIZED_DEFAULT    1234567
#define SERIAL_FORCE_FIFO_DEFAULT       1
#define SERIAL_RX_FIFO_DEFAULT          8
#define SERIAL_TX_FIFO_DEFAULT          14
#define SERIAL_PERMIT_SHARE_DEFAULT     0
#define SERIAL_LOG_FIFO_DEFAULT         0


//
// This define gives the default Object directory
// that we should use to insert the symbolic links
// between the NT device name and namespace used by
// that object directory.
#define DEFAULT_DIRECTORY L"DosDevices"

//
// For the above directory, the serial port will
// use the following name as the suffix of the serial
// ports for that directory.  It will also append
// a number onto the end of the name.  That number
// will start at 1.
#define DEFAULT_SERIAL_NAME L"COM"
//
//
// This define gives the default NT name for
// for serial ports detected by the firmware.
// This name will be appended to Device prefix
// with a number following it.  The number is
// incremented each time encounter a serial
// port detected by the firmware.  Note that
// on a system with multiple busses, this means
// that the first port on a bus is not necessarily
// \Device\Serial0.
//
#define DEFAULT_NT_SUFFIX L"Serial"
#define _DRIVER_NAME_  "Serial.sys"

#define DEVICE_OBJECT_NAME_LENGTH       128
#define SYMBOLIC_NAME_LENGTH            128
#define SERIAL_DEVICE_MAP               L"SERIALCOMM"

//
// GUID_DEVINTERFACE_COMPORT is not defined in the Win2K
// headers, so we will need this definition to avoid compilation
// errors.
//
#define GUID_DEVINTERFACE_COMPORT GUID_CLASS_COMPORT

//
// This value - which could be redefined at compile
// time, define the stride between registers
//
#if !defined(SERIAL_REGISTER_STRIDE)
#define SERIAL_REGISTER_STRIDE 1
#endif

//
// Offsets from the base register address of the
// various registers for the 8250 family of UARTS.
//
#define RECEIVE_BUFFER_REGISTER    ((ULONG)((0x00)*SERIAL_REGISTER_STRIDE))
#define TRANSMIT_HOLDING_REGISTER  ((ULONG)((0x00)*SERIAL_REGISTER_STRIDE))
#define INTERRUPT_ENABLE_REGISTER  ((ULONG)((0x01)*SERIAL_REGISTER_STRIDE))
#define INTERRUPT_IDENT_REGISTER   ((ULONG)((0x02)*SERIAL_REGISTER_STRIDE))
#define FIFO_CONTROL_REGISTER      ((ULONG)((0x02)*SERIAL_REGISTER_STRIDE))
#define LINE_CONTROL_REGISTER      ((ULONG)((0x03)*SERIAL_REGISTER_STRIDE))
#define MODEM_CONTROL_REGISTER     ((ULONG)((0x04)*SERIAL_REGISTER_STRIDE))
#define LINE_STATUS_REGISTER       ((ULONG)((0x05)*SERIAL_REGISTER_STRIDE))
#define MODEM_STATUS_REGISTER      ((ULONG)((0x06)*SERIAL_REGISTER_STRIDE))
#define DIVISOR_LATCH_LSB          ((ULONG)((0x00)*SERIAL_REGISTER_STRIDE))
#define DIVISOR_LATCH_MSB          ((ULONG)((0x01)*SERIAL_REGISTER_STRIDE))
#define SERIAL_REGISTER_SPAN       ((ULONG)(7*SERIAL_REGISTER_STRIDE))

//
// If we have an interrupt status register this is its assumed
// length.
//
#define SERIAL_STATUS_LENGTH       ((ULONG)(1*SERIAL_REGISTER_STRIDE))

//
// Bitmask definitions for accessing the 8250 device registers.
//

//
// These bits define the number of data bits trasmitted in
// the Serial Data Unit (SDU - Start,data, parity, and stop bits)
//
#define SERIAL_DATA_LENGTH_5 0x00
#define SERIAL_DATA_LENGTH_6 0x01
#define SERIAL_DATA_LENGTH_7 0x02
#define SERIAL_DATA_LENGTH_8 0x03


//
// These masks define the interrupts that can be enabled or disabled.
//
//
// This interrupt is used to notify that there is new incomming
// data available.  The SERIAL_RDA interrupt is enabled by this bit.
//
#define SERIAL_IER_RDA   0x01

//
// This interrupt is used to notify that there is space available
// in the transmitter for another character.  The SERIAL_THR
// interrupt is enabled by this bit.
//
#define SERIAL_IER_THR   0x02

//
// This interrupt is used to notify that some sort of error occured
// with the incomming data.  The SERIAL_RLS interrupt is enabled by
// this bit.
#define SERIAL_IER_RLS   0x04

//
// This interrupt is used to notify that some sort of change has
// taken place in the modem control line.  The SERIAL_MS interrupt is
// enabled by this bit.
//
#define SERIAL_IER_MS    0x08


//
// These masks define the values of the interrupt identification
// register.  The low bit must be clear in the interrupt identification
// register for any of these interrupts to be valid.  The interrupts
// are defined in priority order, with the highest value being most
// important.  See above for a description of what each interrupt
// implies.
//
#define SERIAL_IIR_RLS      0x06
#define SERIAL_IIR_RDA      0x04
#define SERIAL_IIR_CTI      0x0c
#define SERIAL_IIR_THR      0x02
#define SERIAL_IIR_MS       0x00

//
// This bit mask get the value of the high two bits of the
// interrupt id register.  If this is a 16550 class chip
// these bits will be a one if the fifo's are enbled, otherwise
// they will always be zero.
//
#define SERIAL_IIR_FIFOS_ENABLED 0xc0

//
// If the low bit is logic one in the interrupt identification register
// this implies that *NO* interrupts are pending on the device.
//
#define SERIAL_IIR_NO_INTERRUPT_PENDING 0x01


//
// Use these bits to detect removal of serial card for Stratus implementation
//
#define SERIAL_IIR_MUST_BE_ZERO 0x30


//
// These masks define access to the fifo control register.
//

//
// Enabling this bit in the fifo control register will turn
// on the fifos.  If the fifos are enabled then the high two
// bits of the interrupt id register will be set to one.  Note
// that this only occurs on a 16550 class chip.  If the high
// two bits in the interrupt id register are not one then
// we know we have a lower model chip.
//
//
#define SERIAL_FCR_ENABLE     ((UCHAR)0x01)
#define SERIAL_FCR_RCVR_RESET ((UCHAR)0x02)
#define SERIAL_FCR_TXMT_RESET ((UCHAR)0x04)

//
// This set of values define the high water marks (when the
// interrupts trip) for the receive fifo.
//
#define SERIAL_1_BYTE_HIGH_WATER   ((UCHAR)0x00)
#define SERIAL_4_BYTE_HIGH_WATER   ((UCHAR)0x40)
#define SERIAL_8_BYTE_HIGH_WATER   ((UCHAR)0x80)
#define SERIAL_14_BYTE_HIGH_WATER  ((UCHAR)0xc0)

//
// These masks define access to the line control register.
//

//
// This defines the bit used to control the definition of the "first"
// two registers for the 8250.  These registers are the input/output
// register and the interrupt enable register.  When the DLAB bit is
// enabled these registers become the least significant and most
// significant bytes of the divisor value.
//
#define SERIAL_LCR_DLAB     0x80

//
// This defines the bit used to control whether the device is sending
// a break.  When this bit is set the device is sending a space (logic 0).
//
// Most protocols will assume that this is a hangup.
//
#define SERIAL_LCR_BREAK    0x40

//
// These defines are used to set the line control register.
//
#define SERIAL_5_DATA       ((UCHAR)0x00)
#define SERIAL_6_DATA       ((UCHAR)0x01)
#define SERIAL_7_DATA       ((UCHAR)0x02)
#define SERIAL_8_DATA       ((UCHAR)0x03)
#define SERIAL_DATA_MASK    ((UCHAR)0x03)

#define SERIAL_1_STOP       ((UCHAR)0x00)
#define SERIAL_1_5_STOP     ((UCHAR)0x04) // Only valid for 5 data bits
#define SERIAL_2_STOP       ((UCHAR)0x04) // Not valid for 5 data bits
#define SERIAL_STOP_MASK    ((UCHAR)0x04)

#define SERIAL_NONE_PARITY  ((UCHAR)0x00)
#define SERIAL_ODD_PARITY   ((UCHAR)0x08)
#define SERIAL_EVEN_PARITY  ((UCHAR)0x18)
#define SERIAL_MARK_PARITY  ((UCHAR)0x28)
#define SERIAL_SPACE_PARITY ((UCHAR)0x38)
#define SERIAL_PARITY_MASK  ((UCHAR)0x38)

//
// These masks define access the modem control register.
//

//
// This bit controls the data terminal ready (DTR) line.  When
// this bit is set the line goes to logic 0 (which is then inverted
// by normal hardware).  This is normally used to indicate that
// the device is available to be used.  Some odd hardware
// protocols (like the kernel debugger) use this for handshaking
// purposes.
//
#define SERIAL_MCR_DTR            0x01

//
// This bit controls the ready to send (RTS) line.  When this bit
// is set the line goes to logic 0 (which is then inverted by the normal
// hardware).  This is used for hardware handshaking.  It indicates that
// the hardware is ready to send data and it is waiting for the
// receiving end to set clear to send (CTS).
//
#define SERIAL_MCR_RTS            0x02

//
// This bit is used for general purpose output.
//
#define SERIAL_MCR_OUT1           0x04

//
// This bit is used for general purpose output.
//
#define SERIAL_MCR_OUT2           0x08

//
// This bit controls the loopback testing mode of the device.  Basically
// the outputs are connected to the inputs (and vice versa).
//
#define SERIAL_MCR_LOOP           0x10

//
// This bit enables auto flow control on a TI TL16C550C/TL16C550CI
//

#define SERIAL_MCR_TL16C550CAFE   0x20


//
// These masks define access to the line status register.  The line
// status register contains information about the status of data
// transfer.  The first five bits deal with receive data and the
// last two bits deal with transmission.  An interrupt is generated
// whenever bits 1 through 4 in this register are set.
//

//
// This bit is the data ready indicator.  It is set to indicate that
// a complete character has been received.  This bit is cleared whenever
// the receive buffer register has been read.
//
#define SERIAL_LSR_DR       0x01

//
// This is the overrun indicator.  It is set to indicate that the receive
// buffer register was not read befor a new character was transferred
// into the buffer.  This bit is cleared when this register is read.
//
#define SERIAL_LSR_OE       0x02

//
// This is the parity error indicator.  It is set whenever the hardware
// detects that the incoming serial data unit does not have the correct
// parity as defined by the parity select in the line control register.
// This bit is cleared by reading this register.
//
#define SERIAL_LSR_PE       0x04

//
// This is the framing error indicator.  It is set whenever the hardware
// detects that the incoming serial data unit does not have a valid
// stop bit.  This bit is cleared by reading this register.
//
#define SERIAL_LSR_FE       0x08

//
// This is the break interrupt indicator.  It is set whenever the data
// line is held to logic 0 for more than the amount of time it takes
// to send one serial data unit.  This bit is cleared whenever the
// this register is read.
//
#define SERIAL_LSR_BI       0x10

//
// This is the transmit holding register empty indicator.  It is set
// to indicate that the hardware is ready to accept another character
// for transmission.  This bit is cleared whenever a character is
// written to the transmit holding register.
//
#define SERIAL_LSR_THRE     0x20

//
// This bit is the transmitter empty indicator.  It is set whenever the
// transmit holding buffer is empty and the transmit shift register
// (a non-software accessable register that is used to actually put
// the data out on the wire) is empty.  Basically this means that all
// data has been sent.  It is cleared whenever the transmit holding or
// the shift registers contain data.
//
#define SERIAL_LSR_TEMT     0x40

//
// This bit indicates that there is at least one error in the fifo.
// The bit will not be turned off until there are no more errors
// in the fifo.
//
#define SERIAL_LSR_FIFOERR  0x80


//
// These masks are used to access the modem status register.
// Whenever one of the first four bits in the modem status
// register changes state a modem status interrupt is generated.
//

//
// This bit is the delta clear to send.  It is used to indicate
// that the clear to send bit (in this register) has *changed*
// since this register was last read by the CPU.
//
#define SERIAL_MSR_DCTS     0x01

//
// This bit is the delta data set ready.  It is used to indicate
// that the data set ready bit (in this register) has *changed*
// since this register was last read by the CPU.
//
#define SERIAL_MSR_DDSR     0x02

//
// This is the trailing edge ring indicator.  It is used to indicate
// that the ring indicator input has changed from a low to high state.
//
#define SERIAL_MSR_TERI     0x04

//
// This bit is the delta data carrier detect.  It is used to indicate
// that the data carrier bit (in this register) has *changed*
// since this register was last read by the CPU.
//
#define SERIAL_MSR_DDCD     0x08

//
// This bit contains the (complemented) state of the clear to send
// (CTS) line.
//
#define SERIAL_MSR_CTS      0x10

//
// This bit contains the (complemented) state of the data set ready
// (DSR) line.
//
#define SERIAL_MSR_DSR      0x20

//
// This bit contains the (complemented) state of the ring indicator
// (RI) line.
//
#define SERIAL_MSR_RI       0x40

//
// This bit contains the (complemented) state of the data carrier detect
// (DCD) line.
//
#define SERIAL_MSR_DCD      0x80

//
// This should be more than enough space to hold then
// numeric suffix of the device name.
//
#define DEVICE_NAME_DELTA 20


//
// Up to 16 Ports Per card.  However for sixteen
// port cards the interrupt status register must me
// the indexing kind rather then the bitmask kind.
//
//
#define SERIAL_MAX_PORTS_INDEXED (16)
#define SERIAL_MAX_PORTS_NONINDEXED (8)

typedef struct _CONFIG_DATA {
    PHYSICAL_ADDRESS    Controller;
    PHYSICAL_ADDRESS    TrController;
    ULONG               SpanOfController;
    ULONG               ClockRate;
    ULONG               AddressSpace;
    ULONG               DisablePort;
    ULONG               ForceFifoEnable;
    ULONG               RxFIFO;
    ULONG               TxFIFO;
    ULONG               PermitShare;
    ULONG               PermitSystemWideShare;
    ULONG               LogFifo;
    KINTERRUPT_MODE     InterruptMode;
    ULONG               TrVector;
    ULONG               TrIrql;
    KAFFINITY           Affinity;
    ULONG               TL16C550CAFC;
    } CONFIG_DATA,*PCONFIG_DATA;


//
// This structure contains configuration data, much of which
// is read from the registry.
//
typedef struct _SERIAL_FIRMWARE_DATA {
    PDRIVER_OBJECT  DriverObject;
    ULONG           ControllersFound;
    ULONG           ForceFifoEnableDefault;
    ULONG           DebugLevel;
    ULONG           ShouldBreakOnEntry;
    ULONG           RxFIFODefault;
    ULONG           TxFIFODefault;
    ULONG           PermitShareDefault;
    ULONG           PermitSystemWideShare;
    ULONG           LogFifoDefault;
    ULONG           UartRemovalDetect;
    UNICODE_STRING  Directory;
    UNICODE_STRING  NtNameSuffix;
    UNICODE_STRING  DirectorySymbolicName;
    LIST_ENTRY      ConfigList;
} SERIAL_FIRMWARE_DATA,*PSERIAL_FIRMWARE_DATA;

//
// Default xon/xoff characters.
//
#define SERIAL_DEF_XON 0x11
#define SERIAL_DEF_XOFF 0x13

//
// Reasons that recption may be held up.
//
#define SERIAL_RX_DTR       ((ULONG)0x01)
#define SERIAL_RX_XOFF      ((ULONG)0x02)
#define SERIAL_RX_RTS       ((ULONG)0x04)
#define SERIAL_RX_DSR       ((ULONG)0x08)

//
// Reasons that transmission may be held up.
//
#define SERIAL_TX_CTS       ((ULONG)0x01)
#define SERIAL_TX_DSR       ((ULONG)0x02)
#define SERIAL_TX_DCD       ((ULONG)0x04)
#define SERIAL_TX_XOFF      ((ULONG)0x08)
#define SERIAL_TX_BREAK     ((ULONG)0x10)

//
// These values are used by the routines that can be used
// to complete a read (other than interval timeout) to indicate
// to the interval timeout that it should complete.
//
#define SERIAL_COMPLETE_READ_CANCEL ((LONG)-1)
#define SERIAL_COMPLETE_READ_TOTAL ((LONG)-2)
#define SERIAL_COMPLETE_READ_COMPLETE ((LONG)-3)

//
// These are default values that shouldn't appear in the registry
//
#define SERIAL_BAD_VALUE ((ULONG)-1)


typedef struct _SERIAL_DEVICE_STATE {
   //
   // TRUE if we need to set the state to open
   // on a powerup
   //

   BOOLEAN Reopen;

   //
   // Hardware registers
   //

   UCHAR IER;
   // FCR is known by other values
   UCHAR LCR;
   UCHAR MCR;
   // LSR is never written
   // MSR is never written
   // SCR is either scratch or interrupt status


} SERIAL_DEVICE_STATE, *PSERIAL_DEVICE_STATE;


typedef
UCHAR
(*PREAD_PORT_UCHAR)(
    IN UCHAR *Register
    );

typedef
VOID
(*PWRITE_PORT_UCHAR)(
    IN UCHAR *Register,
    IN UCHAR  Value
    );

typedef struct _SERIAL_DEVICE_EXTENSION {
    //
    // WDF device handle
    //
    WDFDEVICE WdfDevice;
    //
    // Points to the device object that contains
    // this device extension.
    //
    PDEVICE_OBJECT DeviceObject;
    //
    // We keep a pointer around to our device name for dumps
    // and for creating "external" symbolic links to this
    // device.
    //
    UNICODE_STRING DeviceName;
    //
    // Pointer to the driver object
    //

    PDRIVER_OBJECT DriverObject;

    //
    // Records whether we actually created the symbolic link name
    // at driver load time.  If we didn't create it, we won't try
    // to destroy it when we unload.
    //
    BOOLEAN CreatedSymbolicLink;

    //
    // Records whether we actually created an entry in SERIALCOMM
    // at driver load time.  If we didn't create it, we won't try
    // to destroy it when the device is removed.
    //
    BOOLEAN CreatedSerialCommEntry;

    //
    // Did we update system count for serial ports
    //
    BOOLEAN    IsSystemConfigInfoUpdated;

    //
    // Should we expose external interfaces?
    //
    ULONG SkipNaming;

    //
    // Support the TI TL16C550C and TL16C550CI auto flow control
    //

    ULONG TL16C550CAFC;

    //
    // Detect removed hardware in intterrupt routine flag
    //
    ULONG UartRemovalDetect;

    //
    // We keep track of whether the somebody has the device currently
    // opened with a simple boolean.  We need to know this so that
    // spurious interrupts from the device (especially during initialization)
    // will be ignored.  This value is only accessed in the ISR and
    // is only set via synchronization routines.  We may be able
    // to get rid of this boolean when the code is more fleshed out.
    //
    BOOLEAN DeviceIsOpened;

    //
    // Current state during powerdown
    //

    SERIAL_DEVICE_STATE DeviceState;

    //
    // TRUE if we own power policy
    //

    BOOLEAN OwnsPowerPolicy;

    //
    // TRUE if we should retain power on close and not aggressively
    // reduce power consumption
    //

    BOOLEAN RetainPowerOnClose;

    //
    // Should we enable wakeup
    //

    BOOLEAN IsWakeEnabled;

    //
    // This list head is used to contain the time ordered list
    // of read requests.  Access to this list is protected by
    // the global cancel spinlock.
    //
    WDFQUEUE ReadQueue;

    //
    // This list head is used to contain the time ordered list
    // of write requests.  Access to this list is protected by
    // the global cancel spinlock.
    //
    WDFQUEUE WriteQueue;

    //
    // This list head is used to contain the time ordered list
    // of set and wait mask requests.  Access to this list is protected by
    // the global cancel spinlock.
    //
    WDFQUEUE MaskQueue;

    //
    // Holds the serialized list of purge requests.
    //
    WDFQUEUE PurgeQueue;

    //
    // This points to the request that is currently being processed
    // for the read queue.  This field is initialized by the open to
    // NULL.
    //
    // This value is only set at dispatch level.  It may be
    // read at interrupt level.
    //
    WDFREQUEST CurrentReadRequest;

    //
    // This points to the request that is currently being processed
    // for the write queue.
    //
    // This value is only set at dispatch level.  It may be
    // read at interrupt level.
    //
    WDFREQUEST CurrentWriteRequest;

    //
    // Points to the request that is currently being processed to
    // affect the wait mask operations.
    //
    WDFREQUEST CurrentMaskRequest;

    //
    // Points to the request that is currently being processed to
    // purge the read/write queues and buffers.
    //
    WDFREQUEST CurrentPurgeRequest;

    //
    // Points to the current request that is waiting on a comm event.
    //
    WDFREQUEST CurrentWaitRequest;

    //
    // Points to the request that is being used to send an immediate
    // character.
    //
    WDFREQUEST CurrentImmediateRequest;

    //
    // Points to the request that is being used to count the number
    // of characters received after an xoff (as currently defined
    // by the IOCTL_SERIAL_XOFF_COUNTER ioctl) is sent.
    //
    WDFREQUEST CurrentXoffRequest;

    //
    // The base address for the set of device registers
    // of the serial port.
    //
    PUCHAR Controller;
    //
    // This value holds the span (in units of bytes) of the register
    // set controlling this port.  This is constant over the life
    // of the port.
    //
    ULONG SpanOfController;

    //
    // Address space
    //

    ULONG AddressSpace;

    PREAD_PORT_UCHAR SerialReadUChar;
    PWRITE_PORT_UCHAR SerialWriteUChar;

    //
    // Hold the clock rate input to the serial part.
    //
    ULONG ClockRate;

    //
    // The number of characters to push out if a fifo is present.
    //
    ULONG TxFifoAmount;

    //
    // Set to indicate that it is ok to share interrupts within the device.
    //
    ULONG PermitShare;


    //
    // Points to the interrupt object for used by this device.
    //
    WDFINTERRUPT WdfInterrupt;

    //
    // Translated vector
    //
    ULONG Vector;
    //
    // Translated Irql
    //
    KIRQL Irql;

    KINTERRUPT_MODE     InterruptMode;

    KAFFINITY           Affinity;

    //
    // This value is set by the read code to hold the time value
    // used for read interval timing.  We keep it in the extension
    // so that the interval timer dpc routine determine if the
    // interval time has passed for the IO.
    //
    LARGE_INTEGER IntervalTime;

    //
    // These two values hold the "constant" time that we should use
    // to delay for the read interval time.
    //
    LARGE_INTEGER ShortIntervalAmount;
    LARGE_INTEGER LongIntervalAmount;

    //
    // This holds the value that we use to determine if we should use
    // the long interval delay or the short interval delay.
    //
    LARGE_INTEGER CutOverAmount;

    //
    // This holds the system time when we last time we had
    // checked that we had actually read characters.  Used
    // for interval timing.
    //
    LARGE_INTEGER LastReadTime;


    //
    // This points the the delta time that we should use to
    // delay for interval timing.
    //
    PLARGE_INTEGER IntervalTimeToUse;


    //
    // Set at intialization to indicate that on the current
    // architecture we need to unmap the base register address
    // when we unload the driver.
    //
    BOOLEAN UnMapRegisters;

    //
    // Holds the number of bytes remaining in the current write
    // request.
    //
    // This location is only accessed while at interrupt level.
    //
    ULONG WriteLength;

    //
    // Holds a pointer to the current character to be sent in
    // the current write.
    //
    // This location is only accessed while at interrupt level.
    //
    PUCHAR WriteCurrentChar;

    //
    // This is a buffer for the read processing.
    //
    // The buffer works as a ring.  When the character is read from
    // the device it will be place at the end of the ring.
    //
    // Characters are only placed in this buffer at interrupt level
    // although character may be read at any level. The pointers
    // that manage this buffer may not be updated except at interrupt
    // level.
    //
    PUCHAR InterruptReadBuffer;

    //
    // This is a pointer to the first character of the buffer into
    // which the interrupt service routine is copying characters.
    //
    PUCHAR ReadBufferBase;

    //
    // This is a count of the number of characters in the interrupt
    // buffer.  This value is set and read at interrupt level.  Note
    // that this value is only *incremented* at interrupt level so
    // it is safe to read it at any level.  When characters are
    // copied out of the read buffer, this count is decremented by
    // a routine that synchronizes with the ISR.
    //
    ULONG CharsInInterruptBuffer;

    //
    // Points to the first available position for a newly received
    // character.  This variable is only accessed at interrupt level and
    // buffer initialization code.
    //
    PUCHAR CurrentCharSlot;

    //
    // This variable is used to contain the last available position
    // in the read buffer.  It is updated at open and at interrupt
    // level when switching between the users buffer and the interrupt
    // buffer.
    //
    PUCHAR LastCharSlot;

    //
    // This marks the first character that is available to satisfy
    // a read request.  Note that while this always points to valid
    // memory, it may not point to a character that can be sent to
    // the user.  This can occur when the buffer is empty.
    //
    PUCHAR FirstReadableChar;

    //
    // Pointer to the lock variable returned for this extension when
    // locking down the driver
    //
    PVOID LockPtr;


    //
    // This variable holds the size of whatever buffer we are currently
    // using.
    //
    ULONG BufferSize;

    //
    // This variable holds .8 of BufferSize. We don't want to recalculate
    // this real often - It's needed when so that an application can be
    // "notified" that the buffer is getting full.
    //
    ULONG BufferSizePt8;

    //
    // This value holds the number of characters desired for a
    // particular read.  It is initially set by read length in the
    // WDFREQUEST.  It is decremented each time more characters are placed
    // into the "users" buffer buy the code that reads characters
    // out of the typeahead buffer into the users buffer.  If the
    // typeahead buffer is exhausted by the read, and the reads buffer
    // is given to the isr to fill, this value is becomes meaningless.
    //
    ULONG NumberNeededForRead;

    //
    // This mask will hold the bitmask sent down via the set mask
    // ioctl.  It is used by the interrupt service routine to determine
    // if the occurence of "events" (in the serial drivers understanding
    // of the concept of an event) should be noted.
    //
    ULONG IsrWaitMask;

    //
    // This mask will always be a subset of the IsrWaitMask.  While
    // at device level, if an event occurs that is "marked" as interesting
    // in the IsrWaitMask, the driver will turn on that bit in this
    // history mask.  The driver will then look to see if there is a
    // request waiting for an event to occur.  If there is one, it
    // will copy the value of the history mask into the wait request, zero
    // the history mask, and complete the wait request.  If there is no
    // waiting request, the driver will be satisfied with just recording
    // that the event occured.  If a wait request should be queued,
    // the driver will look to see if the history mask is non-zero.  If
    // it is non-zero, the driver will copy the history mask into the
    // request, zero the history mask, and then complete the request.
    //
    ULONG HistoryMask;

    //
    // This is a pointer to the where the history mask should be
    // placed when completing a wait.  It is only accessed at
    // device level.
    //
    // We have a pointer here to assist us to synchronize completing a wait.
    // If this is non-zero, then we have wait outstanding, and the isr still
    // knows about it.  We make this pointer null so that the isr won't
    // attempt to complete the wait.
    //
    // We still keep a pointer around to the wait request, since the actual
    // pointer to the wait request will be used for the "common" request completion
    // path.
    //
    ULONG *IrpMaskLocation;

    //
    // This mask holds all of the reason that transmission
    // is not proceeding.  Normal transmission can not occur
    // if this is non-zero.
    //
    // This is only written from interrupt level.
    // This could be (but is not) read at any level.
    //
    ULONG TXHolding;

    //
    // This mask holds all of the reason that reception
    // is not proceeding.  Normal reception can not occur
    // if this is non-zero.
    //
    // This is only written from interrupt level.
    // This could be (but is not) read at any level.
    //
    ULONG RXHolding;

    //
    // This holds the reasons that the driver thinks it is in
    // an error state.
    //
    // This is only written from interrupt level.
    // This could be (but is not) read at any level.
    //
    ULONG ErrorWord;

    //
    // This keeps a total of the number of characters that
    // are in all of the "write" irps that the driver knows
    // about.  It is only accessed with the cancel spinlock
    // held.
    //
    ULONG TotalCharsQueued;

    //
    // This holds a count of the number of characters read
    // the last time the interval timer dpc fired.  It
    // is a long (rather than a ulong) since the other read
    // completion routines use negative values to indicate
    // to the interval timer that it should complete the read
    // if the interval timer DPC was lurking in some DPC queue when
    // some other way to complete occurs.
    //
    LONG CountOnLastRead;

    //
    // This is a count of the number of characters read by the
    // isr routine.  It is *ONLY* written at isr level.  We can
    // read it at dispatch level.
    //
    ULONG ReadByIsr;

    //
    // This holds the current baud rate for the device.
    //
    ULONG CurrentBaud;

    //
    // This is the number of characters read since the XoffCounter
    // was started.  This variable is only accessed at device level.
    // If it is greater than zero, it implies that there is an
    // XoffCounter ioctl in the queue.
    //
    LONG CountSinceXoff;

    //
    // This ulong is incremented each time something trys to start
    // the execution path that tries to lower the RTS line when
    // doing transmit toggling.  If it "bumps" into another path
    // (indicated by a false return value from queueing a dpc
    // and a TRUE return value tring to start a timer) it will
    // decrement the count.  These increments and decrements
    // are all done at device level.  Note that in the case
    // of a bump while trying to start the timer, we have to
    // go up to device level to do the decrement.
    //
    ULONG CountOfTryingToLowerRTS;

    //
    // This ULONG is used to keep track of the "named" (in ntddser.h)
    // baud rates that this particular device supports.
    //
    ULONG SupportedBauds;

    //
    // Holds the timeout controls for the device.  This value
    // is set by the Ioctl processing.
    //
    // It should only be accessed under protection of the control
    // lock since more than one request can be in the control dispatch
    // routine at one time.
    //
    SERIAL_TIMEOUTS Timeouts;

    //
    // This holds the various characters that are used
    // for replacement on errors and also for flow control.
    //
    // They are only set at interrupt level.
    //
    SERIAL_CHARS SpecialChars;

    //
    // This structure holds the handshake and control flow
    // settings for the serial driver.
    //
    // It is only set at interrupt level.  It can be
    // be read at any level with the control lock held.
    //
    SERIAL_HANDFLOW HandFlow;


    //
    // Holds performance statistics that applications can query.
    // Reset on each open.  Only set at device level.
    //
    SERIALPERF_STATS PerfStats;

    //
    // This holds what we beleive to be the current value of
    // the line control register.
    //
    // It should only be accessed under protection of the control
    // lock since more than one request can be in the control dispatch
    // routine at one time.
    //
    UCHAR LineControl;


    //
    // This is only accessed at interrupt level.  It keeps track
    // of whether the holding register is empty.
    //
    BOOLEAN HoldingEmpty;

    //
    // This variable is only accessed at interrupt level.  It
    // indicates that we want to transmit a character immediately.
    // That is - in front of any characters that could be transmitting
    // from a normal write.
    //
    BOOLEAN TransmitImmediate;

    //
    // This variable is only accessed at interrupt level.  Whenever
    // a wait is initiated this variable is set to false.
    // Whenever any kind of character is written it is set to true.
    // Whenever the write queue is found to be empty the code that
    // is processing that completing request will synchonize with the interrupt.
    // If this synchronization code finds that the variable is true and that
    // there is a wait on the transmit queue being empty then it is
    // certain that the queue was emptied and that it has happened since
    // the wait was initiated.
    //
    BOOLEAN EmptiedTransmit;

    //
    // We keep the following values around so that we can connect
    // to the interrupt and report resources after the configuration
    // record is gone.
    //

    //
    // We hold the character that should be transmitted immediately.
    //
    // Note that we can't use this to determine whether there is
    // a character to send because the character to send could be
    // zero.
    //
    UCHAR ImmediateChar;

    //
    // This holds the mask that will be used to mask off unwanted
    // data bits of the received data (valid data bits can be 5,6,7,8)
    // The mask will normally be 0xff.  This is set while the control
    // lock is held since it wouldn't have adverse effects on the
    // isr if it is changed in the middle of reading characters.
    // (What it would do to the app is another question - but then
    // the app asked the driver to do it.)
    //
    UCHAR ValidDataMask;

    //
    // The application can turn on a mode,via the
    // IOCTL_SERIAL_LSRMST_INSERT ioctl, that will cause the
    // serial driver to insert the line status or the modem
    // status into the RX stream.  The parameter with the ioctl
    // is a pointer to a UCHAR.  If the value of the UCHAR is
    // zero, then no insertion will ever take place.  If the
    // value of the UCHAR is non-zero (and not equal to the
    // xon/xoff characters), then the serial driver will insert.
    //
    UCHAR EscapeChar;

    //
    // These two booleans are used to indicate to the isr transmit
    // code that it should send the xon or xoff character.  They are
    // only accessed at open and at interrupt level.
    //
    BOOLEAN SendXonChar;
    BOOLEAN SendXoffChar;

    //
    // This boolean will be true if a 16550 is present *and* enabled.
    //
    BOOLEAN FifoPresent;

    //
    // This is the water mark that the rxfifo should be
    // set to when the fifo is turned on.  This is not the actual
    // value, but the encoded value that goes into the register.
    //
    UCHAR RxFifoTrigger;

    //
    // This points to a DPC used to complete write requests.
    //
    WDFDPC CompleteWriteDpc;

    //
    // This points to a DPC used to complete read requests.
    //
    WDFDPC CompleteReadDpc;


    //
    // This dpc is fired off if a comm error occurs.  It will
    // execute a dpc routine that will cancel all pending reads
    // and writes.
    //
    WDFDPC CommErrorDpc;

    //
    // This dpc is fired off if an event occurs and there was
    // a request waiting on that event.  A dpc routine will execute
    // that completes the request.
    //
    WDFDPC CommWaitDpc;

    //
    // This dpc is fired off when the transmit immediate char
    // character is given to the hardware.  It will simply complete
    // the request.
    //
    WDFDPC CompleteImmediateDpc;

    //
    // This dpc is fired off if the xoff counter actually runs down
    // to zero.
    //
    WDFDPC XoffCountCompleteDpc;

    //
    // This dpc is fired off only from device level to start off
    // a timer that will queue a dpc to check if the RTS line
    // should be lowered when we are doing transmit toggling.
    //
    WDFDPC StartTimerLowerRTSDpc;

    //
    // This timer used to handle total read request timing.
    //
    WDFTIMER ReadRequestTotalTimer;

    //
    // This timer used to handle interval read request timing.
    //
    WDFTIMER ReadRequestIntervalTimer;

    //
    // This timer used to handle total write request timing.
    //
    WDFTIMER WriteRequestTotalTimer;

    //
    // This is timer structure used to handle total time request timing.
    //
    WDFTIMER ImmediateTotalTimer;

    //
    // This timer is used to timeout the xoff counter io.
    //
    WDFTIMER XoffCountTimer;

    //
    // This timer is used to invoke a dpc one character time
    // after the timer is set.  That dpc will be used to check
    // whether we should lower the RTS line if we are doing
    // transmit toggling.
    //
    WDFTIMER LowerRTSTimer;

    //
    // WMI Information
    //

    //
    // WMI Comm Data
    //

    SERIAL_WMI_COMM_DATA WmiCommData;

    //
    // WMI HW Data
    //

    SERIAL_WMI_HW_DATA WmiHwData;

    //
    // WMI Performance Data
    //

    SERIAL_WMI_PERF_DATA WmiPerfData;

} SERIAL_DEVICE_EXTENSION,*PSERIAL_DEVICE_EXTENSION;

WDF_DECLARE_CONTEXT_TYPE_WITH_NAME(SERIAL_DEVICE_EXTENSION,
                                        SerialGetDeviceExtension)

//
// This is the scratch area for every request.
// We will copy some of the frequently used information of the request
// into our context area so that way we don't have to call WdfRequestGetParams
// function everytime.
//
typedef struct _REQUEST_CONTEXT {
    ULONG_PTR Information;
    NTSTATUS Status;
    ULONG Length;
    PVOID RefCount;
    PVOID SystemBuffer;
    UCHAR MajorFunction;
    PFN_WDF_REQUEST_CANCEL CancelRoutine;
    BOOLEAN Cancelled;
    PVOID Type3InputBuffer;
    PSERIAL_DEVICE_EXTENSION Extension;
    ULONG IoctlCode;
    BOOLEAN MarkCancelableOnResume;
} REQUEST_CONTEXT, *PREQUEST_CONTEXT;


WDF_DECLARE_CONTEXT_TYPE_WITH_NAME(REQUEST_CONTEXT,
                                        SerialGetRequestContext)


//
// This is the Interrupt context for the Serial device. This structure is used
// for keeping track of whether the Interrupt is connected or not.
//
typedef struct _SERIAL_INTERRUPT_CONTEXT {

    //
    // This boolean value indicates whether Interrupt is connected.
    //
    BOOLEAN IsInterruptConnected;

    //
    // This lock is used to synchronize the file close logic and
    // the Surprise Removal logic. When a surprise remove happens,
    // the device interrupts are disabled. When this occurs, the
    // file close logic should not attempt to use the interrupt
    // object.
    //
    WDFWAITLOCK InterruptStateLock;

} SERIAL_INTERRUPT_CONTEXT, *PSERIAL_INTERRUPT_CONTEXT;

WDF_DECLARE_CONTEXT_TYPE_WITH_NAME(SERIAL_INTERRUPT_CONTEXT,
                                        SerialGetInterruptContext)


#define SERIAL_FLAGS_CLEAR                  0x0L
#define SERIAL_FLAGS_STARTED                0x1L
#define SERIAL_FLAGS_STOPPED                0x2L
#define SERIAL_FLAGS_BROKENHW               0x4L
#define SERIAL_FLAGS_LEGACY_ENUMED          0x8L


__inline
UCHAR
SerialReadPortUChar (
    IN  UCHAR * x
    )
{
    return READ_PORT_UCHAR (x);
}
__inline
VOID
SerialWritePortUChar (
    IN  UCHAR * x,
    IN  UCHAR   y
    )
{
    WRITE_PORT_UCHAR (x,y);
}

__inline
UCHAR
SerialReadRegisterUChar (
    IN  UCHAR * x
    )
{
    return READ_REGISTER_UCHAR (x);
}

__inline
VOID
SerialWriteRegisterUChar (
    IN  UCHAR * x,
    IN  UCHAR   y
    )
{
    WRITE_REGISTER_UCHAR (x,y);
}



//
// Sets the divisor latch register.  The divisor latch register
// is used to control the baud rate of the 8250.
//
// As with all of these routines it is assumed that it is called
// at a safe point to access the hardware registers.  In addition
// it also assumes that the data is correct.
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
// DesiredDivisor - The value to which the divisor latch register should
//                  be set.
//
#define WRITE_DIVISOR_LATCH(Extension, BaseAddress,DesiredDivisor)           \
do                                                                \
{                                                                 \
    PUCHAR Address = BaseAddress;                                 \
    SHORT Divisor = DesiredDivisor;                               \
    UCHAR LineControl;                                            \
    LineControl = Extension->SerialReadUChar(Address+LINE_CONTROL_REGISTER); \
    Extension->SerialWriteUChar(                                             \
        Address+LINE_CONTROL_REGISTER,                            \
        (UCHAR)(LineControl | SERIAL_LCR_DLAB)                    \
        );                                                        \
    Extension->SerialWriteUChar(                                             \
        Address+DIVISOR_LATCH_LSB,                                \
        (UCHAR)(Divisor & 0xff)                                   \
        );                                                        \
    Extension->SerialWriteUChar(                                             \
        Address+DIVISOR_LATCH_MSB,                                \
        (UCHAR)((Divisor & 0xff00) >> 8)                          \
        );                                                        \
    Extension->SerialWriteUChar(                                             \
        Address+LINE_CONTROL_REGISTER,                            \
        LineControl                                               \
        );                                                        \
} WHILE (0)

//
// Reads the divisor latch register.  The divisor latch register
// is used to control the baud rate of the 8250.
//
// As with all of these routines it is assumed that it is called
// at a safe point to access the hardware registers.  In addition
// it also assumes that the data is correct.
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
// DesiredDivisor - A pointer to the 2 byte word which will contain
//                  the value of the divisor.
//
#define READ_DIVISOR_LATCH(Extension, BaseAddress,PDesiredDivisor)           \
do                                                                \
{                                                                 \
    PUCHAR Address = BaseAddress;                                 \
    PSHORT PDivisor = PDesiredDivisor;                            \
    UCHAR LineControl;                                            \
    UCHAR Lsb;                                                    \
    UCHAR Msb;                                                    \
    LineControl = Extension->SerialReadUChar(Address+LINE_CONTROL_REGISTER); \
    Extension->SerialWriteUChar(                                             \
        Address+LINE_CONTROL_REGISTER,                            \
        (UCHAR)(LineControl | SERIAL_LCR_DLAB)                    \
        );                                                        \
    Lsb = Extension->SerialReadUChar(Address+DIVISOR_LATCH_LSB);             \
    Msb = Extension->SerialReadUChar(Address+DIVISOR_LATCH_MSB);             \
    *PDivisor = Lsb;                                              \
    *PDivisor = *PDivisor | (((USHORT)Msb) << 8);                 \
    Extension->SerialWriteUChar(                                             \
        Address+LINE_CONTROL_REGISTER,                            \
        LineControl                                               \
        );                                                        \
} WHILE (0)

//
// This macro reads the interrupt enable register.
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
#define READ_INTERRUPT_ENABLE(Extension, BaseAddress)                     \
    (Extension->SerialReadUChar((BaseAddress)+INTERRUPT_ENABLE_REGISTER))

//
// This macro writes the interrupt enable register.
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
// Values - The values to write to the interrupt enable register.
//
#define WRITE_INTERRUPT_ENABLE(Extension, BaseAddress,Values)                \
do                                                                \
{                                                                 \
    Extension->SerialWriteUChar(                                             \
        BaseAddress+INTERRUPT_ENABLE_REGISTER,                    \
        Values                                                    \
        );                                                        \
} WHILE (0)

//
// This macro disables all interrupts on the hardware.
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
//
#define DISABLE_ALL_INTERRUPTS(Extension, BaseAddress)       \
do                                                \
{                                                 \
    WRITE_INTERRUPT_ENABLE(Extension, BaseAddress,0);        \
} WHILE (0)

//
// This macro enables all interrupts on the hardware.
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
//
#define ENABLE_ALL_INTERRUPTS(Extension, BaseAddress)        \
do                                                \
{                                                 \
                                                  \
    WRITE_INTERRUPT_ENABLE(                       \
        (Extension), (BaseAddress),                            \
        (UCHAR)(SERIAL_IER_RDA | SERIAL_IER_THR | \
                SERIAL_IER_RLS | SERIAL_IER_MS)   \
        );                                        \
                                                  \
} WHILE (0)

//
// This macro reads the interrupt identification register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
// Note that this routine potententially quites a transmitter
// empty interrupt.  This is because one way that the transmitter
// empty interrupt is cleared is to simply read the interrupt id
// register.
//
//
#define READ_INTERRUPT_ID_REG(Extension, BaseAddress)                          \
    (Extension->SerialReadUChar((BaseAddress)+INTERRUPT_IDENT_REGISTER))

//
// This macro reads the modem control register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
//
#define READ_MODEM_CONTROL(Extension, BaseAddress)                          \
    (Extension->SerialReadUChar((BaseAddress)+MODEM_CONTROL_REGISTER))

//
// This macro reads the modem status register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
//
#define READ_MODEM_STATUS(Extension, BaseAddress)                          \
    (Extension->SerialReadUChar((BaseAddress)+MODEM_STATUS_REGISTER))

//
// This macro reads a value out of the receive buffer
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
//
#define READ_RECEIVE_BUFFER(Extension, BaseAddress)                          \
    (Extension->SerialReadUChar((BaseAddress)+RECEIVE_BUFFER_REGISTER))

//
// This macro reads the line status register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
//
#define READ_LINE_STATUS(Extension, BaseAddress)                          \
    (Extension->SerialReadUChar((BaseAddress)+LINE_STATUS_REGISTER))

//
// This macro writes the line control register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
//
#define WRITE_LINE_CONTROL(Extension, BaseAddress,NewLineControl)           \
do                                                               \
{                                                                \
    Extension->SerialWriteUChar(                                            \
        (BaseAddress)+LINE_CONTROL_REGISTER,                     \
        (NewLineControl)                                         \
        );                                                       \
} WHILE (0)

//
// This macro reads the line control register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
//
#define READ_LINE_CONTROL(Extension, BaseAddress)           \
    (Extension->SerialReadUChar((BaseAddress)+LINE_CONTROL_REGISTER))


//
// This macro writes to the transmit register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
// TransmitChar - The character to send down the wire.
//
//
#define WRITE_TRANSMIT_HOLDING(Extension, BaseAddress,TransmitChar)       \
do                                                             \
{                                                              \
    Extension->SerialWriteUChar(                                          \
        (BaseAddress)+TRANSMIT_HOLDING_REGISTER,               \
        (TransmitChar)                                         \
        );                                                     \
} WHILE (0)

//
// This macro writes to the transmit FIFO register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
// TransmitChars - Pointer to the characters to send down the wire.
//
// TxN - number of charactes to send.
//
//
#define WRITE_TRANSMIT_FIFO_HOLDING(Extension, BaseAddress,TransmitChars,TxN)  \
do                                                             \
{                                                              \
    WRITE_PORT_BUFFER_UCHAR(                                   \
        (BaseAddress)+TRANSMIT_HOLDING_REGISTER,               \
        (TransmitChars),                                       \
        (TxN)                                                  \
        );                                                     \
} WHILE (0)

//
// This macro writes to the control register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
// ControlValue - The value to set the fifo control register too.
//
//
#define WRITE_FIFO_CONTROL(Extension, BaseAddress,ControlValue)           \
do                                                             \
{                                                              \
    Extension->SerialWriteUChar(                                          \
        (BaseAddress)+FIFO_CONTROL_REGISTER,                   \
        (ControlValue)                                         \
        );                                                     \
} WHILE (0)

//
// This macro writes to the modem control register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located.
//
// ModemControl - The control bits to send to the modem control.
//
//
#define WRITE_MODEM_CONTROL(Extension, BaseAddress,ModemControl)          \
do                                                             \
{                                                              \
    Extension->SerialWriteUChar(                                          \
        (BaseAddress)+MODEM_CONTROL_REGISTER,                  \
        (ModemControl)                                         \
        );                                                     \
} WHILE (0)

#define WRITE_INTERRUPT_STATUS(Extension, BaseAddress,Status)  \
do                                                               \
{                                                                \
       Extension->SerialWriteUChar(BaseAddress, Status);                    \
} WHILE (0)


//
// This macro reads the interrupt status register
//
// Arguments:
//
// BaseAddress - A pointer to the address from which the hardware
//               device registers are located. BaseAddress is gotten
//               from PSERIAL_MULTIPORT_DISPATCH->InterruptStatus which
//               already has the complete address
//
// AddressSpace - Flag indicating where port is located, MMIO or IO
//                space
//
//
#define READ_INTERRUPT_STATUS(Extension, BaseAddress)  \
                      Extension->SerialReadUChar(BaseAddress))

//
// We use this to query into the registry as to whether we
// should break at driver entry.
//

extern SERIAL_FIRMWARE_DATA    driverDefaults;


//
// This is exported from the kernel.  It is used to point
// to the address that the kernel debugger is using.
//

extern PUCHAR *KdComPortInUse;


typedef enum _SERIAL_MEM_COMPARES {
    AddressesAreEqual,
    AddressesOverlap,
    AddressesAreDisjoint
    } SERIAL_MEM_COMPARES,*PSERIAL_MEM_COMPARES;

#define SERIAL_BAUD_INVALID 0xFFFFFFFF

typedef struct   _SUPPORTED_BAUD_RATES {
    UINT32 BaudRate;
    ULONG Mask;
}SUPPORTED_BAUD_RATES;

