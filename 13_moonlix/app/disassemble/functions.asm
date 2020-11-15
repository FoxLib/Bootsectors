
; Простановка ссылок на константы
; -----------------------------------------------------------------------------
debugger_init:

    push ebp
    mov  esi, data_str_list ; Указатель на строки
    mov  edi, 0x123000      ; Указатель на метки строк

.ld:
    mov [fs:edi], esi

    lodsb
    and al, al
    je .fin

    ; Читать строку, пока не 0
.str:
    lodsb
    and al, al
    jne .str

    ; К следующему элементу
    add edi, 4    
    jmp .ld

.fin:
    pop  ebp
    ret


; Решить ModRM
; -----------------------------------------------------------------
resolve_modrm:

    mov bl, [fs:esi]
    inc esi

    mov [f_modrm], bl
    mov [f_rm] , bl
    mov [f_reg], bl
    mov [f_mod], bl

    and [f_rm],  byte 0x07
    and [f_reg], byte 0x38
    and [f_mod], byte 0xc0

    shr byte [f_reg], 3
    ret


; Преобразовать 16 в 32 бита, если это требуется
; -----------------------------------------------------------------
dreg2regbit:    

    mov  [regbit], byte 16
    mov  [rbase],  byte 16 ; id=16 (ax,cx...)
    cmp  [dreg32], byte 0
    je @f
    mov  [regbit], byte 32 ; если есть расширение адреса до 32 бит
    mov  [rbase],  byte 24 ; id=24 (eax,ecx..)
@@: ret

; В зависимости от того, какой regbit, записывается ptr
; -----------------------------------------------------------------
ptr_write:

    push ax

    mov al, 161 ; "byte"
    cmp [regbit], 8
    je .fin

    mov al, 96 ; "word"
    cmp [regbit], 16
    je .fin

    mov al, 97 ; "dword "
    cmp [regbit], 32
    je .fin

.fin:
    call wstr
    pop ax    
    ret        