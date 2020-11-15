    xchg bx, bx
    mov ax, 0xb800
    mov es, ax

    mov di, 0
    mov al, dl

    ; Выдача байта
    mov ah, 0x17
    push ax    
    
    and al, 0xf0
    shr al, 4
    cmp al, 10
    jc @f
    add al, 7
@@: add al, 0x30
    stosw    
    pop ax

    and al, 0xf
    cmp al, 10
    jc @f
    add al, 7
@@: add al, 0x30
    stosw

    jmp $