
        org     8000h
        macro   brk {  xchg    bx, bx }
         
        ; Переход в графический режим сразу же
        mov     ax, 0012h        
        int     10h            

        ; Загрузка регистра GDT/IDT
        lgdt    [GDTR]      
        lidt    [IDTR] 

        cli
        cld

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

        ; Включить SSE
        mov     eax, cr0
        and     ax, 0xFFFB              ; clear coprocessor emulation CR0.EM
        or      ax, 0x2                 ; set coprocessor monitoring  CR0.MP
        mov     cr0, eax
        mov     eax, cr4
        or      ax, 3 shl 9             ; set CR4.OSFXSR and CR4.OSXMMEXCPT at the same time
        mov     cr4, eax
  
        ; Выровнять код
        std
        mov     esi, os + len
        mov     edi, $9000 + len
        mov     ecx, len + 1
        rep     movsb
        cld
        jmp     10h : 9000h

os:     file    "kernel.c.bin"
len =   $ - os
        
