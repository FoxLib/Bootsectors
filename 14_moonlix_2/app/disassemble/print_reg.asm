
; ---------------------------------------------------------
; al = 0..7 (регистр)
; ---------------------------------------------------------

print_reg:

    ; Регистры общего назначения
    cmp [regbit], byte 8
    je  .b8

    cmp [regbit], byte 16
    je .b16

    cmp [regbit], byte 32
    je .b32

    ; Специальные регистры
    cmp [regbit], byte 1
    je .mmx

    cmp [regbit], byte 2
    je .st

    cmp [regbit], byte 3
    je .xmm

    cmp [regbit], byte 4
    je .seg

    cmp [regbit], byte 5
    je .cr

    cmp [regbit], byte 6
    je .dr
    
    ; по умолчанию, 8 бит
.b8:
    add al, 8
    jmp .w

.b16:
    add al, 16
    jmp .w    

.b32:
    add al, 24
    jmp .w

; Сегменты
.seg:
    add al, 32
    jmp .w

; Модицификации 
.mmx:
    mov word [fs:edi], 'mm'
    jmp .dw

.xmm:
    mov dword [fs:edi], 'xmm '
    inc edi
    jmp .dw

.st:
    mov word [fs:edi], 'st'
    jmp .dw

.cr:
    mov word [fs:edi], 'cr'
    jmp .dw

.dr:
    mov word [fs:edi], 'cr'

; Записать цифру от 0 до 7 
.dw:    
    inc edi
    inc edi
    add al, '0'
    mov [fs:edi], al
    inc edi
    ret

.w: ; Записать имя регистра
    call wstr
    ret

; --- Либо ax, либо eax ---
print_ax:

    push ax
    mov  al, 0
    call dreg2regbit
    call print_reg
    pop  ax
    ret