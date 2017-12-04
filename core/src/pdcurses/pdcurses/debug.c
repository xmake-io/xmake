/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

debug
-----

### Synopsis

    void traceon(void);
    void traceoff(void);
    void PDC_debug(const char *, ...);

### Description

   traceon() and traceoff() toggle the recording of debugging
   information to the file "trace". Although not standard, similar
   functions are in some other curses implementations.

   PDC_debug() is the function that writes to the file, based on
   whether traceon() has been called. It's used from the PDC_LOG()
   macro.

### Portability
                             X/Open    BSD    SYS V
    traceon                     -       -       -
    traceoff                    -       -       -
    PDC_debug                   -       -       -

**man-end****************************************************************/

#include <string.h>
#include <sys/types.h>
#include <time.h>

bool pdc_trace_on = FALSE;

void PDC_debug(const char *fmt, ...)
{
    va_list args;
    FILE *dbfp;
    char hms[9];
    time_t now;

    if (!pdc_trace_on)
        return; 

    /* open debug log file append */

    dbfp = fopen("trace", "a");
    if (!dbfp)
    {
        fprintf(stderr,
            "PDC_debug(): Unable to open debug log file\n");
        return;
    }

    time(&now);
    strftime(hms, 9, "%H:%M:%S", localtime(&now));
    fprintf(dbfp, "At: %8.8ld - %s ", (long) clock(), hms);

    va_start(args, fmt);
    vfprintf(dbfp, fmt, args);
    va_end(args);

    fclose(dbfp);
}

void traceon(void)
{
    PDC_LOG(("traceon() - called\n"));

    pdc_trace_on = TRUE;
}

void traceoff(void)
{
    PDC_LOG(("traceoff() - called\n"));

    pdc_trace_on = FALSE;
}
