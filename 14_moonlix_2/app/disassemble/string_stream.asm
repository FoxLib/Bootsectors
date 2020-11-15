
; Debugger String Write. Записать строку из [data_str_list] AL = 0..ff в edi (потоком)
; eax - количество символов
; edi - последний символ в потоке
; -----------------------------------------------------------------------------
; ax = 0..65535
wstr_ext:

    push  esi
    movzx eax, ax
    jmp   wstr.get

; al от 0 до 255
wstr:

    push esi
    movzx eax, al

.get:    
    mov   esi, [fs:0x123000 + 4*eax] ; esi указывает на строку

.loop:
    lodsb
    and al, al
    je .fin

    mov [fs:edi], al
    inc edi
    inc ah
    jmp .loop

.fin:
    movzx eax, ah
    pop   esi
    ret

; al/ax/eax, edi - куда записать
; Процедура, записывающая шестнадцатеричное представление числа 8, 16, 32 бит
; -----------------------------------------------------------------------------

wstr8:

    push ax

    mov ah, al

    ; Первый полубайт
    and ah, 0xf0
    shr ah, 4
    cmp ah, 10
    jc @f
    add ah, 7
@@: add ah, '0'
    mov [fs:edi], ah
    inc edi

    ; Второй полубайт
    and al, 0xf
    cmp al, 10
    jc @f
    add al, 7
@@: add al, '0'
    mov [fs:edi], al
    inc edi

    pop ax
    ret

; 16 бит
wstr16:

    xchg al, ah
    call wstr8

    xchg al, ah
    call wstr8
    ret

; 32 бит
wstr32:

    ror  eax, 16
    call wstr16

    rol  eax, 16
    call wstr16
    ret

; Записать 8/16/32 (signed)  в поток (al/ax/eax)
; -----------------------------------------------------------------------------
wsigned8:

    mov  ah, '+'
    test al, 0x80    
    je @f
    mov  ah, '-'
    neg  al

@@: mov [fs:edi], ah
    inc edi
    and al, 0x7f
    call wstr8
    ret

; signed word
wsigned16:

    mov [fs:edi], byte '+'
    test ax, 0x8000
    je @f
    mov [fs:edi], byte '-'
    neg ax
@@: inc edi
    and ax, 0x7fff
    call wstr16
    ret

; печать ax/eax в зависимости от [dreg32]
; -----------------------------------------------------------------------------
wstr_eax:

    push ax
    mov al, 16 ; ax
    cmp [dreg32], 0
    je @f
    mov al, 24 ; eax
@@: call wstr
    pop ax
    ret    