#include <curses.h>

int main()
{
    if (initscr()) return endwin();
}
