; **********************************************************************
; ОС SILK работает, используя предзагруженный из BIOS режим VGA
; Это первичный драйвер, который используется при загрузке системы и 
; последующем ее использовании до того, как можно будет сделать вызов
; рисования через SVGA и другие методы
; **********************************************************************

    include "vga/font8x8rus.asm"
    include "vga/print.asm"

display_vga_init:

    ; Запись текущего видеорежима 640x480x16 
    mov     [VIDEO_WIDTH],  word 640
    mov     [VIDEO_HEIGHT], word 480
    mov     [VIDEO_DEPTH],  word 4
    
    ; Инициализация
    mov     [iterm.print_sz],   dword display_vga_print_sz
    mov     [iterm.putc],       dword display_vga_putc
        
    ret

