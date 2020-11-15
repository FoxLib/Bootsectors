;
; Закрыть файл с обновлением даты, времени
; BX содержит описатель файла (handle), возвращенный при открытии. 
; Файл, представленный этим описателем, закрывается, и оглавление 
; обновляется корректными размером, временем и датой.
; 

dos.int21h.CloseFile:

        ; Расчет адреса блока с данными о файле  
        mov     bx, word [cs: dos.int21h.ebx]
        shl     bx, 5       
        add     bx, dos.param.files
        
        ; Очистка Handler
        mov     cx, 32
.loop:  mov     [fs: bx], byte 0
        inc     bx
        loop    .loop

        ; Сбросить CF=0
        and     byte [cs: dos.int21h.flags], 0xFE
        ret
        
