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
    mov dx, 0x00C0
    je @uim_opacity

    cmp al, 3
    mov dx, 0x00F0
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

    mov  ax, 0x0  ; Серый цвет
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

