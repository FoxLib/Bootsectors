;
; Загрузка и рендеринг шрифтов
; ds: dx - ASCIIZ путь к шрифту
;

desktop.Tahoma.name     db 'font/tahoma.bin', 0
desktop.Tahoma.handler  dd 0
desktop.Tahoma.file_id  dw 0

; ----------------------------------------------------------------------
; Загрузка файла в XMS

desktop.Tahoma.Load:

        mov     ax, 3D00h
        mov     dx, desktop.Tahoma.name
        int     21h
        jb      .disk_err
        mov     [desktop.Tahoma.file_id], ax

        ; Размер шрифта всегда фиксирован
        mov     ecx, 2808
        call    XMS.Alloc
        mov     [desktop.Tahoma.handler], eax

        ; Загрузить в XMS
        mov     bp, cx
        mov     bx, [desktop.Tahoma.file_id]
        call    XMS.LoadFile
        
        ; Закрыть и выйти
        mov     ah, 3Eh
        int     21h
        clc
        ret

.disk_err:

        stc
        ret

; ----------------------------------------------------------------------
; (si, di)  Координаты
; al        Символ
; ah        Цвет
; Возврат:
; ax        Кол-во пикселей по ширине
; si        Новое положение курсора

desktop.tahoma.char_x   dw 0
desktop.tahoma.char_y   dw 0
desktop.tahoma.char     dw 0
desktop.tahoma.color    db 0
desktop.tahoma.xyw      dd 0 ; 00.SS.YY.XX
desktop.tahoma.bold     db 0

desktop.Tahoma.Char:

        mov     [desktop.tahoma.char_x], si
        mov     [desktop.tahoma.char_y], di
        mov     [desktop.tahoma.char], ax
        push    bx si di

        ; Реальный адрес
        mov     esi, [desktop.Tahoma.handler]
        call    XMS.Read32
        xchg    eax, esi
        mov     ebp, esi
 
        ; Расчет параметров буквы
        movzx   eax, byte [desktop.tahoma.char]
        imul    ax, 3
        add     esi, eax
        add     esi, 2040
        call    XMS.Read32    
        mov     [desktop.tahoma.xyw], eax
        
        ; Пустой символ не печатать
        cmp     byte [desktop.tahoma.xyw + 2], 0
        je      .null
        
        ; Прорисовка
        mov     dh, 12            
.repy:  push    dx

        ; Y*17 (байт) 
        movzx   ax, byte [desktop.tahoma.xyw + 1]
        mov     bx, 17
        mul     bx
                
        ; X >> 3
        movzx   esi, ax
        movzx   ax, byte [desktop.tahoma.xyw]
        shr     ax, 3
        add     si, ax    
        add     esi, ebp
        
        ; Строка из 32 пикселей
        call    XMS.Read32

        ; Коррекция позиции
        mov     cl, byte [desktop.tahoma.xyw]
        and     cl, 7
        shr     eax, cl
        mov     ecx, eax
        
        ; Количество пикселей по ширине
        mov     di, [desktop.tahoma.char_y]
        mov     si, [desktop.tahoma.char_x]
        mov     dl, byte [desktop.tahoma.xyw + 2]
.repx:  test    cl, 1
        jz      @f
        mov     al, byte [desktop.tahoma.char + 1]
        call    [SetPixel]
@@:     shr     ecx, 1
        inc     si
        dec     dl
        jne     .repx
        
        pop     dx
        inc     [desktop.tahoma.char_y]
        inc     byte [desktop.tahoma.xyw + 1]
        dec     dh
        jne     .repy

        ; Выдать количество пикселей по ширине
        movzx   ax, byte [desktop.tahoma.xyw + 2]
.exit:  pop     di si bx
        add     si, ax
        ret
.null:  mov     ax, 0
        jmp     .exit

; ----------------------------------------------------------------------
; Расчет длины символа AL -> AX

desktop.Tahoma.CharWidth:

        push    esi
        push    eax
        mov     esi, [desktop.Tahoma.handler]
        call    XMS.Read32
        xchg    eax, esi
        pop     eax
        and     eax, 0x00FF    
        imul    ax, 3
        lea     esi, [esi + eax + 2040]
        call    XMS.Read32    
        pop     esi
        shr     eax, 16
        and     ax, 0x00FF
        ret

; ----------------------------------------------------------------------
; Расчет длины строки DS:BX -> DX

desktop.Tahoma.Width:

        xor     dx, dx        
@@:     mov     al, [bx]
        inc     bx
        and     al, al
        je      .term        
        call    desktop.Tahoma.CharWidth
        add     dx, ax
        jmp     @b
.term:  ret

; ----------------------------------------------------------------------
; Пропечатать Zero-Terminated строку
; ds: bx - Строка
; al - цвет
; ah - полужирный (1)
; (si, di) - координаты (si меняется на выходе)

desktop.Tahoma.Print:

        mov     [desktop.tahoma.color], al
        mov     [desktop.tahoma.bold], ah
.rep:   mov     al, [bx]
        inc     bx
        and     al, al
        je      .term
 
        mov     ah, [desktop.tahoma.color]
        call    desktop.Tahoma.Char    
        cmp     [desktop.tahoma.bold], byte 0
        je      .rep

        ; Печать полужирного шрифта (сместить +1)
        sub     si, ax
        inc     si
        mov     ah, [desktop.tahoma.color]
        mov     al, [bx - 1]
        call    desktop.Tahoma.Char        
        jmp     .rep
.term:  ret
