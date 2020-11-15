
; --------------------------------------
; DESCRIPTOR* gdi.LoadBMP(ds:dx Filename AsciiZ)
;
; Загрузка BMP в Memory Handler (BX)
; @return  eax (если =0, изображение не загружено)

gdi.lbmp_handler   dw 0
gdi.lbmp_id        dd 0
gdi.lbmp_width     dw 0
gdi.lbmp_height    dw 0
gdi.lbmp_depth     dw 0     ; 1,2,3,4,5...

gdi.LoadBMP:

        ; Создать временный буфер в 512 байт
        sub     [FreeBlock], 512
        mov     bp, [FreeBlock]
        
        ; Попытка открыть файл
        mov     ax, 3D00h
        int     21h
        jb      .skip_image
        
        ; Прочитать BITMAPFILEHEADER
        mov     bx, ax
        mov     [gdi.lbmp_handler], ax

        mov     ah, 3Fh
        mov     cx, 14
        mov     dx, bp
        int     21h
        jb      .close_file
        
        ; Это формат BMP? Если нет - закрыть и не читать файл        
        cmp     [bp], word 4D42h
        jne     .close_file
        
        ; Прочитать BITMAPINFO
        mov     cx, [bp + 0Ah]
        sub     cx, 14
        mov     ah, 3Fh
        mov     dx, bp
        int     21h
        jb      .close_file

        ; Сокращенный заголовок не поддерживается
        mov     eax, [bp]
        cmp     eax, 12
        je      .not_support

        ; Ширина, высота, битность
        mov     ax, [bp + 4]
        mov     bx, [bp + 8]
        mov     [gdi.lbmp_width], ax        
        mov     [gdi.lbmp_height], bx        
        and     eax, 0FFFFh
        and     ebx, 0FFFFh
        imul    eax, ebx

        ; Битность. Расчет количества бит на точку
        mov     cx, [bp + 0Eh]
        mov     [gdi.lbmp_depth], -1
@@:     shl     eax, 1
        inc     [gdi.lbmp_depth]
        shr     cl, 1
        jnc     @b
        shr     eax, 4
        
        ; Размер данных: 12 (struct) + RawData
        mov     ebp, eax
        mov     ecx, eax
        add     ecx, 12
        call    XMS.Alloc
        mov     [gdi.lbmp_id], eax

        ; СТРУКТУРА ДАННЫХ
        ; dword width
        ; dword height
        ; dword depth
        ; void  pixeldata
        
        movzx   eax, [gdi.lbmp_width]
        call    XMS.Write32

        movzx   eax, [gdi.lbmp_height]
        call    XMS.Write32

        movzx   eax, [gdi.lbmp_depth]
        call    XMS.Write32

.readbmp:

        ; Прочитать следующую порцию данных
        mov     ah, 3Fh
        mov     cx, 512
        mov     bx, [gdi.lbmp_handler]
        mov     dx, [FreeBlock]
        int     21h
        jb      .close_file ; ERR: Ошибка чтения           
        and     ax, ax      ; EOF: Конец файла
        je      @f

        ; Из ESI, скопировать до 512 байт
        movzx   esi, dx
        add     esi, BASEADDR
        cmp     ebp, 512
        jnb     @f
        mov     cx, bp
@@:     movzx   ecx, cx
        call    XMS.Copy

        ; При превышении размера загружаемого файла, выход
        sub     ebp, 512
        js      @f
        je      @f
        jmp     .readbmp

        ; Восстановить справедливость
@@:     mov     ah, 3Eh
        mov     bx, [gdi.lbmp_handler]
        int     21h
        add     [FreeBlock], 512
        mov     eax, [gdi.lbmp_id]
        clc
        ret

; ------------
; ОШИБКИ
; ------------

.err_read:
.not_support:
.close_file:

        ; Закрытие файла
        mov     ah, 3Eh
        mov     bx, [gdi.lbmp_handler]
        int     21h

.skip_image:        
        
        add     [FreeBlock], 512
        xor     eax, eax
        stc
        ret
