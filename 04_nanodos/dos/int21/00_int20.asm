; Тотальное завершение программы
; Вернуть управление передающей программе (предыдущему значению из стека)

dos.int21h.Int20:

        ; Восстановление сегмента, где находится текущий PSP программы
        mov     ds, [cs: dos.param.psp_parent]

        ; Восстановить значение PSP parent
        mov     bx, [16h]
        mov     [cs: dos.param.psp_parent], bx
        mov     sp, [2Eh]
        
        ; Восстановить top_segment тоже
        mov     ax, [02h]
        mov     [cs: dos.param.top_segment], ax
        
        ; Восстановление сегментов
        mov     ax, [ds: 30h]
        mov     ss, ax
        mov     ds, bx
        mov     es, bx        
        xor     ax, ax
        mov     fs, ax
        mov     gs, ax
        iret
