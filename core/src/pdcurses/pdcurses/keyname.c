/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

keyname
-------

### Synopsis

    char *keyname(int key);

    char *key_name(wchar_t c);

    bool has_key(int key);

### Description

   keyname() returns a string corresponding to the argument key.
   key may be any key returned by wgetch().

   key_name() is the wide-character version. It takes a wchar_t
   parameter, but still returns a char *.

   has_key() returns TRUE for recognized keys, FALSE otherwise.
   This function is an ncurses extension.

### Portability
                             X/Open    BSD    SYS V
    keyname                     Y       -      3.0
    key_name                    Y
    has_key                     -       -       -

**man-end****************************************************************/

#include <string.h>

char *keyname(int key)
{
    static char _keyname[14];

    /* Key names must be in exactly the same order as in curses.h */

    static char *key_names[] =
    {
        "KEY_BREAK", "KEY_DOWN", "KEY_UP", "KEY_LEFT", "KEY_RIGHT",
        "KEY_HOME", "KEY_BACKSPACE", "KEY_F0", "KEY_F(1)", "KEY_F(2)",
        "KEY_F(3)", "KEY_F(4)", "KEY_F(5)", "KEY_F(6)", "KEY_F(7)",
        "KEY_F(8)", "KEY_F(9)", "KEY_F(10)", "KEY_F(11)", "KEY_F(12)",
        "KEY_F(13)", "KEY_F(14)", "KEY_F(15)", "KEY_F(16)", "KEY_F(17)",
        "KEY_F(18)", "KEY_F(19)", "KEY_F(20)", "KEY_F(21)", "KEY_F(22)",
        "KEY_F(23)", "KEY_F(24)", "KEY_F(25)", "KEY_F(26)", "KEY_F(27)",
        "KEY_F(28)", "KEY_F(29)", "KEY_F(30)", "KEY_F(31)", "KEY_F(32)",
        "KEY_F(33)", "KEY_F(34)", "KEY_F(35)", "KEY_F(36)", "KEY_F(37)",
        "KEY_F(38)", "KEY_F(39)", "KEY_F(40)", "KEY_F(41)", "KEY_F(42)",
        "KEY_F(43)", "KEY_F(44)", "KEY_F(45)", "KEY_F(46)", "KEY_F(47)",
        "KEY_F(48)", "KEY_F(49)", "KEY_F(50)", "KEY_F(51)", "KEY_F(52)",
        "KEY_F(53)", "KEY_F(54)", "KEY_F(55)", "KEY_F(56)", "KEY_F(57)",
        "KEY_F(58)", "KEY_F(59)", "KEY_F(60)", "KEY_F(61)", "KEY_F(62)",
        "KEY_F(63)", "KEY_DL", "KEY_IL", "KEY_DC", "KEY_IC", "KEY_EIC",
        "KEY_CLEAR", "KEY_EOS", "KEY_EOL", "KEY_SF", "KEY_SR",
        "KEY_NPAGE", "KEY_PPAGE", "KEY_STAB", "KEY_CTAB", "KEY_CATAB",
        "KEY_ENTER", "KEY_SRESET", "KEY_RESET", "KEY_PRINT", "KEY_LL",
        "KEY_ABORT", "KEY_SHELP", "KEY_LHELP", "KEY_BTAB", "KEY_BEG",
        "KEY_CANCEL", "KEY_CLOSE", "KEY_COMMAND", "KEY_COPY",
        "KEY_CREATE", "KEY_END", "KEY_EXIT", "KEY_FIND", "KEY_HELP",
        "KEY_MARK", "KEY_MESSAGE", "KEY_MOVE", "KEY_NEXT", "KEY_OPEN",
        "KEY_OPTIONS", "KEY_PREVIOUS", "KEY_REDO", "KEY_REFERENCE",
        "KEY_REFRESH", "KEY_REPLACE", "KEY_RESTART", "KEY_RESUME",
        "KEY_SAVE", "KEY_SBEG", "KEY_SCANCEL", "KEY_SCOMMAND",
        "KEY_SCOPY", "KEY_SCREATE", "KEY_SDC", "KEY_SDL", "KEY_SELECT",
        "KEY_SEND", "KEY_SEOL", "KEY_SEXIT", "KEY_SFIND", "KEY_SHOME",
        "KEY_SIC", "UNKNOWN KEY", "KEY_SLEFT", "KEY_SMESSAGE",
        "KEY_SMOVE", "KEY_SNEXT", "KEY_SOPTIONS", "KEY_SPREVIOUS",
        "KEY_SPRINT", "KEY_SREDO", "KEY_SREPLACE", "KEY_SRIGHT",
        "KEY_SRSUME", "KEY_SSAVE", "KEY_SSUSPEND", "KEY_SUNDO",
        "KEY_SUSPEND", "KEY_UNDO", "ALT_0", "ALT_1", "ALT_2", "ALT_3",
        "ALT_4", "ALT_5", "ALT_6", "ALT_7", "ALT_8", "ALT_9", "ALT_A",
        "ALT_B", "ALT_C", "ALT_D", "ALT_E", "ALT_F", "ALT_G", "ALT_H",
        "ALT_I", "ALT_J", "ALT_K", "ALT_L", "ALT_M", "ALT_N", "ALT_O",
        "ALT_P", "ALT_Q", "ALT_R", "ALT_S", "ALT_T", "ALT_U", "ALT_V",
        "ALT_W", "ALT_X", "ALT_Y", "ALT_Z", "CTL_LEFT", "CTL_RIGHT",
        "CTL_PGUP", "CTL_PGDN", "CTL_HOME", "CTL_END", "KEY_A1",
        "KEY_A2", "KEY_A3", "KEY_B1", "KEY_B2", "KEY_B3", "KEY_C1",
        "KEY_C2", "KEY_C3", "PADSLASH", "PADENTER", "CTL_PADENTER",
        "ALT_PADENTER", "PADSTOP", "PADSTAR", "PADMINUS", "PADPLUS",
        "CTL_PADSTOP", "CTL_PADCENTER", "CTL_PADPLUS", "CTL_PADMINUS",
        "CTL_PADSLASH", "CTL_PADSTAR", "ALT_PADPLUS", "ALT_PADMINUS",
        "ALT_PADSLASH", "ALT_PADSTAR", "ALT_PADSTOP", "CTL_INS",
        "ALT_DEL", "ALT_INS", "CTL_UP", "CTL_DOWN", "CTL_TAB",
        "ALT_TAB", "ALT_MINUS", "ALT_EQUAL", "ALT_HOME", "ALT_PGUP",
        "ALT_PGDN", "ALT_END", "ALT_UP", "ALT_DOWN", "ALT_RIGHT",
        "ALT_LEFT", "ALT_ENTER", "ALT_ESC", "ALT_BQUOTE",
        "ALT_LBRACKET", "ALT_RBRACKET", "ALT_SEMICOLON", "ALT_FQUOTE",
        "ALT_COMMA", "ALT_STOP", "ALT_FSLASH", "ALT_BKSP", "CTL_BKSP",
        "PAD0", "CTL_PAD0", "CTL_PAD1", "CTL_PAD2", "CTL_PAD3",
        "CTL_PAD4", "CTL_PAD5", "CTL_PAD6", "CTL_PAD7","CTL_PAD8",
        "CTL_PAD9", "ALT_PAD0", "ALT_PAD1", "ALT_PAD2", "ALT_PAD3",
        "ALT_PAD4", "ALT_PAD5", "ALT_PAD6", "ALT_PAD7", "ALT_PAD8",
        "ALT_PAD9", "CTL_DEL", "ALT_BSLASH", "CTL_ENTER",
        "SHF_PADENTER", "SHF_PADSLASH", "SHF_PADSTAR", "SHF_PADPLUS",
        "SHF_PADMINUS", "SHF_UP", "SHF_DOWN", "SHF_IC", "SHF_DC",
        "KEY_MOUSE", "KEY_SHIFT_L", "KEY_SHIFT_R", "KEY_CONTROL_L",
        "KEY_CONTROL_R", "KEY_ALT_L", "KEY_ALT_R", "KEY_RESIZE",
        "KEY_SUP", "KEY_SDOWN"
    };

    PDC_LOG(("keyname() - called: key %d\n", key));

    strcpy(_keyname, ((key >= 0) && (key < 0x80)) ? unctrl((chtype)key) :
           has_key(key) ? key_names[key - KEY_MIN] : "UNKNOWN KEY");

    return _keyname;
}

bool has_key(int key)
{
    PDC_LOG(("has_key() - called: key %d\n", key));

    return (key >= KEY_MIN && key <= KEY_MAX);
}

#ifdef PDC_WIDE
char *key_name(wchar_t c)
{
    PDC_LOG(("key_name() - called\n"));

    return keyname((int)c);
}
#endif
