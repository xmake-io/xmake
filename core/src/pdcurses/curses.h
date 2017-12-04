/* Public Domain Curses */

/*----------------------------------------------------------------------*
 *                              PDCurses                                *
 *----------------------------------------------------------------------*/

#ifndef __PDCURSES__
#define __PDCURSES__ 1

/*man-start**************************************************************

PDCurses definitions list:  (Only define those needed)

    XCURSES         True if compiling for X11.
    PDC_RGB         True if you want to use RGB color definitions
                    (Red = 1, Green = 2, Blue = 4) instead of BGR.
    PDC_WIDE        True if building wide-character support.
    PDC_DLL_BUILD   True if building a Win32 DLL.
    NCURSES_MOUSE_VERSION   Use the ncurses mouse API instead
                            of PDCurses' traditional mouse API.

PDCurses portable platform definitions list:

    PDC_BUILD       Defines API build version.
    PDCURSES        Enables access to PDCurses-only routines.
    XOPEN           Always true.
    SYSVcurses      True if you are compiling for SYSV portability.
    BSDcurses       True if you are compiling for BSD portability.

**man-end****************************************************************/

#define PDC_BUILD 3401
#define PDCURSES        1      /* PDCurses-only routines */
#define XOPEN           1      /* X/Open Curses routines */
#define SYSVcurses      1      /* System V Curses routines */
#define BSDcurses       1      /* BSD Curses routines */
#define CHTYPE_LONG     1      /* size of chtype; long */

/*----------------------------------------------------------------------*/

#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>             /* Required by X/Open usage below */

#ifdef PDC_WIDE
# include <wchar.h>
#endif

#if defined(__cplusplus) || defined(__cplusplus__) || defined(__CPLUSPLUS)
extern "C"
{
# define bool _bool
#endif

/*----------------------------------------------------------------------
 *
 *  PDCurses Manifest Constants
 *
 */

#ifndef FALSE
# define FALSE 0
#endif
#ifndef TRUE
# define TRUE 1
#endif
#ifndef NULL
# define NULL (void *)0
#endif
#ifndef ERR
# define ERR (-1)
#endif
#ifndef OK
# define OK 0
#endif

/*----------------------------------------------------------------------
 *
 *  PDCurses Type Declarations
 *
 */

typedef unsigned char bool;    /* PDCurses Boolean type */

#ifdef CHTYPE_LONG
# if _LP64
typedef unsigned int chtype;
# else
typedef unsigned long chtype;  /* 16-bit attr + 16-bit char */
# endif
#else
typedef unsigned short chtype; /* 8-bit attr + 8-bit char */
#endif

#ifdef PDC_WIDE
typedef chtype cchar_t;
#endif

typedef chtype attr_t;

/*----------------------------------------------------------------------
 *
 *  PDCurses Mouse Interface -- SYSVR4, with extensions
 *
 */

typedef struct
{
    int x;           /* absolute column, 0 based, measured in characters */
    int y;           /* absolute row, 0 based, measured in characters */
    short button[3]; /* state of each button */
    int changes;     /* flags indicating what has changed with the mouse */
} MOUSE_STATUS;

#define BUTTON_RELEASED         0x0000
#define BUTTON_PRESSED          0x0001
#define BUTTON_CLICKED          0x0002
#define BUTTON_DOUBLE_CLICKED   0x0003
#define BUTTON_TRIPLE_CLICKED   0x0004
#define BUTTON_MOVED            0x0005  /* PDCurses */
#define WHEEL_SCROLLED          0x0006  /* PDCurses */
#define BUTTON_ACTION_MASK      0x0007  /* PDCurses */

#define PDC_BUTTON_SHIFT        0x0008  /* PDCurses */
#define PDC_BUTTON_CONTROL      0x0010  /* PDCurses */
#define PDC_BUTTON_ALT          0x0020  /* PDCurses */
#define BUTTON_MODIFIER_MASK    0x0038  /* PDCurses */

#define MOUSE_X_POS             (Mouse_status.x)
#define MOUSE_Y_POS             (Mouse_status.y)

/*
 * Bits associated with the .changes field:
 *   3         2         1         0
 * 210987654321098765432109876543210
 *                                 1 <- button 1 has changed
 *                                10 <- button 2 has changed
 *                               100 <- button 3 has changed
 *                              1000 <- mouse has moved
 *                             10000 <- mouse position report
 *                            100000 <- mouse wheel up
 *                           1000000 <- mouse wheel down
 *                          10000000 <- mouse wheel left
 *                         100000000 <- mouse wheel right
 */

#define PDC_MOUSE_MOVED         0x0008
#define PDC_MOUSE_POSITION      0x0010
#define PDC_MOUSE_WHEEL_UP      0x0020
#define PDC_MOUSE_WHEEL_DOWN    0x0040
#define PDC_MOUSE_WHEEL_LEFT    0x0080
#define PDC_MOUSE_WHEEL_RIGHT   0x0100

#define A_BUTTON_CHANGED        (Mouse_status.changes & 7)
#define MOUSE_MOVED             (Mouse_status.changes & PDC_MOUSE_MOVED)
#define MOUSE_POS_REPORT        (Mouse_status.changes & PDC_MOUSE_POSITION)
#define BUTTON_CHANGED(x)       (Mouse_status.changes & (1 << ((x) - 1)))
#define BUTTON_STATUS(x)        (Mouse_status.button[(x) - 1])
#define MOUSE_WHEEL_UP          (Mouse_status.changes & PDC_MOUSE_WHEEL_UP)
#define MOUSE_WHEEL_DOWN        (Mouse_status.changes & PDC_MOUSE_WHEEL_DOWN)
#define MOUSE_WHEEL_LEFT        (Mouse_status.changes & PDC_MOUSE_WHEEL_LEFT)
#define MOUSE_WHEEL_RIGHT       (Mouse_status.changes & PDC_MOUSE_WHEEL_RIGHT)

/* mouse bit-masks */

#define BUTTON1_RELEASED        0x00000001L
#define BUTTON1_PRESSED         0x00000002L
#define BUTTON1_CLICKED         0x00000004L
#define BUTTON1_DOUBLE_CLICKED  0x00000008L
#define BUTTON1_TRIPLE_CLICKED  0x00000010L
#define BUTTON1_MOVED           0x00000010L /* PDCurses */

#define BUTTON2_RELEASED        0x00000020L
#define BUTTON2_PRESSED         0x00000040L
#define BUTTON2_CLICKED         0x00000080L
#define BUTTON2_DOUBLE_CLICKED  0x00000100L
#define BUTTON2_TRIPLE_CLICKED  0x00000200L
#define BUTTON2_MOVED           0x00000200L /* PDCurses */

#define BUTTON3_RELEASED        0x00000400L
#define BUTTON3_PRESSED         0x00000800L
#define BUTTON3_CLICKED         0x00001000L
#define BUTTON3_DOUBLE_CLICKED  0x00002000L
#define BUTTON3_TRIPLE_CLICKED  0x00004000L
#define BUTTON3_MOVED           0x00004000L /* PDCurses */

/* For the ncurses-compatible functions only, BUTTON4_PRESSED and 
   BUTTON5_PRESSED are returned for mouse scroll wheel up and down; 
   otherwise PDCurses doesn't support buttons 4 and 5 */

#define BUTTON4_RELEASED        0x00008000L
#define BUTTON4_PRESSED         0x00010000L
#define BUTTON4_CLICKED         0x00020000L
#define BUTTON4_DOUBLE_CLICKED  0x00040000L
#define BUTTON4_TRIPLE_CLICKED  0x00080000L

#define BUTTON5_RELEASED        0x00100000L
#define BUTTON5_PRESSED         0x00200000L
#define BUTTON5_CLICKED         0x00400000L
#define BUTTON5_DOUBLE_CLICKED  0x00800000L
#define BUTTON5_TRIPLE_CLICKED  0x01000000L

#define MOUSE_WHEEL_SCROLL      0x02000000L /* PDCurses */
#define BUTTON_MODIFIER_SHIFT   0x04000000L /* PDCurses */
#define BUTTON_MODIFIER_CONTROL 0x08000000L /* PDCurses */
#define BUTTON_MODIFIER_ALT     0x10000000L /* PDCurses */

#define ALL_MOUSE_EVENTS        0x1fffffffL
#define REPORT_MOUSE_POSITION   0x20000000L

/* ncurses mouse interface */

typedef unsigned long mmask_t;

typedef struct
{
    short id;       /* unused, always 0 */
    int x, y, z;    /* x, y same as MOUSE_STATUS; z unused */
    mmask_t bstate; /* equivalent to changes + button[], but
                       in the same format as used for mousemask() */
} MEVENT;

#ifdef NCURSES_MOUSE_VERSION
# define BUTTON_SHIFT   BUTTON_MODIFIER_SHIFT
# define BUTTON_CONTROL BUTTON_MODIFIER_CONTROL
# define BUTTON_CTRL    BUTTON_MODIFIER_CONTROL
# define BUTTON_ALT     BUTTON_MODIFIER_ALT
#else
# define BUTTON_SHIFT   PDC_BUTTON_SHIFT
# define BUTTON_CONTROL PDC_BUTTON_CONTROL
# define BUTTON_ALT     PDC_BUTTON_ALT
#endif

/*----------------------------------------------------------------------
 *
 *  PDCurses Structure Definitions
 *
 */

typedef struct _win       /* definition of a window */
{
    int   _cury;          /* current pseudo-cursor */
    int   _curx;
    int   _maxy;          /* max window coordinates */
    int   _maxx;
    int   _begy;          /* origin on screen */
    int   _begx;
    int   _flags;         /* window properties */
    chtype _attrs;        /* standard attributes and colors */
    chtype _bkgd;         /* background, normally blank */
    bool  _clear;         /* causes clear at next refresh */
    bool  _leaveit;       /* leaves cursor where it is */
    bool  _scroll;        /* allows window scrolling */
    bool  _nodelay;       /* input character wait flag */
    bool  _immed;         /* immediate update flag */
    bool  _sync;          /* synchronise window ancestors */
    bool  _use_keypad;    /* flags keypad key mode active */
    chtype **_y;          /* pointer to line pointer array */
    int   *_firstch;      /* first changed character in line */
    int   *_lastch;       /* last changed character in line */
    int   _tmarg;         /* top of scrolling region */
    int   _bmarg;         /* bottom of scrolling region */
    int   _delayms;       /* milliseconds of delay for getch() */
    int   _parx, _pary;   /* coords relative to parent (0,0) */
    struct _win *_parent; /* subwin's pointer to parent win */
} WINDOW;

/* Avoid using the SCREEN struct directly -- use the corresponding 
   functions if possible. This struct may eventually be made private. */

typedef struct
{
    bool  alive;          /* if initscr() called, and not endwin() */
    bool  autocr;         /* if cr -> lf */
    bool  cbreak;         /* if terminal unbuffered */
    bool  echo;           /* if terminal echo */
    bool  raw_inp;        /* raw input mode (v. cooked input) */
    bool  raw_out;        /* raw output mode (7 v. 8 bits) */
    bool  audible;        /* FALSE if the bell is visual */
    bool  mono;           /* TRUE if current screen is mono */
    bool  resized;        /* TRUE if TERM has been resized */
    bool  orig_attr;      /* TRUE if we have the original colors */
    short orig_fore;      /* original screen foreground color */
    short orig_back;      /* original screen foreground color */
    int   cursrow;        /* position of physical cursor */
    int   curscol;        /* position of physical cursor */
    int   visibility;     /* visibility of cursor */
    int   orig_cursor;    /* original cursor size */
    int   lines;          /* new value for LINES */
    int   cols;           /* new value for COLS */
    unsigned long _trap_mbe;       /* trap these mouse button events */
    unsigned long _map_mbe_to_key; /* map mouse buttons to slk */
    int   mouse_wait;              /* time to wait (in ms) for a
                                      button release after a press, in 
                                      order to count it as a click */
    int   slklines;                /* lines in use by slk_init() */
    WINDOW *slk_winptr;            /* window for slk */
    int   linesrippedoff;          /* lines ripped off via ripoffline() */
    int   linesrippedoffontop;     /* lines ripped off on 
                                      top via ripoffline() */
    int   delaytenths;             /* 1/10ths second to wait block
                                      getch() for */
    bool  _preserve;               /* TRUE if screen background
                                      to be preserved */
    int   _restore;                /* specifies if screen background
                                      to be restored, and how */
    bool  save_key_modifiers;      /* TRUE if each key modifiers saved
                                      with each key press */
    bool  return_key_modifiers;    /* TRUE if modifier keys are
                                      returned as "real" keys */
    bool  key_code;                /* TRUE if last key is a special key;
                                      used internally by get_wch() */
#ifdef XCURSES
    int   XcurscrSize;    /* size of Xcurscr shared memory block */
    bool  sb_on;
    int   sb_viewport_y;
    int   sb_viewport_x;
    int   sb_total_y;
    int   sb_total_x;
    int   sb_cur_y;
    int   sb_cur_x;
#endif
    short line_color;     /* color of line attributes - default -1 */
} SCREEN;

/*----------------------------------------------------------------------
 *
 *  PDCurses External Variables
 *
 */

#ifdef PDC_DLL_BUILD
# ifdef CURSES_LIBRARY
#  define PDCEX __declspec(dllexport) extern
# else
#  define PDCEX __declspec(dllimport)
# endif
#else
# define PDCEX extern
#endif

PDCEX  int          LINES;        /* terminal height */
PDCEX  int          COLS;         /* terminal width */
PDCEX  WINDOW       *stdscr;      /* the default screen window */
PDCEX  WINDOW       *curscr;      /* the current screen image */
PDCEX  SCREEN       *SP;          /* curses variables */
PDCEX  MOUSE_STATUS Mouse_status;
PDCEX  int          COLORS;
PDCEX  int          COLOR_PAIRS;
PDCEX  int          TABSIZE;
PDCEX  chtype       acs_map[];    /* alternate character set map */
PDCEX  char         ttytype[];    /* terminal name/description */

/*man-start**************************************************************

PDCurses Text Attributes
========================

Originally, PDCurses used a short (16 bits) for its chtype. To include 
color, a number of things had to be sacrificed from the strict Unix and 
System V support. The main problem was fitting all character attributes 
and color into an unsigned char (all 8 bits!).

Today, PDCurses by default uses a long (32 bits) for its chtype, as in 
System V. The short chtype is still available, by undefining CHTYPE_LONG 
and rebuilding the library.

The following is the structure of a win->_attrs chtype:

short form:

    +-----------------------------------------------+
    |15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
    +-----------------------------------------------+
      color number |  attrs |   character eg 'a'

The available non-color attributes are bold, reverse and blink. Others 
have no effect. The high order char is an index into an array of 
physical colors (defined in color.c) -- 32 foreground/background color 
pairs (5 bits) plus 3 bits for other attributes.

long form:

    +--------------------------------------------------------------------+
    |31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|..| 2| 1| 0|
    +--------------------------------------------------------------------+
          color number      |     modifiers         |   character eg 'a'

The available non-color attributes are bold, underline, invisible, 
right-line, left-line, protect, reverse and blink. 256 color pairs (8 
bits), 8 bits for other attributes, and 16 bits for character data.

**man-end****************************************************************/

/*** Video attribute macros ***/

#define A_NORMAL      (chtype)0

#ifdef CHTYPE_LONG
# define A_ALTCHARSET (chtype)0x00010000
# define A_RIGHTLINE  (chtype)0x00020000
# define A_LEFTLINE   (chtype)0x00040000
# define A_INVIS      (chtype)0x00080000
# define A_UNDERLINE  (chtype)0x00100000
# define A_REVERSE    (chtype)0x00200000
# define A_BLINK      (chtype)0x00400000
# define A_BOLD       (chtype)0x00800000

# define A_ATTRIBUTES (chtype)0xffff0000
# define A_CHARTEXT   (chtype)0x0000ffff
# define A_COLOR      (chtype)0xff000000

# define A_ITALIC     A_INVIS
# define A_PROTECT    (A_UNDERLINE | A_LEFTLINE | A_RIGHTLINE)

# define PDC_COLOR_SHIFT 24
#else
# define A_BOLD       (chtype)0x0100  /* X/Open */
# define A_REVERSE    (chtype)0x0200  /* X/Open */
# define A_BLINK      (chtype)0x0400  /* X/Open */

# define A_ATTRIBUTES (chtype)0xff00  /* X/Open */
# define A_CHARTEXT   (chtype)0x00ff  /* X/Open */
# define A_COLOR      (chtype)0xf800  /* System V */

# define A_ALTCHARSET A_NORMAL        /* X/Open */
# define A_PROTECT    A_NORMAL        /* X/Open */
# define A_UNDERLINE  A_NORMAL        /* X/Open */

# define A_LEFTLINE   A_NORMAL
# define A_RIGHTLINE  A_NORMAL
# define A_ITALIC     A_NORMAL
# define A_INVIS      A_NORMAL

# define PDC_COLOR_SHIFT 11
#endif

#define A_STANDOUT    (A_REVERSE | A_BOLD) /* X/Open */
#define A_DIM         A_NORMAL

#define CHR_MSK       A_CHARTEXT           /* Obsolete */
#define ATR_MSK       A_ATTRIBUTES         /* Obsolete */
#define ATR_NRM       A_NORMAL             /* Obsolete */

/* For use with attr_t -- X/Open says, "these shall be distinct", so 
   this is a non-conforming implementation. */

#define WA_NORMAL     A_NORMAL

#define WA_ALTCHARSET A_ALTCHARSET
#define WA_BLINK      A_BLINK
#define WA_BOLD       A_BOLD
#define WA_DIM        A_DIM
#define WA_INVIS      A_INVIS
#define WA_LEFT       A_LEFTLINE
#define WA_PROTECT    A_PROTECT
#define WA_REVERSE    A_REVERSE
#define WA_RIGHT      A_RIGHTLINE
#define WA_STANDOUT   A_STANDOUT
#define WA_UNDERLINE  A_UNDERLINE

#define WA_HORIZONTAL A_NORMAL
#define WA_LOW        A_NORMAL
#define WA_TOP        A_NORMAL
#define WA_VERTICAL   A_NORMAL

#define WA_ATTRIBUTES A_ATTRIBUTES

/*** Alternate character set macros ***/

/* 'w' = 32-bit chtype; acs_map[] index | A_ALTCHARSET
   'n' = 16-bit chtype; it gets the fallback set because no bit is 
         available for A_ALTCHARSET */

#ifdef CHTYPE_LONG
# define ACS_PICK(w, n) ((chtype)w | A_ALTCHARSET)
#else
# define ACS_PICK(w, n) ((chtype)n)
#endif

/* VT100-compatible symbols -- box chars */

#define ACS_ULCORNER  ACS_PICK('l', '+')
#define ACS_LLCORNER  ACS_PICK('m', '+')
#define ACS_URCORNER  ACS_PICK('k', '+')
#define ACS_LRCORNER  ACS_PICK('j', '+')
#define ACS_RTEE      ACS_PICK('u', '+')
#define ACS_LTEE      ACS_PICK('t', '+')
#define ACS_BTEE      ACS_PICK('v', '+')
#define ACS_TTEE      ACS_PICK('w', '+')
#define ACS_HLINE     ACS_PICK('q', '-')
#define ACS_VLINE     ACS_PICK('x', '|')
#define ACS_PLUS      ACS_PICK('n', '+')

/* VT100-compatible symbols -- other */

#define ACS_S1        ACS_PICK('o', '-')
#define ACS_S9        ACS_PICK('s', '_')
#define ACS_DIAMOND   ACS_PICK('`', '+')
#define ACS_CKBOARD   ACS_PICK('a', ':')
#define ACS_DEGREE    ACS_PICK('f', '\'')
#define ACS_PLMINUS   ACS_PICK('g', '#')
#define ACS_BULLET    ACS_PICK('~', 'o')

/* Teletype 5410v1 symbols -- these are defined in SysV curses, but
   are not well-supported by most terminals. Stick to VT100 characters
   for optimum portability. */

#define ACS_LARROW    ACS_PICK(',', '<')
#define ACS_RARROW    ACS_PICK('+', '>')
#define ACS_DARROW    ACS_PICK('.', 'v')
#define ACS_UARROW    ACS_PICK('-', '^')
#define ACS_BOARD     ACS_PICK('h', '#')
#define ACS_LANTERN   ACS_PICK('i', '*')
#define ACS_BLOCK     ACS_PICK('0', '#')

/* That goes double for these -- undocumented SysV symbols. Don't use
   them. */

#define ACS_S3        ACS_PICK('p', '-')
#define ACS_S7        ACS_PICK('r', '-')
#define ACS_LEQUAL    ACS_PICK('y', '<')
#define ACS_GEQUAL    ACS_PICK('z', '>')
#define ACS_PI        ACS_PICK('{', 'n')
#define ACS_NEQUAL    ACS_PICK('|', '+')
#define ACS_STERLING  ACS_PICK('}', 'L')

/* Box char aliases */

#define ACS_BSSB      ACS_ULCORNER
#define ACS_SSBB      ACS_LLCORNER
#define ACS_BBSS      ACS_URCORNER
#define ACS_SBBS      ACS_LRCORNER
#define ACS_SBSS      ACS_RTEE
#define ACS_SSSB      ACS_LTEE
#define ACS_SSBS      ACS_BTEE
#define ACS_BSSS      ACS_TTEE
#define ACS_BSBS      ACS_HLINE
#define ACS_SBSB      ACS_VLINE
#define ACS_SSSS      ACS_PLUS

/* cchar_t aliases */

#ifdef PDC_WIDE
# define WACS_ULCORNER (&(acs_map['l']))
# define WACS_LLCORNER (&(acs_map['m']))
# define WACS_URCORNER (&(acs_map['k']))
# define WACS_LRCORNER (&(acs_map['j']))
# define WACS_RTEE     (&(acs_map['u']))
# define WACS_LTEE     (&(acs_map['t']))
# define WACS_BTEE     (&(acs_map['v']))
# define WACS_TTEE     (&(acs_map['w']))
# define WACS_HLINE    (&(acs_map['q']))
# define WACS_VLINE    (&(acs_map['x']))
# define WACS_PLUS     (&(acs_map['n']))

# define WACS_S1       (&(acs_map['o']))
# define WACS_S9       (&(acs_map['s']))
# define WACS_DIAMOND  (&(acs_map['`']))
# define WACS_CKBOARD  (&(acs_map['a']))
# define WACS_DEGREE   (&(acs_map['f']))
# define WACS_PLMINUS  (&(acs_map['g']))
# define WACS_BULLET   (&(acs_map['~']))

# define WACS_LARROW   (&(acs_map[',']))
# define WACS_RARROW   (&(acs_map['+']))
# define WACS_DARROW   (&(acs_map['.']))
# define WACS_UARROW   (&(acs_map['-']))
# define WACS_BOARD    (&(acs_map['h']))
# define WACS_LANTERN  (&(acs_map['i']))
# define WACS_BLOCK    (&(acs_map['0']))

# define WACS_S3       (&(acs_map['p']))
# define WACS_S7       (&(acs_map['r']))
# define WACS_LEQUAL   (&(acs_map['y']))
# define WACS_GEQUAL   (&(acs_map['z']))
# define WACS_PI       (&(acs_map['{']))
# define WACS_NEQUAL   (&(acs_map['|']))
# define WACS_STERLING (&(acs_map['}']))

# define WACS_BSSB     WACS_ULCORNER
# define WACS_SSBB     WACS_LLCORNER
# define WACS_BBSS     WACS_URCORNER
# define WACS_SBBS     WACS_LRCORNER
# define WACS_SBSS     WACS_RTEE
# define WACS_SSSB     WACS_LTEE
# define WACS_SSBS     WACS_BTEE
# define WACS_BSSS     WACS_TTEE
# define WACS_BSBS     WACS_HLINE
# define WACS_SBSB     WACS_VLINE
# define WACS_SSSS     WACS_PLUS
#endif

/*** Color macros ***/

#define COLOR_BLACK   0

#ifdef PDC_RGB        /* RGB */
# define COLOR_RED    1
# define COLOR_GREEN  2
# define COLOR_BLUE   4
#else                 /* BGR */
# define COLOR_BLUE   1
# define COLOR_GREEN  2
# define COLOR_RED    4
#endif

#define COLOR_CYAN    (COLOR_BLUE | COLOR_GREEN)
#define COLOR_MAGENTA (COLOR_RED | COLOR_BLUE)
#define COLOR_YELLOW  (COLOR_RED | COLOR_GREEN)

#define COLOR_WHITE   7

/*----------------------------------------------------------------------
 *
 *  Function and Keypad Key Definitions.
 *  Many are just for compatibility.
 *
 */

#define KEY_CODE_YES  0x100  /* If get_wch() gives a key code */

#define KEY_BREAK     0x101  /* Not on PC KBD */
#define KEY_DOWN      0x102  /* Down arrow key */
#define KEY_UP        0x103  /* Up arrow key */
#define KEY_LEFT      0x104  /* Left arrow key */
#define KEY_RIGHT     0x105  /* Right arrow key */
#define KEY_HOME      0x106  /* home key */
#define KEY_BACKSPACE 0x107  /* not on pc */
#define KEY_F0        0x108  /* function keys; 64 reserved */

#define KEY_DL        0x148  /* delete line */
#define KEY_IL        0x149  /* insert line */
#define KEY_DC        0x14a  /* delete character */
#define KEY_IC        0x14b  /* insert char or enter ins mode */
#define KEY_EIC       0x14c  /* exit insert char mode */
#define KEY_CLEAR     0x14d  /* clear screen */
#define KEY_EOS       0x14e  /* clear to end of screen */
#define KEY_EOL       0x14f  /* clear to end of line */
#define KEY_SF        0x150  /* scroll 1 line forward */
#define KEY_SR        0x151  /* scroll 1 line back (reverse) */
#define KEY_NPAGE     0x152  /* next page */
#define KEY_PPAGE     0x153  /* previous page */
#define KEY_STAB      0x154  /* set tab */
#define KEY_CTAB      0x155  /* clear tab */
#define KEY_CATAB     0x156  /* clear all tabs */
#define KEY_ENTER     0x157  /* enter or send (unreliable) */
#define KEY_SRESET    0x158  /* soft/reset (partial/unreliable) */
#define KEY_RESET     0x159  /* reset/hard reset (unreliable) */
#define KEY_PRINT     0x15a  /* print/copy */
#define KEY_LL        0x15b  /* home down/bottom (lower left) */
#define KEY_ABORT     0x15c  /* abort/terminate key (any) */
#define KEY_SHELP     0x15d  /* short help */
#define KEY_LHELP     0x15e  /* long help */
#define KEY_BTAB      0x15f  /* Back tab key */
#define KEY_BEG       0x160  /* beg(inning) key */
#define KEY_CANCEL    0x161  /* cancel key */
#define KEY_CLOSE     0x162  /* close key */
#define KEY_COMMAND   0x163  /* cmd (command) key */
#define KEY_COPY      0x164  /* copy key */
#define KEY_CREATE    0x165  /* create key */
#define KEY_END       0x166  /* end key */
#define KEY_EXIT      0x167  /* exit key */
#define KEY_FIND      0x168  /* find key */
#define KEY_HELP      0x169  /* help key */
#define KEY_MARK      0x16a  /* mark key */
#define KEY_MESSAGE   0x16b  /* message key */
#define KEY_MOVE      0x16c  /* move key */
#define KEY_NEXT      0x16d  /* next object key */
#define KEY_OPEN      0x16e  /* open key */
#define KEY_OPTIONS   0x16f  /* options key */
#define KEY_PREVIOUS  0x170  /* previous object key */
#define KEY_REDO      0x171  /* redo key */
#define KEY_REFERENCE 0x172  /* ref(erence) key */
#define KEY_REFRESH   0x173  /* refresh key */
#define KEY_REPLACE   0x174  /* replace key */
#define KEY_RESTART   0x175  /* restart key */
#define KEY_RESUME    0x176  /* resume key */
#define KEY_SAVE      0x177  /* save key */
#define KEY_SBEG      0x178  /* shifted beginning key */
#define KEY_SCANCEL   0x179  /* shifted cancel key */
#define KEY_SCOMMAND  0x17a  /* shifted command key */
#define KEY_SCOPY     0x17b  /* shifted copy key */
#define KEY_SCREATE   0x17c  /* shifted create key */
#define KEY_SDC       0x17d  /* shifted delete char key */
#define KEY_SDL       0x17e  /* shifted delete line key */
#define KEY_SELECT    0x17f  /* select key */
#define KEY_SEND      0x180  /* shifted end key */
#define KEY_SEOL      0x181  /* shifted clear line key */
#define KEY_SEXIT     0x182  /* shifted exit key */
#define KEY_SFIND     0x183  /* shifted find key */
#define KEY_SHOME     0x184  /* shifted home key */
#define KEY_SIC       0x185  /* shifted input key */

#define KEY_SLEFT     0x187  /* shifted left arrow key */
#define KEY_SMESSAGE  0x188  /* shifted message key */
#define KEY_SMOVE     0x189  /* shifted move key */
#define KEY_SNEXT     0x18a  /* shifted next key */
#define KEY_SOPTIONS  0x18b  /* shifted options key */
#define KEY_SPREVIOUS 0x18c  /* shifted prev key */
#define KEY_SPRINT    0x18d  /* shifted print key */
#define KEY_SREDO     0x18e  /* shifted redo key */
#define KEY_SREPLACE  0x18f  /* shifted replace key */
#define KEY_SRIGHT    0x190  /* shifted right arrow */
#define KEY_SRSUME    0x191  /* shifted resume key */
#define KEY_SSAVE     0x192  /* shifted save key */
#define KEY_SSUSPEND  0x193  /* shifted suspend key */
#define KEY_SUNDO     0x194  /* shifted undo key */
#define KEY_SUSPEND   0x195  /* suspend key */
#define KEY_UNDO      0x196  /* undo key */

/* PDCurses-specific key definitions -- PC only */

#define ALT_0         0x197
#define ALT_1         0x198
#define ALT_2         0x199
#define ALT_3         0x19a
#define ALT_4         0x19b
#define ALT_5         0x19c
#define ALT_6         0x19d
#define ALT_7         0x19e
#define ALT_8         0x19f
#define ALT_9         0x1a0
#define ALT_A         0x1a1
#define ALT_B         0x1a2
#define ALT_C         0x1a3
#define ALT_D         0x1a4
#define ALT_E         0x1a5
#define ALT_F         0x1a6
#define ALT_G         0x1a7
#define ALT_H         0x1a8
#define ALT_I         0x1a9
#define ALT_J         0x1aa
#define ALT_K         0x1ab
#define ALT_L         0x1ac
#define ALT_M         0x1ad
#define ALT_N         0x1ae
#define ALT_O         0x1af
#define ALT_P         0x1b0
#define ALT_Q         0x1b1
#define ALT_R         0x1b2
#define ALT_S         0x1b3
#define ALT_T         0x1b4
#define ALT_U         0x1b5
#define ALT_V         0x1b6
#define ALT_W         0x1b7
#define ALT_X         0x1b8
#define ALT_Y         0x1b9
#define ALT_Z         0x1ba

#define CTL_LEFT      0x1bb  /* Control-Left-Arrow */
#define CTL_RIGHT     0x1bc
#define CTL_PGUP      0x1bd
#define CTL_PGDN      0x1be
#define CTL_HOME      0x1bf
#define CTL_END       0x1c0

#define KEY_A1        0x1c1  /* upper left on Virtual keypad */
#define KEY_A2        0x1c2  /* upper middle on Virt. keypad */
#define KEY_A3        0x1c3  /* upper right on Vir. keypad */
#define KEY_B1        0x1c4  /* middle left on Virt. keypad */
#define KEY_B2        0x1c5  /* center on Virt. keypad */
#define KEY_B3        0x1c6  /* middle right on Vir. keypad */
#define KEY_C1        0x1c7  /* lower left on Virt. keypad */
#define KEY_C2        0x1c8  /* lower middle on Virt. keypad */
#define KEY_C3        0x1c9  /* lower right on Vir. keypad */

#define PADSLASH      0x1ca  /* slash on keypad */
#define PADENTER      0x1cb  /* enter on keypad */
#define CTL_PADENTER  0x1cc  /* ctl-enter on keypad */
#define ALT_PADENTER  0x1cd  /* alt-enter on keypad */
#define PADSTOP       0x1ce  /* stop on keypad */
#define PADSTAR       0x1cf  /* star on keypad */
#define PADMINUS      0x1d0  /* minus on keypad */
#define PADPLUS       0x1d1  /* plus on keypad */
#define CTL_PADSTOP   0x1d2  /* ctl-stop on keypad */
#define CTL_PADCENTER 0x1d3  /* ctl-enter on keypad */
#define CTL_PADPLUS   0x1d4  /* ctl-plus on keypad */
#define CTL_PADMINUS  0x1d5  /* ctl-minus on keypad */
#define CTL_PADSLASH  0x1d6  /* ctl-slash on keypad */
#define CTL_PADSTAR   0x1d7  /* ctl-star on keypad */
#define ALT_PADPLUS   0x1d8  /* alt-plus on keypad */
#define ALT_PADMINUS  0x1d9  /* alt-minus on keypad */
#define ALT_PADSLASH  0x1da  /* alt-slash on keypad */
#define ALT_PADSTAR   0x1db  /* alt-star on keypad */
#define ALT_PADSTOP   0x1dc  /* alt-stop on keypad */
#define CTL_INS       0x1dd  /* ctl-insert */
#define ALT_DEL       0x1de  /* alt-delete */
#define ALT_INS       0x1df  /* alt-insert */
#define CTL_UP        0x1e0  /* ctl-up arrow */
#define CTL_DOWN      0x1e1  /* ctl-down arrow */
#define CTL_TAB       0x1e2  /* ctl-tab */
#define ALT_TAB       0x1e3
#define ALT_MINUS     0x1e4
#define ALT_EQUAL     0x1e5
#define ALT_HOME      0x1e6
#define ALT_PGUP      0x1e7
#define ALT_PGDN      0x1e8
#define ALT_END       0x1e9
#define ALT_UP        0x1ea  /* alt-up arrow */
#define ALT_DOWN      0x1eb  /* alt-down arrow */
#define ALT_RIGHT     0x1ec  /* alt-right arrow */
#define ALT_LEFT      0x1ed  /* alt-left arrow */
#define ALT_ENTER     0x1ee  /* alt-enter */
#define ALT_ESC       0x1ef  /* alt-escape */
#define ALT_BQUOTE    0x1f0  /* alt-back quote */
#define ALT_LBRACKET  0x1f1  /* alt-left bracket */
#define ALT_RBRACKET  0x1f2  /* alt-right bracket */
#define ALT_SEMICOLON 0x1f3  /* alt-semi-colon */
#define ALT_FQUOTE    0x1f4  /* alt-forward quote */
#define ALT_COMMA     0x1f5  /* alt-comma */
#define ALT_STOP      0x1f6  /* alt-stop */
#define ALT_FSLASH    0x1f7  /* alt-forward slash */
#define ALT_BKSP      0x1f8  /* alt-backspace */
#define CTL_BKSP      0x1f9  /* ctl-backspace */
#define PAD0          0x1fa  /* keypad 0 */

#define CTL_PAD0      0x1fb  /* ctl-keypad 0 */
#define CTL_PAD1      0x1fc
#define CTL_PAD2      0x1fd
#define CTL_PAD3      0x1fe
#define CTL_PAD4      0x1ff
#define CTL_PAD5      0x200
#define CTL_PAD6      0x201
#define CTL_PAD7      0x202
#define CTL_PAD8      0x203
#define CTL_PAD9      0x204

#define ALT_PAD0      0x205  /* alt-keypad 0 */
#define ALT_PAD1      0x206
#define ALT_PAD2      0x207
#define ALT_PAD3      0x208
#define ALT_PAD4      0x209
#define ALT_PAD5      0x20a
#define ALT_PAD6      0x20b
#define ALT_PAD7      0x20c
#define ALT_PAD8      0x20d
#define ALT_PAD9      0x20e

#define CTL_DEL       0x20f  /* clt-delete */
#define ALT_BSLASH    0x210  /* alt-back slash */
#define CTL_ENTER     0x211  /* ctl-enter */

#define SHF_PADENTER  0x212  /* shift-enter on keypad */
#define SHF_PADSLASH  0x213  /* shift-slash on keypad */
#define SHF_PADSTAR   0x214  /* shift-star  on keypad */
#define SHF_PADPLUS   0x215  /* shift-plus  on keypad */
#define SHF_PADMINUS  0x216  /* shift-minus on keypad */
#define SHF_UP        0x217  /* shift-up on keypad */
#define SHF_DOWN      0x218  /* shift-down on keypad */
#define SHF_IC        0x219  /* shift-insert on keypad */
#define SHF_DC        0x21a  /* shift-delete on keypad */

#define KEY_MOUSE     0x21b  /* "mouse" key */
#define KEY_SHIFT_L   0x21c  /* Left-shift */
#define KEY_SHIFT_R   0x21d  /* Right-shift */
#define KEY_CONTROL_L 0x21e  /* Left-control */
#define KEY_CONTROL_R 0x21f  /* Right-control */
#define KEY_ALT_L     0x220  /* Left-alt */
#define KEY_ALT_R     0x221  /* Right-alt */
#define KEY_RESIZE    0x222  /* Window resize */
#define KEY_SUP       0x223  /* Shifted up arrow */
#define KEY_SDOWN     0x224  /* Shifted down arrow */

#define KEY_MIN       KEY_BREAK      /* Minimum curses key value */
#define KEY_MAX       KEY_SDOWN      /* Maximum curses key */

#define KEY_F(n)      (KEY_F0 + (n))

/*----------------------------------------------------------------------
 *
 *  PDCurses Function Declarations
 *
 */

/* Standard */

int     addch(const chtype);
int     addchnstr(const chtype *, int);
int     addchstr(const chtype *);
int     addnstr(const char *, int);
int     addstr(const char *);
int     attroff(chtype);
int     attron(chtype);
int     attrset(chtype);
int     attr_get(attr_t *, short *, void *);
int     attr_off(attr_t, void *);
int     attr_on(attr_t, void *);
int     attr_set(attr_t, short, void *);
int     baudrate(void);
int     beep(void);
int     bkgd(chtype);
void    bkgdset(chtype);
int     border(chtype, chtype, chtype, chtype, chtype, chtype, chtype, chtype);
int     box(WINDOW *, chtype, chtype);
bool    can_change_color(void);
int     cbreak(void); 
int     chgat(int, attr_t, short, const void *);
int     clearok(WINDOW *, bool);
int     clear(void);
int     clrtobot(void);
int     clrtoeol(void);
int     color_content(short, short *, short *, short *);
int     color_set(short, void *);
int     copywin(const WINDOW *, WINDOW *, int, int, int, int, int, int, int);
int     curs_set(int);
int     def_prog_mode(void);
int     def_shell_mode(void);
int     delay_output(int);
int     delch(void);
int     deleteln(void);
void    delscreen(SCREEN *); 
int     delwin(WINDOW *);
WINDOW *derwin(WINDOW *, int, int, int, int);
int     doupdate(void);
WINDOW *dupwin(WINDOW *);
int     echochar(const chtype);
int     echo(void);
int     endwin(void);
char    erasechar(void);
int     erase(void);
void    filter(void);
int     flash(void);
int     flushinp(void);
chtype  getbkgd(WINDOW *);
int     getnstr(char *, int);
int     getstr(char *);
WINDOW *getwin(FILE *);
int     halfdelay(int);
bool    has_colors(void);
bool    has_ic(void);
bool    has_il(void);
int     hline(chtype, int);
void    idcok(WINDOW *, bool);
int     idlok(WINDOW *, bool);
void    immedok(WINDOW *, bool);
int     inchnstr(chtype *, int);
int     inchstr(chtype *);
chtype  inch(void);
int     init_color(short, short, short, short);
int     init_pair(short, short, short);
WINDOW *initscr(void);
int     innstr(char *, int);
int     insch(chtype);
int     insdelln(int);
int     insertln(void);
int     insnstr(const char *, int);
int     insstr(const char *);
int     instr(char *);
int     intrflush(WINDOW *, bool);
bool    isendwin(void);
bool    is_linetouched(WINDOW *, int);
bool    is_wintouched(WINDOW *);
char   *keyname(int);
int     keypad(WINDOW *, bool);
char    killchar(void);
int     leaveok(WINDOW *, bool);
char   *longname(void);
int     meta(WINDOW *, bool);
int     move(int, int);
int     mvaddch(int, int, const chtype);
int     mvaddchnstr(int, int, const chtype *, int);
int     mvaddchstr(int, int, const chtype *);
int     mvaddnstr(int, int, const char *, int);
int     mvaddstr(int, int, const char *);
int     mvchgat(int, int, int, attr_t, short, const void *);
int     mvcur(int, int, int, int);
int     mvdelch(int, int);
int     mvderwin(WINDOW *, int, int);
int     mvgetch(int, int);
int     mvgetnstr(int, int, char *, int);
int     mvgetstr(int, int, char *);
int     mvhline(int, int, chtype, int);
chtype  mvinch(int, int);
int     mvinchnstr(int, int, chtype *, int);
int     mvinchstr(int, int, chtype *);
int     mvinnstr(int, int, char *, int);
int     mvinsch(int, int, chtype);
int     mvinsnstr(int, int, const char *, int);
int     mvinsstr(int, int, const char *);
int     mvinstr(int, int, char *);
int     mvprintw(int, int, const char *, ...);
int     mvscanw(int, int, const char *, ...);
int     mvvline(int, int, chtype, int);
int     mvwaddchnstr(WINDOW *, int, int, const chtype *, int);
int     mvwaddchstr(WINDOW *, int, int, const chtype *);
int     mvwaddch(WINDOW *, int, int, const chtype);
int     mvwaddnstr(WINDOW *, int, int, const char *, int);
int     mvwaddstr(WINDOW *, int, int, const char *);
int     mvwchgat(WINDOW *, int, int, int, attr_t, short, const void *);
int     mvwdelch(WINDOW *, int, int);
int     mvwgetch(WINDOW *, int, int);
int     mvwgetnstr(WINDOW *, int, int, char *, int);
int     mvwgetstr(WINDOW *, int, int, char *);
int     mvwhline(WINDOW *, int, int, chtype, int);
int     mvwinchnstr(WINDOW *, int, int, chtype *, int);
int     mvwinchstr(WINDOW *, int, int, chtype *);
chtype  mvwinch(WINDOW *, int, int);
int     mvwinnstr(WINDOW *, int, int, char *, int);
int     mvwinsch(WINDOW *, int, int, chtype);
int     mvwinsnstr(WINDOW *, int, int, const char *, int);
int     mvwinsstr(WINDOW *, int, int, const char *);
int     mvwinstr(WINDOW *, int, int, char *);
int     mvwin(WINDOW *, int, int);
int     mvwprintw(WINDOW *, int, int, const char *, ...);
int     mvwscanw(WINDOW *, int, int, const char *, ...);
int     mvwvline(WINDOW *, int, int, chtype, int);
int     napms(int);
WINDOW *newpad(int, int);
SCREEN *newterm(const char *, FILE *, FILE *);
WINDOW *newwin(int, int, int, int);
int     nl(void);
int     nocbreak(void);
int     nodelay(WINDOW *, bool);
int     noecho(void);
int     nonl(void);
void    noqiflush(void);
int     noraw(void);
int     notimeout(WINDOW *, bool);
int     overlay(const WINDOW *, WINDOW *);
int     overwrite(const WINDOW *, WINDOW *);
int     pair_content(short, short *, short *);
int     pechochar(WINDOW *, chtype);
int     pnoutrefresh(WINDOW *, int, int, int, int, int, int);
int     prefresh(WINDOW *, int, int, int, int, int, int);
int     printw(const char *, ...);
int     putwin(WINDOW *, FILE *);
void    qiflush(void);
int     raw(void);
int     redrawwin(WINDOW *);
int     refresh(void);
int     reset_prog_mode(void);
int     reset_shell_mode(void);
int     resetty(void);
int     ripoffline(int, int (*)(WINDOW *, int));
int     savetty(void);
int     scanw(const char *, ...);
int     scr_dump(const char *);
int     scr_init(const char *);
int     scr_restore(const char *);
int     scr_set(const char *);
int     scrl(int);
int     scroll(WINDOW *);
int     scrollok(WINDOW *, bool);
SCREEN *set_term(SCREEN *);
int     setscrreg(int, int);
int     slk_attroff(const chtype);
int     slk_attr_off(const attr_t, void *);
int     slk_attron(const chtype);
int     slk_attr_on(const attr_t, void *);
int     slk_attrset(const chtype);
int     slk_attr_set(const attr_t, short, void *);
int     slk_clear(void);
int     slk_color(short);
int     slk_init(int);
char   *slk_label(int);
int     slk_noutrefresh(void);
int     slk_refresh(void);
int     slk_restore(void);
int     slk_set(int, const char *, int);
int     slk_touch(void);
int     standend(void);
int     standout(void);
int     start_color(void);
WINDOW *subpad(WINDOW *, int, int, int, int);
WINDOW *subwin(WINDOW *, int, int, int, int);
int     syncok(WINDOW *, bool);
chtype  termattrs(void);
attr_t  term_attrs(void);
char   *termname(void);
void    timeout(int);
int     touchline(WINDOW *, int, int);
int     touchwin(WINDOW *);
int     typeahead(int);
int     untouchwin(WINDOW *);
void    use_env(bool);
int     vidattr(chtype);
int     vid_attr(attr_t, short, void *);
int     vidputs(chtype, int (*)(int));
int     vid_puts(attr_t, short, void *, int (*)(int));
int     vline(chtype, int);
int     vw_printw(WINDOW *, const char *, va_list);
int     vwprintw(WINDOW *, const char *, va_list);
int     vw_scanw(WINDOW *, const char *, va_list);
int     vwscanw(WINDOW *, const char *, va_list);
int     waddchnstr(WINDOW *, const chtype *, int);
int     waddchstr(WINDOW *, const chtype *);
int     waddch(WINDOW *, const chtype);
int     waddnstr(WINDOW *, const char *, int);
int     waddstr(WINDOW *, const char *);
int     wattroff(WINDOW *, chtype);
int     wattron(WINDOW *, chtype);
int     wattrset(WINDOW *, chtype);
int     wattr_get(WINDOW *, attr_t *, short *, void *);
int     wattr_off(WINDOW *, attr_t, void *);
int     wattr_on(WINDOW *, attr_t, void *);
int     wattr_set(WINDOW *, attr_t, short, void *);
void    wbkgdset(WINDOW *, chtype);
int     wbkgd(WINDOW *, chtype);
int     wborder(WINDOW *, chtype, chtype, chtype, chtype,
                chtype, chtype, chtype, chtype);
int     wchgat(WINDOW *, int, attr_t, short, const void *);
int     wclear(WINDOW *);
int     wclrtobot(WINDOW *);
int     wclrtoeol(WINDOW *);
int     wcolor_set(WINDOW *, short, void *);
void    wcursyncup(WINDOW *);
int     wdelch(WINDOW *);
int     wdeleteln(WINDOW *);
int     wechochar(WINDOW *, const chtype);
int     werase(WINDOW *);
int     wgetch(WINDOW *);
int     wgetnstr(WINDOW *, char *, int);
int     wgetstr(WINDOW *, char *);
int     whline(WINDOW *, chtype, int);
int     winchnstr(WINDOW *, chtype *, int);
int     winchstr(WINDOW *, chtype *);
chtype  winch(WINDOW *);
int     winnstr(WINDOW *, char *, int);
int     winsch(WINDOW *, chtype);
int     winsdelln(WINDOW *, int);
int     winsertln(WINDOW *);
int     winsnstr(WINDOW *, const char *, int);
int     winsstr(WINDOW *, const char *);
int     winstr(WINDOW *, char *);
int     wmove(WINDOW *, int, int);
int     wnoutrefresh(WINDOW *);
int     wprintw(WINDOW *, const char *, ...);
int     wredrawln(WINDOW *, int, int);
int     wrefresh(WINDOW *);
int     wscanw(WINDOW *, const char *, ...);
int     wscrl(WINDOW *, int);
int     wsetscrreg(WINDOW *, int, int);
int     wstandend(WINDOW *);
int     wstandout(WINDOW *);
void    wsyncdown(WINDOW *);
void    wsyncup(WINDOW *);
void    wtimeout(WINDOW *, int);
int     wtouchln(WINDOW *, int, int, int);
int     wvline(WINDOW *, chtype, int);

/* Wide-character functions */

#ifdef PDC_WIDE
int     addnwstr(const wchar_t *, int);
int     addwstr(const wchar_t *);
int     add_wch(const cchar_t *);
int     add_wchnstr(const cchar_t *, int);
int     add_wchstr(const cchar_t *);
int     border_set(const cchar_t *, const cchar_t *, const cchar_t *, 
                   const cchar_t *, const cchar_t *, const cchar_t *, 
                   const cchar_t *, const cchar_t *);
int     box_set(WINDOW *, const cchar_t *, const cchar_t *);
int     echo_wchar(const cchar_t *);
int     erasewchar(wchar_t *);
int     getbkgrnd(cchar_t *);
int     getcchar(const cchar_t *, wchar_t *, attr_t *, short *, void *);
int     getn_wstr(wint_t *, int);
int     get_wch(wint_t *);
int     get_wstr(wint_t *);
int     hline_set(const cchar_t *, int);
int     innwstr(wchar_t *, int);
int     ins_nwstr(const wchar_t *, int);
int     ins_wch(const cchar_t *);
int     ins_wstr(const wchar_t *);
int     inwstr(wchar_t *);
int     in_wch(cchar_t *);
int     in_wchnstr(cchar_t *, int);
int     in_wchstr(cchar_t *);
char   *key_name(wchar_t);
int     killwchar(wchar_t *);
int     mvaddnwstr(int, int, const wchar_t *, int);
int     mvaddwstr(int, int, const wchar_t *);
int     mvadd_wch(int, int, const cchar_t *);
int     mvadd_wchnstr(int, int, const cchar_t *, int);
int     mvadd_wchstr(int, int, const cchar_t *);
int     mvgetn_wstr(int, int, wint_t *, int);
int     mvget_wch(int, int, wint_t *);
int     mvget_wstr(int, int, wint_t *);
int     mvhline_set(int, int, const cchar_t *, int);
int     mvinnwstr(int, int, wchar_t *, int);
int     mvins_nwstr(int, int, const wchar_t *, int);
int     mvins_wch(int, int, const cchar_t *);
int     mvins_wstr(int, int, const wchar_t *);
int     mvinwstr(int, int, wchar_t *);
int     mvin_wch(int, int, cchar_t *);
int     mvin_wchnstr(int, int, cchar_t *, int);
int     mvin_wchstr(int, int, cchar_t *);
int     mvvline_set(int, int, const cchar_t *, int);
int     mvwaddnwstr(WINDOW *, int, int, const wchar_t *, int);
int     mvwaddwstr(WINDOW *, int, int, const wchar_t *);
int     mvwadd_wch(WINDOW *, int, int, const cchar_t *);
int     mvwadd_wchnstr(WINDOW *, int, int, const cchar_t *, int);
int     mvwadd_wchstr(WINDOW *, int, int, const cchar_t *);
int     mvwgetn_wstr(WINDOW *, int, int, wint_t *, int);
int     mvwget_wch(WINDOW *, int, int, wint_t *);
int     mvwget_wstr(WINDOW *, int, int, wint_t *);
int     mvwhline_set(WINDOW *, int, int, const cchar_t *, int);
int     mvwinnwstr(WINDOW *, int, int, wchar_t *, int);
int     mvwins_nwstr(WINDOW *, int, int, const wchar_t *, int);
int     mvwins_wch(WINDOW *, int, int, const cchar_t *);
int     mvwins_wstr(WINDOW *, int, int, const wchar_t *);
int     mvwin_wch(WINDOW *, int, int, cchar_t *);
int     mvwin_wchnstr(WINDOW *, int, int, cchar_t *, int);
int     mvwin_wchstr(WINDOW *, int, int, cchar_t *);
int     mvwinwstr(WINDOW *, int, int, wchar_t *);
int     mvwvline_set(WINDOW *, int, int, const cchar_t *, int);
int     pecho_wchar(WINDOW *, const cchar_t*);
int     setcchar(cchar_t*, const wchar_t*, const attr_t, short, const void*);
int     slk_wset(int, const wchar_t *, int);
int     unget_wch(const wchar_t);
int     vline_set(const cchar_t *, int);
int     waddnwstr(WINDOW *, const wchar_t *, int);
int     waddwstr(WINDOW *, const wchar_t *);
int     wadd_wch(WINDOW *, const cchar_t *);
int     wadd_wchnstr(WINDOW *, const cchar_t *, int);
int     wadd_wchstr(WINDOW *, const cchar_t *);
int     wbkgrnd(WINDOW *, const cchar_t *);
void    wbkgrndset(WINDOW *, const cchar_t *);
int     wborder_set(WINDOW *, const cchar_t *, const cchar_t *,
                    const cchar_t *, const cchar_t *, const cchar_t *, 
                    const cchar_t *, const cchar_t *, const cchar_t *);
int     wecho_wchar(WINDOW *, const cchar_t *);
int     wgetbkgrnd(WINDOW *, cchar_t *);
int     wgetn_wstr(WINDOW *, wint_t *, int);
int     wget_wch(WINDOW *, wint_t *);
int     wget_wstr(WINDOW *, wint_t *);
int     whline_set(WINDOW *, const cchar_t *, int);
int     winnwstr(WINDOW *, wchar_t *, int);
int     wins_nwstr(WINDOW *, const wchar_t *, int);
int     wins_wch(WINDOW *, const cchar_t *);
int     wins_wstr(WINDOW *, const wchar_t *);
int     winwstr(WINDOW *, wchar_t *);
int     win_wch(WINDOW *, cchar_t *);
int     win_wchnstr(WINDOW *, cchar_t *, int);
int     win_wchstr(WINDOW *, cchar_t *);
wchar_t *wunctrl(cchar_t *);
int     wvline_set(WINDOW *, const cchar_t *, int);
#endif

/* Quasi-standard */

chtype  getattrs(WINDOW *);
int     getbegx(WINDOW *);
int     getbegy(WINDOW *);
int     getmaxx(WINDOW *);
int     getmaxy(WINDOW *);
int     getparx(WINDOW *);
int     getpary(WINDOW *);
int     getcurx(WINDOW *);
int     getcury(WINDOW *);
void    traceoff(void);
void    traceon(void);
char   *unctrl(chtype);

int     crmode(void);
int     nocrmode(void);
int     draino(int);
int     resetterm(void);
int     fixterm(void);
int     saveterm(void);
int     setsyx(int, int);

int     mouse_set(unsigned long);
int     mouse_on(unsigned long);
int     mouse_off(unsigned long);
int     request_mouse_pos(void);
int     map_button(unsigned long);
void    wmouse_position(WINDOW *, int *, int *);
unsigned long getmouse(void);
unsigned long getbmap(void);

/* ncurses */

int     assume_default_colors(int, int);
const char *curses_version(void);
bool    has_key(int);
int     use_default_colors(void);
int     wresize(WINDOW *, int, int);

int     mouseinterval(int);
mmask_t mousemask(mmask_t, mmask_t *);
bool    mouse_trafo(int *, int *, bool);
int     nc_getmouse(MEVENT *);
int     ungetmouse(MEVENT *);
bool    wenclose(const WINDOW *, int, int);
bool    wmouse_trafo(const WINDOW *, int *, int *, bool);

/* PDCurses */

int     addrawch(chtype);
int     insrawch(chtype);
bool    is_termresized(void);
int     mvaddrawch(int, int, chtype);
int     mvdeleteln(int, int);
int     mvinsertln(int, int);
int     mvinsrawch(int, int, chtype);
int     mvwaddrawch(WINDOW *, int, int, chtype);
int     mvwdeleteln(WINDOW *, int, int);
int     mvwinsertln(WINDOW *, int, int);
int     mvwinsrawch(WINDOW *, int, int, chtype);
int     raw_output(bool);
int     resize_term(int, int);
WINDOW *resize_window(WINDOW *, int, int);
int     waddrawch(WINDOW *, chtype);
int     winsrawch(WINDOW *, chtype);
char    wordchar(void);

#ifdef PDC_WIDE
wchar_t *slk_wlabel(int);
#endif

void    PDC_debug(const char *, ...);
int     PDC_ungetch(int);
int     PDC_set_blink(bool);
int     PDC_set_line_color(short);
void    PDC_set_title(const char *);

int     PDC_clearclipboard(void);
int     PDC_freeclipboard(char *);
int     PDC_getclipboard(char **, long *);
int     PDC_setclipboard(const char *, long);

unsigned long PDC_get_input_fd(void);
unsigned long PDC_get_key_modifiers(void);
int     PDC_return_key_modifiers(bool);
int     PDC_save_key_modifiers(bool);

#ifdef XCURSES
WINDOW *Xinitscr(int, char **);
void    XCursesExit(void);
int     sb_init(void);
int     sb_set_horz(int, int, int);
int     sb_set_vert(int, int, int);
int     sb_get_horz(int *, int *, int *);
int     sb_get_vert(int *, int *, int *);
int     sb_refresh(void);
#endif

/*** Functions defined as macros ***/

/* getch() and ungetch() conflict with some DOS libraries */

#define getch()            wgetch(stdscr)
#define ungetch(ch)        PDC_ungetch(ch)

#define COLOR_PAIR(n)      (((chtype)(n) << PDC_COLOR_SHIFT) & A_COLOR)
#define PAIR_NUMBER(n)     (((n) & A_COLOR) >> PDC_COLOR_SHIFT)

/* These will _only_ work as macros */

#define getbegyx(w, y, x)  (y = getbegy(w), x = getbegx(w))
#define getmaxyx(w, y, x)  (y = getmaxy(w), x = getmaxx(w))
#define getparyx(w, y, x)  (y = getpary(w), x = getparx(w))
#define getyx(w, y, x)     (y = getcury(w), x = getcurx(w))

#define getsyx(y, x)       { if (curscr->_leaveit) (y)=(x)=-1; \
                             else getyx(curscr,(y),(x)); }

#ifdef NCURSES_MOUSE_VERSION
# define getmouse(x) nc_getmouse(x)
#endif

/* return codes from PDC_getclipboard() and PDC_setclipboard() calls */

#define PDC_CLIP_SUCCESS         0
#define PDC_CLIP_ACCESS_ERROR    1
#define PDC_CLIP_EMPTY           2
#define PDC_CLIP_MEMORY_ERROR    3

/* PDCurses key modifier masks */

#define PDC_KEY_MODIFIER_SHIFT   1
#define PDC_KEY_MODIFIER_CONTROL 2
#define PDC_KEY_MODIFIER_ALT     4
#define PDC_KEY_MODIFIER_NUMLOCK 8

#if defined(__cplusplus) || defined(__cplusplus__) || defined(__CPLUSPLUS)
# undef bool
}
#endif

#endif  /* __PDCURSES__ */
