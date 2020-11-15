; ---------------------------------------------
; Первоначальная очистка очередей событий
; ---------------------------------------------

events_clear:

    ; Очистить список событий (раньше тут был RealMode IDT)
    mov ax, SGN_ESTACK
    mov es, ax
    mov cx, 65536 / 4
    xor eax, eax
    xor edi, edi
    rep stosd

    ; Очистить список компонентов (раньше была информация о VESA)
    mov ax, SGN_COMEVT
    mov es, ax
    mov cx, (2 * 65536) / 4
    xor eax, eax
    xor edi, edi
    rep stosd
    ret

; ---------------------------------------------
; Регистрация нового компонента в системе
; DS:ESI - описатель блока
; ---------------------------------------------

com_register:

    push eax esi

    mov ax, SGN_COMEVT
    mov fs, ax

    ; Начать поиск с первого свободного блока
    mov edi, [ui_reg_free]

@com_register_loop:

    cmp edi, 0x10000
    jnb @com_register_fault

    ; Если позиция списка освобождена, запись нового компонента сюда
    test [fs:edi + COMSH_FLAG], word COM_FLAG_AVAIL
    je @com_register_found_free

    add edi, COMSH_SIZEOF
    jmp @com_register_loop

    ; Свободный элемент найден
@com_register_found_free:

    push esi

    ; Пометить элемент как занятый
    or  [fs:edi + COMSH_FLAG], word COM_FLAG_AVAIL

    str ax
    mov [fs:edi + COMSH_TSS], ax

    ; Копировать word X, word Y
    lodsd
    mov [fs:edi + COMSH_X], eax

    ; Копировать word W, word H
    lodsd
    mov [fs:edi + COMSH_W], eax

    pop esi

    ; Запись указателя на структуру данных
    mov [fs:edi + COMSH_DATA], esi

    ; Поиск первого свободного блока будет начинаться со следующего элемента
    lea esi, [edi + COMSH_SIZEOF]
    mov [ui_reg_free], esi

    ; Установить верхнюю границу всех регистрированных элементов
    mov eax, [ui_reg_top]
    cmp esi, eax
    jb @cr_no_adjust

    mov [ui_reg_top], esi

@cr_no_adjust:

    pop esi eax

    clc
    ret

; Невозможно зарегистрировать новый компонент, нет больше места
; В версии OS 0.0 не предусмотрена ротация. Потенциальная уязвимость: переполнение очереди.
@com_register_fault:

    stc
    ret

; ---------------------------------------------
; Обнаружение событий по движению мыши
; ---------------------------------------------
events_mouse_detector:

    mov al, [ui_mouse_keys]
    mov ah, [ui_mouse_keys_old]
    and al, 0x07
    and ah, 0x07
    cmp ah, al
    je  @event_not_modified

    brk

@event_not_modified:

    ret