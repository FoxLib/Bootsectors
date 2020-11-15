
; Библиотечные функции
; 
; lib_grayscale_palette()
;
; ======================

; Создает палитру 0 .. 255 для видеорежима 320x200
; ------------------------------------------------------------------------------------------------------------

lib_grayscale_palette:

    mov ecx, 255

.pal:

    mov dx, 0x3C8
    mov al, cl
    inc dx
    mov al, cl
    shr al, 2
    out dx, al
    out dx, al
    out dx, al
    inc al
    loop .pal
    ret