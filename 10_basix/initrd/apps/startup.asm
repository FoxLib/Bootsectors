[BITS 32]

[EXTERN main]
[GLOBAL _start]
[GLOBAL kcall]

_start: jmp     main

; Системные вызовы
kcall:

        push    ebp
        lea     ebp, [esp + 4]
        mov     eax, [ebp + 4]  ; mode
        mov     edx, [ebp + 8]  ; ref* 
        call    [eax]           ; это типа такой вызов к ядру, потому что типа int ацтой
        pop     ebp
        ret
        
