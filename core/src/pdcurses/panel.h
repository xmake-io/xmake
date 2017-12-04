/* Public Domain Curses */

/*----------------------------------------------------------------------*
 *                         Panels for PDCurses                          *
 *----------------------------------------------------------------------*/

#ifndef __PDCURSES_PANEL_H__
#define __PDCURSES_PANEL_H__ 1

#include <curses.h>

#if defined(__cplusplus) || defined(__cplusplus__) || defined(__CPLUSPLUS)
extern "C"
{
#endif

typedef struct panelobs
{
    struct panelobs *above;
    struct panel *pan;
} PANELOBS;

typedef struct panel
{
    WINDOW *win;
    int wstarty;
    int wendy;
    int wstartx;
    int wendx;
    struct panel *below;
    struct panel *above;
    const void *user;
    struct panelobs *obscure;
} PANEL;

int     bottom_panel(PANEL *pan);
int     del_panel(PANEL *pan);
int     hide_panel(PANEL *pan);
int     move_panel(PANEL *pan, int starty, int startx);
PANEL  *new_panel(WINDOW *win);
PANEL  *panel_above(const PANEL *pan);
PANEL  *panel_below(const PANEL *pan);
int     panel_hidden(const PANEL *pan);
const void *panel_userptr(const PANEL *pan);
WINDOW *panel_window(const PANEL *pan);
int     replace_panel(PANEL *pan, WINDOW *win);
int     set_panel_userptr(PANEL *pan, const void *uptr);
int     show_panel(PANEL *pan);
int     top_panel(PANEL *pan);
void    update_panels(void);

#if defined(__cplusplus) || defined(__cplusplus__) || defined(__CPLUSPLUS)
}
#endif

#endif /* __PDCURSES_PANEL_H__ */
