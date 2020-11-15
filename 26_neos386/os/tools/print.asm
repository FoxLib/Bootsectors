; ----------------------------------
print:  ; bx
        mov     cx, 4
.lp:    rol     bx, 4
        mov     ax, bx
        and     ax, 0Fh
        cmp     ax, 10
        jb      @f
        add     al, 7
@@:     add     al, '0'
        mov     ah, 0Eh
        int     10h
        loop    .lp
        ret
