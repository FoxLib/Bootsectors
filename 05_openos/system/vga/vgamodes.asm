; ОПИСАТЕЛИ ВИДЕОРЕЖИМОВ
; AC: http://www.osdever.net/FreeVGA/vga/attrreg.htm 

VGA_TEXT_80x25:

.misc:
        db 0x67

.seq:
        db 0x03, 0x00, 0x03, 0x00, 0x02

.crtc:        
        db 0x5F, 0x4F, 0x50, 0x82, 0x55, 0x81, 0xBF, 0x1F
        db 0x00, 0x4F, 0x0D, 0x0E, 0x00, 0x00, 0x00, 0x50
        db 0x9C, 0x0E, 0x8F, 0x28, 0x1F, 0x96, 0xB9, 0xA3
        db 0xFF

.gc:
        db 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x0E, 0x00
        db 0xFF

.ac:
        db 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x14, 0x07
        db 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F
        db 0x0C, 0x00, 0x0F, 0x08, 0x00

VGA_MODE_640x480:
; ----------------------------------------------------------__

.misc:    
        db  0xE3

.seq:   ; биты
        db  0x03, 0x01, 0x0F, 0x00, 0x06

.crtc:
        db  0x5F, 0x4F, 0x50, 0x82, 0x54, 0x80, 0x0B, 0x3E
        db  0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        db  0xEA, 0x8C, 0xDF, 0x28, 0x00, 0xE7, 0x04, 0xE3
        db  0xFF

.gc:                                ; 03 (было)
        db  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x0F
        db  0xFF

.ac:
        db  0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x14, 0x07
        db  0x38, 0x09, 0x3A, 0x0B, 0x3C, 0x0D, 0x3E, 0x0F
        db  0x01, 0x01, 0x0F, 0x03, 0x00


VGA_MODE_320x200:
; ----------------------------------------------------------__

.misc:
        db 0x63 ; Установки  I/OAS "Input/Output Address Select"
                ; RAM Enabled
                ; O/E "Odd/Even Page Select" 
                ; Horizontal Sync Polarity = 1 (Negative)

.seq:        
        db 0x03, 0x01, 0x0F, 0x00, 0x0E

.crtc:
        db 0x5F, 0x4F, 0x50, 0x82, 0x54, 0x80, 0xBF, 0x1F
        db 0x00, 0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        db 0x9C, 0x0E, 0x8F, 0x28, 0x40, 0x96, 0xB9, 0xA3
        db 0xFF

.gc:
        db 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x05, 0x0F
        db 0xFF

.ac: ; Маппинг цветов (16)    
        db 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
        db 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F

        db 0x41 ; 0x10: ATGE | 8BIT (8 бит, графический режим)
        db 0x00 ; 0x11: Цвет бордюра 0
        db 0x0F ; 0x12: Битовая маска для цветов в памяти  
        db 0x00 ; 0x13: Сдвиг влево по горизонтали видеопамяти (для скроллинга)
        db 0x00 ; 0x14: Выбор палитры (0 палитра);

; ----------------------------------------------
; ВИДЕОРЕЖИМ 640x480
; ----------------------------------------------
vga_640x480:

        mov esi, VGA_MODE_640x480
        call vga_write_regs

        ; Сброс битовой карты
        call vga_bit_clear

        ; Очистка экрана от "мусора" в 0x00
        mov edi, 0xa0000
        mov ecx, 480*80
        mov al,  0x00
@@:     mov ah, [es:edi]
        stosb       
        loop @b
        ret

; ----------------------------------------------
; ВИДЕОРЕЖИМ 320x200
; ----------------------------------------------

vga_320x200:

        mov  esi, VGA_MODE_320x200
        call vga_write_regs

        ; Сбросить экран в черный цвет
        xor eax, eax
        mov edi, 0xA0000
        mov ecx, 65536 / 4
        rep stosd
        ret

; ----------------------------------------------
; ВИДЕОРЕЖИМ 80x25 (ТЕКСТОВЫЙ)
; ----------------------------------------------

vga_80x25:

        mov  esi, VGA_TEXT_80x25
        call vga_write_regs

        ; перезаписать шрифты в видеопамять
        ; mov esi, VGA_FONT_8x16_FIXED
        ; call vga_set_font

        mov  ax,  0x0720
        mov  edi, 0xB8000
        mov  ecx, 2000
        rep  stosw

        ret