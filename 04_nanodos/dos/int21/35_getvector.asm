;
; Загрузить в ES:BX вектор прерывания
;

dos.Int21h.GetVector:

        mov     bx, word [cs: dos.int21h.eax]
        mov     bh, 0
        shl     bx, 2
        mov     dx, [fs: bx]
        mov     es, [fs: bx + 2]        
        mov     word [cs: dos.int21h.ebx], dx
        ret
        
