; ============================================
; Процедура регистрации базовых элементов Desktop
; ============================================
basic_desktop_components_register:

    ; Вычисление размера экрана
    mov ax, word [SCREEN_WIDTH]

    ; Размер по ширине рабочего стола и taskbar имеют одинаковое значение
    mov [UICOM_desktop + COM_BASIC_W], ax
    mov [UICOM_taskbar + COM_BASIC_W], ax

    mov ax, word [SCREEN_HEIGHT]
    mov [UICOM_desktop + COM_BASIC_H], ax

    ; Панель задач имеет высоту 30 пикселей
    sub ax, 30    
    mov [UICOM_taskbar + COM_BASIC_Y], ax

    ; Иконка "Дом" по центру панели задач
    add ax, 7
    mov [UICOM_home_icon + COM_BASIC_Y], ax

    ; Регистрация компонента "фон"
    mov esi, UICOM_desktop
    call com_register

    ; Градиент панели задач
    mov esi, UICOM_taskbar
    call com_register

    ; Иконка "дом"
    mov esi, UICOM_home_icon
    call com_register

; ----------------------------------------

    ; ... проверка ... (todo)

    ; mov esi, UICOM_nawindow
    mov esi, UICOM_topwindow
    call com_register

    mov esi, UICOM_text_under
    call com_register

    mov esi, UICOM_text
    call com_register

    mov esi, UICOM_winblock
    call com_register
    ret


; Получить позицию пикселя по X, Y (блок DS:EBX)
; EDI = 4*(screen_width * Y + X)
; EDX = 4*screen_width
; --------------------------------------------------
get_pixel_position:

    push  eax ecx
    movzx eax, word [ebx + COM_BASIC_Y]
    mul   dword [SCREEN_WIDTH]
    movzx ecx, word [ebx + COM_BASIC_X]
    add   eax, ecx
    mov   edx, [SCREEN_WIDTH]
    shl   edx, 2
    lea   edi, [4*eax]
    pop   ecx eax
    ret

; --------------------------------------------------
; Рисование закрашенного прямоугольника
; DS:EBX - блок параметров
; ES - указатель на сегмент видеопамяти
; --------------------------------------------------

ui_rectangle:

    call get_pixel_position

    mov   eax, [ebx + COM_BASIC_DATA] ; Цвет пикселя
    movzx ecx, word [ebx + COM_BASIC_W] ; Ширина
    movzx ebx, word [ebx + COM_BASIC_H] ; Высота

@rect_loopy:

    push ecx edi
    rep  stosd
    pop  edi ecx

    add  edi, edx
    dec  ebx
    jne  @rect_loopy
    ret    

; --------------------------------------------------
; Рисование градиента для компонента
; --------------------------------------------------

ui_gradient:

    call get_pixel_position
    
    mov   esi, [ebx + COM_BASIC_DATA + 2]  ; Указатель на данные 
    movzx ecx, word [ebx + COM_BASIC_W]    ; Ширина
    movzx ebx, word [ebx + COM_BASIC_DATA] ; Высота градиента

@ui_gradient_loopy:

    lodsd

    push ecx edi
    rep  stosd
    pop  edi ecx

    add edi, edx 
    dec ebx
    jne @ui_gradient_loopy
 
    ret

; --------------------------------------------------
; Системная иконка 4 бита
; --------------------------------------------------

ui_icon_4bit:

    call get_pixel_position
    mov esi, [ebx + COM_BASIC_DATA]

    mov cl, 16

@ui_icon4_loopy:

    mov ch, 4 
    push ecx edi ebx

@ui_icon4_loopx:

    mov cl, 4 
    lodsb

@ui_icon4_loop4x:

    rol al, 2
    mov ah, al
    and ah, 0x03    
    je  @ui_icon4_next

    mov ebx, 0x00A0A0A0 ; Серый
    cmp ah, 0x01
    je @ui_icon4_put

    mov ebx, 0x00808080 ; Темно-серый
    cmp ah, 0x02
    je @ui_icon4_put

    mov ebx, 0x00FFFFFF ; Белый

@ui_icon4_put:

    mov [es:edi], ebx

@ui_icon4_next:

    add edi, 4

@ui_icon4_after:

    dec cl
    jne @ui_icon4_loop4x

    dec ch
    jne @ui_icon4_loopx

    pop ebx edi ecx

    add edi, edx
    dec cl
    jne @ui_icon4_loopy
    ret

; --------------------------------------------------
; Однострочный системный текст (только англ.)
; --------------------------------------------------

ui_text:

    call get_pixel_position
    mov esi, [ebx + COM_BASIC_DATA + 4] ; Указатель на текст

    mov [ebx + COM_BASIC_W], word 0
    mov [ebx + COM_BASIC_H], word 11

@ut_symbol:

    xor eax, eax
    lodsb
    and al, al
    je @ut_stop

    ; Берем цвет шрифта
    mov  ecx, [ebx + COM_BASIC_DATA] 
    push edi ebx

    ; eax = 11*eax
    lea ebx, [eax*8 + eax]
    lea eax, [eax*2 + ebx]

    xchg eax, ecx ; eax = цвет шрифта
    mov  ebx, ecx ; ebx = указатель на букву    
    mov ch, 11    ; Высота шрифта 11

@ut_loopy:    

    push edx edi

    mov  cl, 6 ; Ширина 6
    mov  dl, [font6_11 + ebx]

@ut_loopx: ; x++

    test dl, 0x80
    je @ut_next_point

    mov [es:edi], eax

@ut_next_point:

    add edi, 4
    shl dl, 1
    dec cl
    jne @ut_loopx
    pop edi edx

    ; y++
    add edi, edx
    inc ebx

    dec ch
    jne @ut_loopy

    pop ebx edi
    add edi, 4*6 ; Смещение вправо на [4 байта на пиксель x 6 пикселей]
    add [ebx + COM_BASIC_W], word 6 ; Длина рассчитывается динамически

    ; Следующий символ
    jmp @ut_symbol

@ut_stop:
    ret    

