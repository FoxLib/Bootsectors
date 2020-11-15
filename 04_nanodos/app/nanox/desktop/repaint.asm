; Последняя позиция нажатия на мышку

desktop.mouse.x         dw -1
desktop.mouse.y         dw -1
desktop.current_icon    dw -1
desktop.debug           db '00000000', 0

; Печать отладки
desktop.Debug:

        pusha
        push    eax
        mov     si, 80
        mov     di, 480 - 20
        mov     cx, 320
        mov     dx, 479
        mov     al, 7
        call    [FillRectangle]    
        pop     eax
                
        ; --------
        mov     di, desktop.debug
        mov     cx, 8
.rpt:   rol     eax, 4
        mov     bl, al
        and     bl, 15
        cmp     bl, 10
        jb      @f
        add     bl, 7
@@:     add     bl, '0'
        mov     [di], bl
        inc     di
        loop    .rpt
        ; --------
        
        mov     bx, desktop.debug
        mov     ax, 0
        mov     si, 80
        mov     di, 480 - 20
        call    desktop.Tahoma.Print
        popa
        ret

; Полная перерисовка рабочего стола
; ----------------------------------------------------------------------

desktop.Repaint:

        ; Очистка экрана в фоновый цвет
        mov     si, 0
        mov     di, 0
        mov     cx, [ResolutionX]
        mov     dx, [ResolutionY]
        mov     ax, 3
        call    [FillRectangle]

        ; Фоновая картинка
        mov     si, 0
        mov     di, 0
        mov     ebx, [desktop.images.hnd_wallpaper]
        call    gdi.DrawBitmap

        ; Иконки
        call    desktop.RedrawIcons

        ; Кнопка "пуск"
        call    desktop.ButtonStart        
        
        ret

; ----------------------------------------------------------------------
; Обновление иконок
; Ослеживание нажатия левой кнопки мыши и выбор иконки

desktop.UpdateIcons:

        ; ЛКМ нажата?
        mov     al, [PS2Mouse.irq.cmd]
        test    al, 1
        je      .noclk

        ; Предыдущего клика нет?
        cmp     [.MouseClicked], 0
        jne     .ok
                
        mov     [.MouseClicked], 1

        ; ----------            
        call    PS2Mouse.Disable
        call    PS2Mouse.Hide

        ; Сохранить последний клик мыши
        mov     ax, [PS2Mouse.x]
        mov     [desktop.mouse.x], ax
        mov     ax, [PS2Mouse.y]
        mov     [desktop.mouse.y], ax

        call    desktop.RedrawIcons        ; <-- баг где-то тут
        call    PS2Mouse.Show
        call    PS2Mouse.Enable
        ; ----------

        jmp     .ok                
.noclk: mov     [.MouseClicked], 0            
.ok:    ret

.MouseClicked   db 0

; ----------------------------------------------------------------------
; Перерисовка всех загруженных иконок

desktop.RedrawIcons:
    
        ; Проверка позиции нажатия на мышь
        mov     [desktop.current_icon], -1
        xor     cx, cx
        mov     esi, [desktop.images.icons_list]
        sub     [FreeBlock], 128

.dicon: push    cx
        push    esi
        push    cx
        
        ; Чтение параметров
        call    XMS.Read32
        mov     [.loc_name], eax
        
        call    XMS.Read32
        call    XMS.Read32        
        mov     [.loc_icon], eax
        
        call    XMS.Read32
        mov     [.loc_xy], eax

        ; Скопировать имя иконки в tmp_string
        push    esi
        movzx   edi, [FreeBlock]
        add     edi, BASEADDR
        mov     esi, [.loc_name]
        mov     ecx, 128
        call    XMS.Copy
        pop     esi        
        
        ; Из полученных временных параметров нарисовать иконку
        mov     bx, [FreeBlock]
        mov     si, word [.loc_xy]
        mov     di, word [.loc_xy + 2]
        pop     cx
        mov     ax, 0Dh
        
        ; Тест на попадание мыши в регион иконки [si,di]-[si+32,di+50]
        cmp     [desktop.mouse.x], si
        jb      .noregion
        cmp     [desktop.mouse.y], di
        jb      .noregion
        mov     dx, si
        add     dx, 32
        cmp     dx, [desktop.mouse.x]
        jb      .noregion
        mov     dx, di
        add     dx, 50
        cmp     dx, [desktop.mouse.y]
        jb      .noregion
        
        ; Рисовать иконку "выбранной"
        mov     [desktop.current_icon], cx        
        add     ax, 100h        
        
.noregion:
        
        mov     si, word [.loc_xy]
        mov     di, word [.loc_xy + 2]
        mov     edx, [.loc_icon]
        call    desktop.DrawIcon
        
        ; К следующей 
        pop     esi
        pop     cx
        add     esi, 10h
        inc     cx
        cmp     cx, [desktop.images.icons_count]
        jb      .dicon

        add     [FreeBlock], 128
        ret

.loc_name   dd 0
.loc_icon   dd 0
.loc_xy     dd 0

; ----------------------------------------------------------------------
; Отрисовка иконки по позици (si,di) ds:bx
; edx - Icon Handle
; ax  - Цвет | Наложение

desktop.drawIcon.x      dw 0
desktop.drawIcon.y      dw 0
desktop.drawIcon.txt    dw 0

desktop.DrawIcon:

        mov     [desktop.drawIcon.x], si
        mov     [desktop.drawIcon.y], di
        mov     [desktop.drawIcon.txt], bx
    
        ; Рисовать иконку с прозрачным цветом ФИОЛЕТОВЫЙ (=13)
        mov     ebx, edx
        call    gdi.DrawBitmapOpacity

        ; Читается длина строки DS:BX -> DX
        mov     bx, [desktop.drawIcon.txt]
        call    desktop.Tahoma.Width

        ; Рассчитать центр иконки для прорисовки текста
        mov     si, [desktop.drawIcon.x]
        add     si, 16
        
        push    dx
        shr     dx, 1
        sub     si, dx
        sub     si, 4        
        jns     @f
        xor     si, si        
@@:     mov     [desktop.drawIcon.x], si
        add     di, 32 + 8
        
        ; Длина строки
        pop     dx
        mov     cx, [desktop.drawIcon.x]
        add     cx, dx
        add     cx, 7
        
        mov     dx, [desktop.drawIcon.y]
        add     dx, 16 + 32 + 8
        mov     ax, 3
        call    [FillRectangle]

        ; Печать названия
        mov     si, [desktop.drawIcon.x]
        add     si, 4
        mov     di, [desktop.drawIcon.y]
        add     di, 32 + 8 + 2
        mov     bx, [desktop.drawIcon.txt]
        mov     ax, 000Fh
        call    desktop.Tahoma.Print
        ret

; Перерисовать кнопку Пуск
; ----------------------------------------------------------------------

desktop.ButtonStart:

        ; Прорисовать панель управления (высота 28)
        mov     si, 0
        mov     di, 480 - 28
        mov     cx, 639
        mov     dx, 479
        mov     al, 7
        call    [FillRectangle]
        
        ; Полоска
        mov     di, 480 - 27
        mov     dx, di
        mov     al, 15
        call    [FillRectangle]
        
        ; Кнопка
        mov     si, 3
        mov     di, 480 - 24
        mov     cx, 62
        mov     dx, 480 - 4
        call    gdi.Button

        ; Лого
        mov     si, 8
        mov     di, 480 - 22
        mov     ebx, [desktop.images.hnd_winlogo]
        mov     ax, 0Dh
        call    gdi.DrawBitmapOpacity          
        ret
        
