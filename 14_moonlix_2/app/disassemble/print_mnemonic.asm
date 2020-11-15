

; Напечатать мнемонику в зависимости от того, какая конфигурация
; -----------------------------------------------------------------
print_mnemonic:

    push  ax

    xor   cx, cx
    mov   dx, ax

    ; Записать опкод как он есть
    movzx eax, ax

    ; В случае расширенной мнемоники
    and ah, ah
    jne extended_mnemonic

    ; ---------------------
    call .write_prefixes    

    ; FPU-коды
    ; ----
    cmp al, 0xd8
    jc  @f
    cmp al, 0xe0
    jnc @f
    jmp fpu_mnemonics

@@:
    ; Мнемоника определяется mod/rm
    ; -------------------- (GRP1)
    cmp ax, 0x80
    je .modm_80
    cmp ax, 0x81
    je .modm_80
    cmp ax, 0x82
    je .modm_80
    cmp ax, 0x83
    je .modm_80
    ; -------------------- (GRP2)
    cmp ax, 0xc0
    je .modm_c0
    cmp ax, 0xc1
    je .modm_c0
    cmp ax, 0xd0
    je .modm_c0
    cmp ax, 0xd1
    je .modm_c0
    cmp ax, 0xd2
    je .modm_c0
    cmp ax, 0xd3
    je .modm_c0
    ; -----------------------
    cmp ax, 0xf6 ; GRP3
    je .grp3
    cmp ax, 0xf7 ; GRP3
    je .grp3
    cmp ax, 0xfe ; GRP4
    je .grp4
    cmp ax, 0xff ; GRP4
    je .grp4
    ; -----------------------
    cmp ax, 0x98
    je .cbw
    cmp ax, 0x99
    je .cwd
    ; --------------------

    mov   ax, [mnemonics_list + 2*eax]
    call  wstr_ext

    ; Есть 32-х разрядный регистр?
    cmp [dreg32], byte 0
    je .pad

    ; особые инструкции
    cmp  dx, 0xe3
    je .jecxz

    ; -- дополнить букву --
    cmp  dx, 0x60 ; pusha
    je .wrD
    cmp  dx, 0x61 ; popa
    je .wrD
    cmp  dx, 0x9c ; pushf
    je .wrD
    cmp  dx, 0x9d ; popf
    je .wrD
    cmp  dx, 0xcf ; iret
    je .wrD

    ; -- стереть букву (строковые функции) --
    cmp  dx, 0x6d ; insw/d
    je .wrDb
    cmp  dx, 0x6f ; outsw/d
    je .wrDb
    cmp  dx, 0xa5 ; movsw
    je .wrDb
    cmp  dx, 0xa7 ; cmpsw
    je .wrDb
    cmp  dx, 0xab ; stosw
    je .wrDb
    cmp  dx, 0xad ; lodsw
    je .wrDb
    cmp  dx, 0xaf ; scasw
    je .wrDb

    ; -- иначе без постфикса --
    jmp .pad

; Напечатать "jecxz" вместо "jcxz"
.jecxz:

    sub  edi, 4
    mov  al, 136 
    call wstr    ; "jecxz"
    jmp .pad 

.wrDb:
    dec edi
    dec ax

.wrD:

    ; дописать или переписать символ "d"
    WSYMB 'd'  
    inc ax   

; Расширить до 8 символов (ax - кол-во символов)
.pad:    

    WSYMB ' '  ; Пропечатать символ в любом случае

    ; PAD до 8 символов
    add   ax, cx ; cx - количество символов от префикса
    sub   ax, 8
    neg   ax

@@: dec  ax
    js @f    
    WSYMB ' ' 
    jmp @b

@@: pop ax
    ret

; -----------------
.cbw:    
    mov al, 88 ; CBW
    cmp [dreg32], byte 0
    je @f
    mov al, 89 ; CWDE
@@: call wstr
    pop ax
    ret

.cwd:    
    mov al, 90 ; CWD
    cmp [dreg32], byte 0
    je @f
    mov al, 91 ; CDQ
@@: call wstr
    pop ax
    ret

; -------------- если у опкода есть префиксы, писать их --------
.write_prefixes:

    push  ax

    ; LOCK
    cmp [dlock], byte 0
    je @f

        add cx, 5
        mov al, 139
        call wstr

    ; REP
@@: cmp [drep], byte 0
    je @f
    
        add cx, 4
        mov al, 140
        call wstr

    ; REPNZ
@@: cmp [drepnz], byte 0
    je @f
    
        add cx, 6
        mov al, 141
        call wstr

@@: pop ax
    ret

; ---------------------------- разбор групповой мнемоники --------------------------
.modm_req:

    movzx eax,  byte[fs:esi]
    and   al, 0x38
    shr   al, 3    
    movzx eax, al
    ret

.modm_80: ; grp 0x80 - 0x83

    call  .modm_req
    call  wstr_ext  ; add..cmp
    jmp .pad

.modm_c0: ; grp 0xc0 - 0xc1, 0xd0 .. 0xd3

    call  .modm_req  
    add   al, 112
    call  wstr_ext  ; rol..sar
    jmp .pad

.grp3: ; Группа 0xf6, 0xf7

    call  .modm_req    
    mov   al, [grps_mnemonic + eax]
    call  wstr
    jmp .pad

.grp4: ; Группа 0xfe, 0xff

    call  .modm_req
    mov   al, [grps_mnemonic + eax + 8]
    call  wstr
    jmp .pad

; Расширенные коды операции
; -------------------------------------------------------------------------------------

extended_mnemonic:

    ret


; Коды операции FPU
; -------------------------------------------------------------------------------------
fpu_mnemonics:

    ret    