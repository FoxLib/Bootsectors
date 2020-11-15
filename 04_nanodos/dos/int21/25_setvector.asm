;
; Загрузить в ES:BX вектор прерывания
;

dos.Int21h.SetVector:

        mov     bx, word [cs: dos.int21h.eax]
        mov     bh, 0
        shl     bx, 2
        mov     ax, word [cs: dos.int21h.edx]
        mov     [fs: bx], ax
        mov     [fs: bx + 2], ds
        ret
        
