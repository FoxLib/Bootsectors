; Установка видеорежима VGA из BIOS
vga_set_320x200:

    mov ax, 0x0013
    int 0x10
    ret