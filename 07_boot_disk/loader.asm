
        org     8000h
        macro   brk {  xchg    bx, bx }
        
        ; Переход в текстовый режим
        mov     ax, 0003h
        int     10h
                
        ; Загрузка регистра GDT/IDT
        lgdt    [GDTR]      
        lidt    [IDTR] 

        ; Вход в Protected Mode
        mov     eax, cr0
        or      al, 1
        mov     cr0, eax
        jmp     10h : pm        

; ----------------------------------------------------------------------
GDTR:   dw 3*8 - 1                  ; Лимит GDT (размер - 1)
        dq GDT                      ; Линейный адрес GDT 
IDTR:   dw 256*8 - 1                ; Лимит GDT (размер - 1)
        dq 0                        ; Линейный адрес GDT          
GDT:    dw 0,      0,    0,     0   ; 00 NULL-дескриптор
        dw 0FFFFh, 0, 9200h, 00CFh  ; 08 32-битный дескриптор данных
        dw 0FFFFh, 0, 9A00h, 00CFh  ; 10 32-bit код
; ----------------------------------------------------------------------

        use32        
        
        ; Установка сегментов
pm:     mov     ax, 8
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     fs, ax
        mov     gs, ax

        ; Скопировать ядро в память
        mov     esi, os
        mov     edi, 100000h
        mov     ecx, len
        rep     movsb
        jmp     100000h
        
os:     file    "kernel.c.bin"
len =   $ - os
        
