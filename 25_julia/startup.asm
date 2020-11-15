[BITS 32]

[EXTERN main]
[GLOBAL _start]

; ---------------------------------------------------------------
_start: mov     esp, 0x180000
        jmp     main
