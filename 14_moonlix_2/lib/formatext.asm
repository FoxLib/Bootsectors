; Вывод десятичного числа из EAX в ES:EDI 
; ---------------------------------------------------------
WRITE_decimal:

    create_frame 4 ; 16 символов

    pusha

    ; Если мы получили 0, то пропечатать его
    and eax, eax
    je .zero    

    xor esi, esi
    mov ebx, 10
    mov ecx, ebx

    ; Выстраивание обратной цепочки делений на 10
@@: xor edx, edx
    div ebx    
    add dl, '0'
    mov [ebp + esi], dl
    dec esi
    loop @b

    ; Пропустить лидируюшие нули
    inc esi
@@: cmp [ebp + esi], byte '0'
    jne .symbols
    inc esi
    jmp @b

.symbols:

    mov al, [ebp + esi]
    stosb
    inc esi
    cmp si, 1
    jne .symbols

    jmp .exit

.zero: ; пропечатать 0
    mov al, '0'
    stosb

.exit: ; z-terminated строка

    mov al, 0
    stosb

    popa
    leave
    ret    

; Вывод Z-строки в терминал ES:ESI в ES:EDI, AH - атрибут
; -----------------------------------------------------
CPRINT_string:    

    pusha
@@: mov al, [es:esi]
    and al, al
    je .exit
    stosw
    inc esi
    jmp @b
    
.exit:
    pop  esi
    push edi
    popa
    ret

; Вывод Z-строки DS:ESI в ES:EDI, AH - атрибут
; -----------------------------------------------------
SPRINTF_string:

    pusha
@@: lodsb
    and al, al
    je @f
    stosw
    jmp @b
@@: pop esi
    push edi
    popa
    ret    
