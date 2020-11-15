; ---------------------------------------------
; Полностью перерисовать рабочий стол
; --
; DS должен быть обязательно CORE_DATA сегмент
; ---------------------------------------------

full_repaint:

    mov ax, SGN_VESA
    mov es, ax

    mov ax, SGN_COMEVT
    mov fs, ax

    xor esi, esi
    mov ecx, [ui_reg_top]
    shr ecx, 4

@fr_loop:

    ; Запись пуста - пропуск
    test [fs:esi + COMSH_FLAG], word COM_FLAG_AVAIL
    je @fr_next

    ; Получить ссылку на блок параметров этого компонента
    mov ebx, [fs:esi + COMSH_DATA]

    ; Получить идентификатор тип объекта в блоке параметров
    movzx edi, word [ds:ebx + COM_BASIC_ID]

    ; ---------------
    ; ПРОВЕРКИ ГРАНИЦ
    ; ---------------

    cmp edi, (1 + UI_ELEMENTS_COUNT)
    jnb @fr_next

    ; Получение ссылки на процедуру-обработчик
    mov edx, [4*edi + UICOM_references]
    and edx, edx
    je @fr_next   ; Процедуры не существует?

    ; Вызор процедуры
    push esi ecx
    call dword [4*edi + UICOM_references]
    pop  ecx esi

@fr_next:

    ; Обход списка закончен?
    dec ecx
    je @fr_end

    add esi, COMSH_SIZEOF
    jmp @fr_loop

@fr_end:
    ret