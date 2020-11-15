

; Печать из AL значения MOD (16 бит)
; -----------------------------------------------------------------------------
print_modm:

    push eax

    mov  ah, al
    and  ah, 0xc0
    and  al, 0x07

    ; switch (ah & 0xc0)
    cmp  ah, 0x00 ; Стандартный mod
    je   .mod0

    cmp  ah, 0x40
    je   .mod1

    cmp  ah, 0x80
    je   .mod2
    jmp  .mod3

; case 0x00
; -----------
.mod0:

    WSYMB '['
    call .segment_pre

    cmp   al, 6
    je  .mod0_disp16 ; если 6 - displacement

    ; если не 6, то записать из таблицы 16-бит
    add   al, 40    
    call  wstr
    jmp  .mod0_end

.mod0_disp16:

    mov  ax, [fs:esi]
    inc  esi
    inc  esi
    call wstr16

.mod0_end:

    WSYMB ']'
    jmp .swend ; break

; case 0x04 +/- disp8
; -----------
.mod1:

    ; печатать индексы
    WSYMB '['
    call .segment_pre

    add  al, 40
    call wstr

    ; Получить signed byte
    mov al, [fs:esi]
    inc esi

    ; Если 0 - пропуск выдачи
    and al, al
    je @f
    
    call wsigned8
@@:
    WSYMB ']'
    jmp .swend ; break

; case 0x08
; -----------
.mod2:    

    WSYMB '['
    call .segment_pre

    add  al, 40
    call wstr

    ; Получить signed word
    mov ax, [fs:esi]
    inc esi
    inc esi

    ; Если 0 - пропуск выдачи
    and ax, ax
    je @f    
    call wsigned16
    
@@: WSYMB ']'
    jmp .swend ; break

; case 0xc0 (регистр вместо mem-ref)
; -----------
.mod3:
    call print_reg

.swend: 
    pop  eax
    ret


; Печать суффикса, если он есть
.segment_pre:
   
    ; без суффикса?
    cmp [dsfx], byte 0
    je @f

    push ax
    mov  al, [dsfx]
    dec  al
    mov  [regbit], byte 4 ; print segment
    call print_reg
    WSYMB ':'
    pop ax

@@: ret


; Печать 16/32 бит
; -----------------------------------------------------------------------------
print_moffset:

    WSYMB '['

    cmp [dmem32], byte 0
    je  .m16

    mov eax, [fs:esi]
    add esi, 4
    call wstr32
    jmp .fin

.m16:    
    mov eax, [fs:esi]
    inc esi
    inc esi
    call wstr16

.fin:
    WSYMB ']'
    ret        

; 32-bit MOD/RM
; -----------------------------------------------------------------------------    