-start=                      &
RESET,                       &
EIINTTBL/0,                  &
.const,                      &
.INIT_DSEC.const,            &
.INIT_BSEC.const,            &
.text,                       &
.data/00008000,              &
.data.R,                     &
.bss,                        &
.stack.bss/FEDE8000

-rom=                        &
.data=.data.R
