; 
; УСТАНОВКА МАКСИМАЛЬНОГО РАЗРЕШЕНИЯ
; 

; Установленное самое большое допустимое разрешение
vesa.vmode            dw 0      ; Номер видеорежима
vesa.width            dd 0      ; Ширина
vesa.height           dd 0      ; Высота
vesa.linear           dd 0      ; Указатель на фреймбуфер
vesa.color            dw 0FFFFh ; Цвет
vesa.bgcolor          dw 018Eh  ; Цвет фона

; ----------------------------------------------------------------------
; ARG   void
; RET   nil

vesa.SetMaximalMode:

        mov     ax, 0x4f00          ; Получение списка видеорежимов
        mov     di, VBE20_ICTRL
        int     10h
        cmp     ax, 0x004f          ; VESA не поддерживается
        jne     .vesa_error
        cmp     [VBE20_ICTRL + 4], word 0200h ; VESA менее чем 2.0
        jb      .vesa_error
        lds     si, [VBE20_ICTRL + 0Eh]     ; Указатель на список видеорежимов

        ; Проверка следующего видеорежима
        ; См. http://www.delorie.com/djgpp/doc/rbinter/it/79/0.html

.next:  lodsw
        cmp     ax, $ffff
        je      .done
        mov     cx, ax
        mov     ax, 4f01h
        mov     di, VBE20_IVIDEO
        int     10h
        cmp     al, 4fh
        jne     .vesa_error

        ; Количество бит на пиксель
        ; Интересны лишь только 16 битные (WORD)
        cmp     [es: VBE20_IVIDEO + 19h], byte 16
        jne     .next

        ; Записывается максимально допустимое разрешение
        or      cx, 4000h                         ; Последний запрошенный видеорежим
        mov     ax,  [es: VBE20_IVIDEO + 12h]     ; Ширина в пикселях
        mov     bx,  [es: VBE20_IVIDEO + 14h]     ; Высота в пикселях
        mov     edx, [es: VBE20_IVIDEO + 28h]     ; Адрес фреймбуфера
        mov     word [cs: vesa.width],  ax
        mov     word [cs: vesa.height], bx
        mov     word [cs: vesa.vmode],  cx
        mov          [cs: vesa.linear], edx

        ; Отладочный видеорежим 117h для BOCHS (на реальных CPU убрать опцию)
        if defined BX_DBG
        cmp     cx, 4117h
        je      .done          
        end if
        
        jmp     .next
        
        ; Установка последнего запрошенного видеорежима
.done:  mov     ax, 4f02h
        mov     bx, [cs: vesa.vmode]
        int     10h
        ret

.vesa_error:

        ; просто висим пока что без движения
        jmp     $
