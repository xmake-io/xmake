format MZ

entry main:start                        ; program entry point
stack 100h                              ; stack size

segment main                            ; main program segment

  start:
        mov     ax,text
        mov     ds,ax

        mov     dx,hello
        call    extra:write_text

        mov     ax,4C00h
        int     21h

segment text

  hello db 'Hello world!',24h

segment extra

  write_text:
        mov     ah,9
        int     21h
        retf       
    
