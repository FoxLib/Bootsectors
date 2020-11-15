; ----------------------------------------------------------------------
; Алиасы вызовов и переменные

ResolutionX         dw 640 - 1
ResolutionY         dw 480 - 1
PlaneBits           db 4

; ----------------------------------------------------------------------

VGA_AC_INDEX        EQU 0x3C0
VGA_AC_WRITE        EQU 0x3C0
VGA_AC_READ         EQU 0x3C1

VGA_MISC_WRITE      EQU 0x3C2
VGA_SEQ_INDEX       EQU 0x3C4
VGA_SEQ_DATA        EQU 0x3C5

VGA_DAC_READ_INDEX  EQU 0x3C7
VGA_DAC_WRITE_INDEX EQU 0x3C8
VGA_DAC_DATA        EQU 0x3C9

VGA_MISC_READ       EQU 0x3CC
VGA_GC_INDEX        EQU 0x3CE
VGA_GC_DATA         EQU 0x3CF

VGA_CRTC_INDEX      EQU 0x3D4 ; 0x3B4 
VGA_CRTC_DATA       EQU 0x3D5 ; 0x3B5 
VGA_INSTAT_READ     EQU 0x3DA

; Количество регистров
VGA_NUM_SEQ_REGS    EQU 5
VGA_NUM_CRTC_REGS   EQU 25
VGA_NUM_GC_REGS     EQU 9
VGA_NUM_AC_REGS     EQU 21
VGA_NUM_REGS        EQU (1 + VGA_NUM_SEQ_REGS + VGA_NUM_CRTC_REGS + VGA_NUM_GC_REGS + VGA_NUM_AC_REGS)

; ----------------------------------------------------------------------
; Сменить видеорежим 

VGALib.Set640x480:

        mov     [PlaneBits], byte 4     ; 16 цветов
        mov     ax, 0012h
        int     10h

        ; IoWrite16(VGA_GC_INDEX, 0x0205); 
        mov     dx, VGA_GC_INDEX
        mov     ax, 0x0205
        out     dx, ax

        ; Установить палитру 16 бит
        mov     si, VGALib.ColorTable16
        xor     ax, ax
        mov     dx, VGA_DAC_WRITE_INDEX
        out     dx, al
        inc     dx                    

        mov     bx, 16    
@@:     lodsd
        xchg    eax, ecx
        push    bx

        mov     bx, cx
        shr     ecx, 18
        mov     al, cl
        out     dx, al
        mov     al, bh
        shr     al, 2
        out     dx, al
        mov     al, bl
        shr     al, 2
        out     dx, al
        
        pop     bx
        dec     bx
        jne     @b
        
        ret

; ----------------------------------------------------------------------

; Записать один пиксель на экран
; AX - Цвет
; SI - X
; DI - Y

VGALib.SetPixel:

        pushf
        cli

        ; x = [0..639], y = [0..479]
        cmp     si, 640
        jnb     .exit
        cmp     di, 480
        jnb     .exit
        
        ; CLI для того, чтобы не было вызова от мыши
        push    cx di si dx es
        push    ax 

        ; IoWrite16(VGA_GC_INDEX, 0x0008 | (0x8000 >> (x & 7))
        mov     cx, si
        and     cl, 7
        mov     ah, 80h
        shr     ah, cl
        mov     al, 8
        mov     dx, VGA_GC_INDEX
        out     dx, ax
        
        ; addr = di*80 + si>>3
        shr     si, 3
        imul    di, 80
        add     di, si
        mov     ax, 0xA000
        mov     es, ax
        pop     ax
        
        ; Писать точку
        mov     ah, [es: di]
        mov     [es: di], al
        pop     es dx si di cx
        
.exit:  popf
        ret

; ----------------------------------------------------------------------

; Читать один пиксель
; AL - Возвращается цвет
; CX - X
; DX - Y

VGALib.GetPixel:
        
        pushf
        cli
        push    bx        
        mov     ah, 0Dh
        mov     bh, 0        
        int     10h                 ; Использую BIOS для чтения точек
        pop     bx
        popf
        ret

; ----------------------------------------------------------------------
; AX - цвет
; Регион (SI, DI) - (CX, DX)

VGALib.loc.rect.x1      dw 0
VGALib.loc.rect.y1      dw 0
VGALib.loc.rect.x2      dw 0
VGALib.loc.rect.y2      dw 0
VGALib.loc.rect.m1      db 0
VGALib.loc.rect.m2      db 0
VGALib.loc.rect.xa      dw 0
VGALib.loc.rect.xb      dw 0
VGALib.loc.rect.color   db 0

VGALib.FillRectangle:

        pusha
        pushf
        cli
        
        push    es
        
        push    0A000h
        pop     es

        mov     [VGALib.loc.rect.color], al
        mov     [VGALib.loc.rect.x1], si
        mov     [VGALib.loc.rect.x2], cx
        mov     [VGALib.loc.rect.y1], di
        mov     [VGALib.loc.rect.y2], dx        
        mov     dx, VGA_GC_INDEX
        
        ; m1 = (1 << (8 - (x1 & 7))) - 1
        ; xa = (x1 >> 3)
        
        push    si
        mov     cx, 8
        and     si, 7
        sub     cx, si
        mov     al, 1
        shl     al, cl
        dec     al
        mov     [VGALib.loc.rect.m1], al
        pop     si
        shr     si, 3
        mov     [VGALib.loc.rect.xa], si
      
        ; m2 = ((0x7f80) >> (x2 & 7)) & 0xff 
        ; xb = (x2 >> 3)
        mov     cx, [VGALib.loc.rect.x2]
        push    cx
        and     cl, 7
        mov     ax, 0x7f80
        shr     ax, cl
        mov     [VGALib.loc.rect.m2], al
        pop     ax
        shr     ax, 3
        mov     [VGALib.loc.rect.xb], ax
   
        ; if (xb > xa) then 
        cmp     ax, [VGALib.loc.rect.xa]
        jbe     .bounds_single
        
        ; Рисование ЛЕВОЙ половины
        ; IoWrite16(VGA_GC_INDEX, 0x0008 | (m1 << 8))
        mov     ah, [VGALib.loc.rect.m1]
        mov     al, 8
        out     dx, ax
        mov     dx, [VGALib.loc.rect.xa]
        call    .vertical_bar
        
        ; Сплошная средняя линия (по 8 бит)
        ; IoWrite16(VGA_GC_INDEX, 0xFF08)
        ; for (j = xa + 1; j < xb; j++)
        ; for (i = y1; i <= y2; i++) 
        ;     write(80*i + j, c);        

        mov     dx, VGA_GC_INDEX
        mov     ax, 0FF08h
        out     dx, ax
        mov     si, [VGALib.loc.rect.xa]
.xa2xb: inc     si   
        cmp     si,  [VGALib.loc.rect.xb]
        jnb     .horz_end
        mov     dx, si
        call    .vertical_bar
        jmp     .xa2xb
        
.horz_end:

        ; Рисовать правую половину
        ; IoWrite16(VGA_GC_INDEX, 0x0008 | (m2 << 8))
        
        mov     dx, VGA_GC_INDEX
        mov     ah, [VGALib.loc.rect.m2]
        mov     al, 8
        out     dx, ax        
        mov     dx, [VGALib.loc.rect.xb]
        call    .vertical_bar
        jmp     .done
        
.bounds_single:

        ; IoWrite16(VGA_GC_INDEX, 0x0008 | ((m1 & m2) << 8))
        mov     ah, [VGALib.loc.rect.m1]
        and     ah, [VGALib.loc.rect.m2]
        mov     al, 8
        out     dx, ax
        mov     dx, [VGALib.loc.rect.xb]
        call    .vertical_bar

.done:  pop     es
        popf
        popa        
        ret

; Рисование вертикальной черты y1..y2
; for (bx = y1; bx <= y2; bx++)
;     write(80*bx + dx, c)

.vertical_bar:

        mov     al, [VGALib.loc.rect.color]
        mov     bx, [VGALib.loc.rect.y1]
@@:     imul    di, bx, 80
        add     di, dx
        mov     ah, [es: di]
        stosb
        inc     bx
        cmp     bx, [VGALib.loc.rect.y2]
        jb      @b
        ret
        
; ----------------------------------------------------------------------
; Назначить цвет DAC
; AL - номер, ECX - цвет (RR:GG:BB)
        
VGALib.AssignColor:

        push    dx ecx ax bx
        mov     dx, VGA_DAC_WRITE_INDEX
        out     dx, al
        inc     dx
        mov     bx, cx
        shr     ecx, 18
        mov     al, cl
        out     dx, al
        mov     al, bh
        shr     al, 2
        out     dx, al
        mov     al, bl
        shr     al, 2
        out     dx, al
        pop     bx ax ecx dx
        ret

VGALib.ColorTable16:

        dd      0000000h ; 0
        dd      0000080h ; 1
        dd      0008000h ; 2
        dd      0008080h ; 3
        dd      0800000h ; 4
        dd      0808080h ; 5
        dd      0808000h ; 6
        dd      0C0C0C0h ; 7
        ; -- далее vga не поддерживает --
        dd      0888888h ; 8
        dd      00000FFh ; 9
        dd      000FF00h ; 10
        dd      000FFFFh ; 11
        dd      0FF0000h ; 12
        dd      0FF00FFh ; 13
        dd      0FFFF00h ; 14
        dd      0FFFFFFh ; 15
