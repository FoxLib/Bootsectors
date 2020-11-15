; ax - input
debug_print16_bit:

    push ax bx cx dx 
    mov  cx, 4

@dp16bit_loop:

    rol  ax, 4

    push ax
    mov ah, 0x0E
    and al, 0x0F
    cmp al, 10
    jb  $+4
    add al, 7
    add al, '0'

    mov bx, 7
    int 0x10

    pop ax
    dec cx
    jne @dp16bit_loop

    mov ax, 0xe20
    int 0x10

    pop dx cx bx ax
    ret

debug_lnlf:

    push ax bx cx dx
    mov ax, 0x0E0D
    mov bx, 0x0007
    int 0x10
    mov ax, 0x0E0A
    int 0x10
    pop dx cx bx ax
    ret