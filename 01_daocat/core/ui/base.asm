; Полное обновление всех элементов из выбранного списка [ui_events_stack] 
ui_redraw:

    ; tss тут уже не важен

    mov ax,  [ui_events_stack] 
    mov fs,  ax

    mov ecx, [ui_registered_top]
    shr ecx, 5
    xor esi, esi

@ui_loop:

    ; В случае, если элемент неактивен в списке
    test [fs:esi + EVENT_FLAGS], word EVT_AVAILABLE
    je @uir_skip

    ; Не обрабатывать событие как элемент UI
    test [fs:esi + EVENT_FLAGS], word EVT_IS_EVENT
    jne @uir_skip

    ; Тестируем, что будет нарисовано
    mov ax, [fs:esi + EVENT_UI_ID]

        cmp ax, UI_DESKTOP
        je ui_fill_desktop
        cmp ax, UI_TASKBAR
        je ui_hipanel
        cmp ax, UI_TEXT
        je ui_text_mono
        cmp ax, UI_ICON4
        je ui_icon4

@uir_skip:

    ; К следующему элементу
    add  esi, 32

    ; ...пока не закончится список
    loop @ui_loop
    ret

; Залить одним цветом весь экран
; EAX - Цвет BGR
; ---------------------
ui_fill_desktop:

    push esi ecx

    ; Разметка максимального размера монитора
    push dword 0    ; x1
    push dword 0    ; y1

    mov  ecx, [SCREEN_WIDTH]
    dec  ecx
    push dword ecx ; y2

    mov  ecx, [SCREEN_HEIGHT]
    dec  ecx    
    push dword ecx  ; y1

    push dword [ui_desktop_color]  ; color
    call VESA_rectangle
    add  esp, 0x14

    pop ecx esi
    jmp @uir_skip

; Начертание нижней панели задач
; EAX - Цвет BGR
; ---------------------

ui_hipanel:

    push esi ecx

    push dword Gradient_For_Task_Panel
    push dword 30 ; height
    push dword 0  ; x

    mov eax, [SCREEN_HEIGHT] 
    sub eax, 30
    push eax ; y

    mov eax, [SCREEN_WIDTH]
    dec eax 
    push eax ; width

    call ui_gradient
    add  esp, 0x14

    pop ecx esi
    jmp @uir_skip

; Рисовать моноширинный текст
; --------------------------
ui_text_mono:

    push esi ecx

    movzx eax, word [fs:esi + EVENT_X]
    movzx ebx, word [fs:esi + EVENT_Y]

    push dword eax
    push dword ebx

    push dword [fs:esi + EVENT_DATA]

    ; ds:textptr
    mov  ax, ds
    mov  gs, ax
    mov  ax, [fs:esi + EVENT_CALLBACK + 4]
    mov  ds, ax
    push dword [fs:esi + EVENT_CALLBACK] 
    call VESA_out_text
    add  esp, 0x10

    mov  ax, gs
    mov  ds, ax

    pop ecx esi
    jmp @uir_skip


; Рисовать иконку 16x16, 4 цвета
; ---------------------
ui_icon4:

    movzx eax, word [fs:esi + EVENT_Y]
    mov ecx, [SCREEN_WIDTH]
    mul ecx
    movzx ebx, word [fs:esi + EVENT_X]
    add eax, ebx
    lea edi, [4*eax] ; edi = 4*(x + W*y)
    lea edx, [4*ecx] ; edx = 4*W

    mov ax, [fs:esi + EVENT_CALLBACK_SGN]
    mov gs, ax
    mov esi, [fs:esi + EVENT_CALLBACK]

    mov cl, 16

@ui_icon4_loopy:

    mov ch, 4 
    push cx edi edx

@ui_icon4_loopx:

    mov cl, 4 
    mov ah, [gs:esi]

@ui_icon4_loop4x:

    rol ah, 2
    mov al, ah
    and al, 0x03    
    je  @ui_icon4_next

    mov dl, 0xA0
    cmp al, 0x01
    je @ui_icon4_put

    mov dl, 0x80
    cmp al, 0x02
    je @ui_icon4_put

    mov dl, 0xFF

@ui_icon4_put:

    mov al, dl
    stosb
    stosb
    stosb
    stosb
    jmp @ui_icon4_after    

@ui_icon4_next:

    add edi, 4

@ui_icon4_after:

    dec cl
    jne @ui_icon4_loop4x

    inc esi
    dec ch
    jne @ui_icon4_loopx

    pop edx edi cx

    add edi, edx
    dec cl
    jne @ui_icon4_loopy

    ret

; "Выбранная" и не выбранная задача
; ---------------------
ui_task_panel:

    ret    

; Инициализация мыши
ui_init_mouse:

    mov eax, [SCREEN_WIDTH]
    shr eax, 1
    mov [ui_mouse_x],    eax
    mov [ui_mouse_xold], eax

    mov eax, [SCREEN_HEIGHT]
    shr eax, 1
    mov [ui_mouse_y],    eax
    mov [ui_mouse_yold], eax

    ret

; Отрисовка курсора мыши
; ds: data, es: vesa
; ----------------------------------------------------------------------------------------------
ui_mouse_enable:

    mov  eax, [ui_mouse_x]
    mov  ebx, [ui_mouse_y]
    call ui_calc_mouse_fragment

    ; Получение координат
    mov eax, [ui_mouse_y]
    mov ebx, [SCREEN_WIDTH]
    mul ebx
    add eax, [ui_mouse_x]
    lea edi, [eax*4]    ; edi = 4*(W*y + x)
    lea ebx, [ebx*4]    ; ebx = 4*W

    ; Сохранить область за мышью
    mov ax, SGN_KBD_DPL0
    mov fs, ax
    
    push edi
    mov esi, KBD_MOUSEUNDER
    mov ch, [ui_mouse_height]

@ui_me_loopy:

    mov cl, [ui_mouse_width]
    shl cl, 2 
    push edi

@ui_me_loopx:

    mov al, [es:edi]
    mov [fs:esi], al
    inc esi
    inc edi
    dec cl
    jne @ui_me_loopx

    pop edi
    add edi, ebx

    dec ch
    jne @ui_me_loopy

    pop edi

    ; Отрисовка мыши
    ; --------------

    mov ch,  [ui_mouse_height]

    ; Указатель на текущий курсор мыши
    mov esi, [ui_icon_mouse] 

@uim_loopy:

    mov cl, [ui_mouse_width]
    push esi
    push edi

@uim_loopx:

    lodsb

    cmp al, 5
    mov dx, 0x3D3D
    je @uim_put

    cmp al, 9
    mov dx, 0xFFFF
    je @uim_put

    cmp al, 4
    mov dx, 0x0090
    je @uim_opacity

    cmp al, 3
    mov dx, 0x00C0
    je @uim_opacity

    add edi, 4
    jmp @uim_next

; Обработка прозрачной точки
@uim_opacity:

    push cx
    mov  cl, 3

@uim_rgb:

    push cx
    push dx
    mov   cx, dx
    movzx ax, byte [es:edi]

    mul cx
    shr ax, 8

    push ax

    mov  ax, 0x40  ; Серый цвет
    neg  cx
    and  cx, 0x00FF
    mul  cx
    shr  ax, 8

    pop  cx
    add  ax, cx
    stosb

    pop dx
    pop cx

    dec cl
    jne @uim_rgb

    pop cx
    jmp @uim_next

@uim_put:

    movzx eax, dx
    stosw
    stosw

@uim_next:

    dec cl
    jne @uim_loopx

    pop edi
    pop esi
    add esi, 13
    add edi, ebx

    dec ch
    jne @uim_loopy

    ret    

; Восстанавливает предыдущую область
; ----------------------------------
ui_mouse_disable:

    mov  eax, [ui_mouse_xold]
    mov  ebx, [ui_mouse_yold]
    call ui_calc_mouse_fragment   

    ; Получение координат
    mov eax, [ui_mouse_yold]
    mov ebx, [SCREEN_WIDTH]
    mul ebx
    add eax, [ui_mouse_xold]
    lea edi, [eax*4]    ; edi = 4*(W*y + x)
    lea ebx, [ebx*4]    ; ebx = 4*W

    ; Сохранить область за мышью
    mov ax, SGN_KBD_DPL0
    mov fs, ax
    
    mov esi, KBD_MOUSEUNDER
    mov ch,  [ui_mouse_height]

@ui_md_loopy:

    mov cl, [ui_mouse_width]
    shl cl, 2
    push edi

@ui_md_loopx:

    mov al, [fs:esi]
    mov [es:edi], al
    inc esi
    inc edi
    dec cl
    jne @ui_md_loopx

    pop edi
    add edi, ebx

    dec ch
    jne @ui_md_loopy   
    ret    

; Расчет фрагмента области мыши
; Предназначено для того, чтобы курсор мыши не выходил за пределы экрана
; eax (x), ebx (y)
ui_calc_mouse_fragment:    
   
    mov cl,  13

    ; Ширина
    mov edx, [SCREEN_WIDTH]
    sub edx, 13
    cmp eax, edx
    jb @ui_cmf_1

    mov edx, [SCREEN_WIDTH]
    sub edx, eax
    mov cl,  dl

@ui_cmf_1:

    mov [ui_mouse_width], cl

    ; Высота
    mov cl, 20
    mov edx, [SCREEN_HEIGHT]
    sub edx, 20
    cmp ebx, edx
    jb @ui_cmf_2

    mov edx, [SCREEN_HEIGHT]
    sub edx, ebx
    mov cl,  dl

@ui_cmf_2:

    mov [ui_mouse_height], cl
    ret
