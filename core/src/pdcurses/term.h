/* Public Domain Curses */

/* PDCurses doesn't operate with terminfo, but we need these functions for 
   compatibility, to allow some things (notably, interface libraries for 
   other languages) to be compiled. Anyone who tries to actually _use_ 
   them will be disappointed, since they only return ERR. */

#ifndef __PDCURSES_TERM_H__
#define __PDCURSES_TERM_H__ 1

#include <curses.h>

#if defined(__cplusplus) || defined(__cplusplus__) || defined(__CPLUSPLUS)
extern "C"
{
#endif

typedef struct
{
    const char *_termname;
} TERMINAL;

#ifdef PDC_DLL_BUILD
# ifndef CURSES_LIBRARY
__declspec(dllimport)  TERMINAL *cur_term;
# else
__declspec(dllexport) extern TERMINAL *cur_term;
# endif
#else
extern TERMINAL *cur_term;
#endif

int     del_curterm(TERMINAL *);
int     putp(const char *);
int     restartterm(const char *, int, int *);
TERMINAL *set_curterm(TERMINAL *);
int     setterm(const char *);
int     setupterm(const char *, int, int *);
int     tgetent(char *, const char *);
int     tgetflag(const char *);
int     tgetnum(const char *);
char   *tgetstr(const char *, char **);
char   *tgoto(const char *, int, int);
int     tigetflag(const char *);
int     tigetnum(const char *);
char   *tigetstr(const char *);
char   *tparm(const char *, long, long, long, long, long, 
              long, long, long, long);
int     tputs(const char *, int, int (*)(int));

#if defined(__cplusplus) || defined(__cplusplus__) || defined(__CPLUSPLUS)
}
#endif

#endif /* __PDCURSES_TERM_H__ */
