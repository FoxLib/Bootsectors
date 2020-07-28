
        org     0x8000
        include "inc/macro.asm"

	cli
	cld

        ; Инициализация
        xor     ax, ax
        xor     sp, sp
        mov     ds, ax
        mov     ss, ax
        mov     ax, $b800
        mov     es, ax
	jmp	$