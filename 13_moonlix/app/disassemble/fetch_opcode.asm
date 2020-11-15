
; Сканирование опкода (fs:esi)
; ex - номер опкода (0..1ff)
; -----------------------------------------------------------------------------
fetch_opcode:

    ; ИНИЦИАЛИЗАЦИЯ
    mov  [regbit], byte 0
    mov  [dlock],  byte 0
    mov  [drep],   byte 0
    mov  [drepnz], byte 0
    mov  [dsfx],   byte 0

.reploop:
    
    ; FETCH
    movzx ax, byte [fs:esi] ; al
    inc esi

    cmp al, 0x0f
    je  .set_0f

    cmp al, 0x66
    je .set_reg32

    cmp al, 0x67
    je .set_mem32

    cmp al, 0xf0
    je .set_lock

    cmp al, 0xf2
    je .set_repnz

    cmp al, 0xf3
    je .set_rep

    cmp al, 0x26
    je .seg_es
    
    cmp al, 0x2e
    je .seg_cs
    
    cmp al, 0x36
    je .seg_ss

    cmp al, 0x3e
    je .seg_ds

    ; Сегменты
    cmp al, 0x64
    je .seg_fs

    cmp al, 0x65
    je .seg_gs

    ; Код разобран успешно
    movzx eax, ax
    ret

.set_0f:
    mov ah, 0x01 ; дополнительные опкоды
    jmp .reploop

.set_reg32:
    xor [dreg32], byte 0xff ; reg16/32 (смотря что было проинициализировано по умолчанию)
    jmp .reploop

.set_mem32:    
    xor [dmem32], byte 0xff ; mem16/32 
    jmp .reploop

.set_lock:
    mov [dlock], byte 0xff
    jmp .reploop

.set_repnz:
    mov [drepnz], byte 0xff
    jmp .reploop

.set_rep:
    mov [drep], byte 0xff
    jmp .reploop

.seg_es:
    mov [dsfx], byte 0x01
    jmp .reploop

.seg_cs:
    mov [dsfx], byte 0x02
    jmp .reploop

.seg_ss:
    mov [dsfx], byte 0x03
    jmp .reploop

.seg_ds:
    mov [dsfx], byte 0x04
    jmp .reploop

.seg_fs:
    mov [dsfx], byte 0x05
    jmp .reploop

.seg_gs:
    mov [dsfx], byte 0x06
    jmp .reploop
