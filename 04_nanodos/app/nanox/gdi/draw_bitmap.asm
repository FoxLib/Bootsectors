;
; Отрисовка Bitmap, находящемся в XMS, по заданному Handler EBX
; Координаты (si, di)
;

gdi.pbmpf_opacity   dw 0010h       ; LO=Прозрачный цвет, HI>0 (рисовка сетки)
gdi.pbmpf_width     dw 0
gdi.pbmpf_height    dw 0
gdi.pbmpf_depth     db 0
gdi.pbmpf_y         dw 0
gdi.pbmpf_x1        dw 0
gdi.pbmpf_y1        dw 0

gdi.DrawBitmap:
        
        mov     [gdi.pbmpf_x1], si
        mov     [gdi.pbmpf_y1], di
        mov     [gdi.pbmpf_y], di

        ; Получить структуру
        mov     esi, ebx
        call    XMS.Read32              ; Указатель
        mov     esi, eax        
        
        call    XMS.Read32              ; Ширина
        mov     [gdi.pbmpf_width], ax
        
        call    XMS.Read32              ; Высота
        mov     [gdi.pbmpf_height], ax        
        add     [gdi.pbmpf_y], ax

        call    XMS.Read32              ; Глубина
        dec     al
        mov     [gdi.pbmpf_depth], al

.next_block:

        ; Прочесть новую порцию данных из памяти (1 строка)
        mov     edi, tmpdisk + BASEADDR
        movzx   eax, [gdi.pbmpf_width]
        mov     cl, [gdi.pbmpf_depth]
        shr     eax, cl
        mov     dl, cl
        mov     ecx, eax
        call    XMS.Copy

        ; Только 4-битные цвета
        cmp     dl, 1
        je      .bits4
        jmp     .not_support
        
.bits4: ; 4-х битный цвет
        push    esi            
        mov     cx, [gdi.pbmpf_width]
        shr     cx, 1        
        dec     [gdi.pbmpf_y]
        mov     si, [gdi.pbmpf_x1]
        mov     di, [gdi.pbmpf_y]
        mov     bx, tmpdisk
.lb:    mov     al, [bx]
        shr     al, 4
        cmp     al, byte [gdi.pbmpf_opacity]
        je      @f

        ; У картинки есть наложение цвета
        mov     ah, byte [gdi.pbmpf_opacity + 1]
        and     ah, ah
        je      .pix0              
        mov     dx, si
        xor     dx, di
        and     dl, 1
        je      .pix0
        mov     al, ah
        
.pix0:  call    [SetPixel]        
@@:     inc     si
        mov     al, [bx]
        and     al, 0Fh
        cmp     al, byte [gdi.pbmpf_opacity]
        je      @f
        
        ; У картинки есть наложение цвета
        mov     ah, byte [gdi.pbmpf_opacity + 1]
        and     ah, ah
        je      .pix1
        mov     dx, si
        xor     dx, di
        and     dl, 1
        je      .pix1
        mov     al, ah

.pix1:  call    [SetPixel]
@@:     inc     si
        inc     bx
        loop    .lb            
        pop     esi
        
        ; Рисовать пока не будет достигнут Y=Y1        
        cmp     di, [gdi.pbmpf_y1]
        jnbe    .next_block

.not_support:        
        
        ret

; ----------------------------------------------------------------------
; Аналогично gdi.DrawBitmap, но AL - цвет прозрачности

gdi.DrawBitmapOpacity:

        mov     [gdi.pbmpf_opacity], ax
        call    gdi.DrawBitmap
        mov     [gdi.pbmpf_opacity], 0010h
        ret
        
