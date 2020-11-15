; -----------------------------------------
; Подсчет оставшейся памяти
; -----------------------------------------

calc_free_memory:

        mov si, PTR_FAT + 8    ; Начинаем проверку с 256-го байта
        xor dx, dx
        mov cl, 0x7F
.r:     lodsb
        and al, al
        jne @f
        inc dx
@@:     loop .r
        shl dx, 5 
        ret

; -----------------------------------------
; Конвертация числа (AX) в строку (-> nmeric)
; -----------------------------------------

itoa:
        mov cl, 8
        mov si, nmeric + 8
        mov bx, 10
@@:     cwd
        div bx
        add dl, '0'
        dec si
        mov [si], dl
        loop @b
        ret
