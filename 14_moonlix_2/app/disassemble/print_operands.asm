
; ax - опкод, esi - данные, edi - буфер
; -----------------------------------------------------------------
print_operands:

    ; Есть modrm?
    cmp [has_mod_rm + eax], byte 0
    je  .norm
    call resolve_modrm

.norm:

    ; Получить тип вместо опкода 
    mov bl, byte [types_list + eax]

    ; Разбор типов
    cmp bl, 1
    je .modrm_r8

    cmp bl, 2
    je .modrm_r16 ; ext-32

    cmp bl, 3
    je .r8_modrm

    cmp bl, 4
    je .r16_modrm ; ext-32

    cmp bl, 5
    je .al_i8

    cmp bl, 6
    je .ax_i16 ; ext-32

    cmp bl, 7
    je .seg64

    cmp bl, 8    
    je .fin

    cmp bl, 9
    je .l3operand

    cmp bl, 10
    je .i8_ext_16

    cmp bl, 11
    je .i16_32

    cmp bl, 12
    je .r_rm_i16

    cmp bl, 13
    je .r_rm_i8e

    cmp bl, 14
    je .rel8

    cmp bl, 15
    je .rm8_i8

    cmp bl, 16
    je .rm16_i16

    cmp bl, 17
    je .rm16_i8_ext

    cmp bl, 18
    je .rm16_seg

    cmp bl, 19
    je .seg_rm16

    cmp bl, 20
    je .rm16_ptr

    cmp bl, 21
    je .l3xchg

    cmp bl, 22
    je .callf

    cmp bl, 23
    je .al_moffset

    cmp bl, 24
    je .ax_moffset

    cmp bl, 25
    je .moffset_al

    cmp bl, 26
    je .moffset_ax

    cmp bl, 27
    je .r3l_i8

    cmp bl, 28
    je .r3l_i16

    cmp bl, 29
    je .rm16_i8

    cmp bl, 30
    je .imm16

    cmp bl, 31
    je .imm16_8

    cmp bl, 32
    je .imm8

    cmp bl, 33
    je .r8_1

    cmp bl, 34
    je .r16_1

    cmp bl, 35
    je .r8_cl

    cmp bl, 36
    je .r16_cl

    cmp bl, 37
    je .rel16_32

    ; if (38 <= bl <= 45) .inout()
    cmp bl, 38
    jb .fin
    cmp bl, 45
    jbe .inout

    ; grp
    cmp bl, 46
    je .grp3_1

    cmp bl, 47
    je .grp3_2

    cmp bl, 48
    je .grp4_1

    cmp bl, 49
    je .grp4_2

.fin:
    ; неизвестный операнд
    ret

; -----------------------
.modrm_r8:
    
    mov  al, [f_modrm]
    call print_modm
    WSYMB ','

    mov  [regbit], byte 8
    mov  al, [f_reg]
    call print_reg
    ret

; -----------------------
.modrm_r16:
    
    call dreg2regbit
    mov  al, [f_modrm]
    call print_modm
    WSYMB ','
    mov  al, [f_reg]
    call print_reg    
    ret

; -----------------------
.r8_modrm: 
    
    mov  al, [f_reg]
    call print_reg
    WSYMB ','    
    mov  [regbit], byte 8
    mov  al, [f_modrm]
    call print_modm
    ret

; -----------------------
.r16_modrm:
    
    call dreg2regbit
    mov  al, [f_reg]
    call print_reg
    WSYMB ','    
    mov  al, [f_modrm]
    call print_modm
    ret

; -----------------------
.al_i8:

    mov word [fs:edi], 'al'
    inc edi
    inc edi
    WSYMB ','
    mov al, [fs:esi]
    inc esi      
    call wstr8    
    ret

; -----------------------
.ax_i16:

    call dreg2regbit
    mov  al, 0
    call print_reg
    WSYMB ','

    cmp [regbit], byte 16
    je .b16

    mov  eax, [fs:esi]
    add  esi, 4
    call wstr32
    ret

.b16:
    
    mov  ax, [fs:esi]
    inc  esi
    inc  esi
    call wstr16
    ret
    
; Печатать сегмент (& 0x38)
; ----------------------- 
.seg64:

    mov  [regbit], byte 4     
    and al, 0x38
    shr al, 3   
    call print_reg
    ret

; --- 8bit как 16 бит ---
.i8_ext_16:

    mov  al, [fs:esi]
    inc  esi
    cbw
    call wstr16
    ret

; --16/32 immediate ---
.i16_32:

    cmp [dreg32], byte 0x00
    je @f

    mov eax, [fs:esi]
    add esi, 4
    call wstr32
    ret

@@: mov ax, [fs:esi]
    inc esi
    inc esi
    call wstr16
    ret

; -- 8 -> 16/32 immediate ---
.i8_16_32:

    mov al, [fs:esi]
    inc esi
    cbw
    cmp [dreg32], byte 0x00
    je @f
    cwde
    call wstr32
    ret
@@: call wstr16
    ret

; --------------
.l3operand:

    call dreg2regbit
    and  al, 0x7
    call print_reg
    ret

.l3xchg: ; eax, <reg16/32>
    
    call dreg2regbit
    call wstr_eax
    WSYMB ','
    and  al, 0x7
    call print_reg
    ret

; --------------
.r_rm_i16:

    call .r16_modrm
    WSYMB ','
    call .i16_32
    ret

; --------------
.r_rm_i8e:

    call .r16_modrm
    WSYMB ','

    mov al, [fs:esi]
    cbw

    cmp [dreg32], byte 0x00
    je @f
    cwde
    call wstr32
    ret
@@: call wstr16
    ret

; --------------
.rm8_i8:

    mov  [regbit], byte 8
    mov  al, [f_modrm]
    call print_modm
    WSYMB ','
    mov  al, [fs:esi]
    inc  esi   
    call wstr8
    ret

; --------------
.rm16_i16:

    call .print_rm16_32
    WSYMB ','
    call .i16_32
    ret

; --------------
.rm16_i8:

    call .print_rm16_32
    WSYMB ','
    mov  al, [fs:esi]
    inc  esi   
    call wstr8
    ret
; --------------
.rm16_i8_ext:

    call .print_rm16_32
    WSYMB ','
    call .i8_16_32
    ret

; --------------
.rel8:
    mov al, [fs:esi]
    inc esi
    cbw
    cwde
    add eax, esi
    call wstr32
    ret

; ------------ [bx+f00b], ds ---- (foobar)
.rm16_seg:

    call .print_rm16_32 ; r/m16/32
    WSYMB ','
    mov al, [f_reg]
    mov [regbit], 4
    call print_reg      ; segment
    ret

; ------------ es, [bx+si] -----
.seg_rm16:

    mov al, [f_reg]
    mov [regbit], 4
    call print_reg ; segment
    WSYMB ','
    call .print_rm16_32 ; r/m16/32
    ret

; ---------- word/dword ptr -------
.rm16_ptr:

    mov al, 96 ; "word"
    cmp [dreg32], byte 0
    je @f
    mov al, 97 ; "dword"
@@: call wstr
    call .print_rm16_32
    ret

; ----------- seg16:off16/32 ---------
.callf:
    
    cmp [dreg32], byte 0
    je @f 

    ; 32 битный операнд
    mov  ax, [fs:esi + 4]
    call wstr16
    WSYMB ':'
    mov  eax, [fs:esi]
    call wstr32
    add  esi, 6
    ret

    ; 16 битный операнд?
@@: mov  ax, [fs:esi + 2]
    call wstr16
    WSYMB ':'
    mov  ax, [fs:esi]
    call wstr16
    add  esi, 4
    ret  

; Пропечатать r/m/16/32
; ----------------------------------------
.print_rm16_32:

    call dreg2regbit
    mov  al, [f_modrm]
    call print_modm
    ret    

; ------------------------------------------
   
.al_moffset: ; al, [moffset]

    mov  al, 8
    call wstr
    WSYMB ','
    call print_moffset
    ret

.ax_moffset:

    call wstr_eax
    WSYMB ','
    call print_moffset
    ret

.moffset_al:

    call print_moffset
    WSYMB ','
    mov  al, 8
    call wstr
    ret

.moffset_ax:

    call print_moffset
    WSYMB ','
    call wstr_eax
    ret

; ------------------------------------------

.imm8:

    mov  al, [fs:esi]
    inc  esi
    call wstr8
    ret

.imm16:

    mov  ax, [fs:esi]
    inc  esi
    inc  esi
    call wstr16
    ret

; ------------
.imm16_8:

    mov  ax, [fs:esi]    
    call wstr16
    WSYMB ','
    mov  al, [fs:esi+2]
    call wstr8
    inc  esi
    inc  esi
    inc  esi
    ret

; ------------------------------------------
.r3l_i8:    

    and al, 7
    mov [regbit], byte 8
    call print_reg
    WSYMB ','
    mov al, [fs:esi]
    inc esi      
    call wstr8    
    ret

.r3l_i16:

    and al, 7
    call dreg2regbit
    call print_reg
    WSYMB ','

    cmp [dreg32], byte 0
    je @f

    ; 32bit
    mov eax, [fs:esi]
    add esi, 4
    call wstr32   
    ret

    ; 16bit
@@: mov ax, [fs:esi]
    inc esi
    inc esi
    call wstr16
    ret

; ---- (групповые/битовые смещения) ---
.r8_1:

    mov  [regbit], byte 8
    mov  al, [f_modrm]
    call print_modm
    WSYMB ','
    WSYMB '1'
    ret

.r16_1:

    call .print_rm16_32
    WSYMB ','
    WSYMB '1'
    ret    

.r8_cl:

    mov  [regbit], byte 8
    mov  al, [f_modrm]
    call print_modm
    WSYMB ','
    WSYMW 'cl'
    ret

.r16_cl:

    call .print_rm16_32
    WSYMB ','
    WSYMW 'cl'
    ret        

; --- relative 16/32 ----
.rel16_32:

    cmp [dreg32], 0
    je @f ; 16 bit

    mov eax, [fs:esi]
    add esi, 4
    jmp .add

@@: mov ax, [fs:esi]
    cwde
    inc esi
    inc esi
    
.add:
    add eax, esi
    call wstr32
    ret

; Печать in/out
; -------------------------------------------------------------------
.inout:

    cmp bl, 39
    je .ax_i8 

    cmp bl, 40
    je .al_dx

    cmp bl, 41
    je .ax_dx

    cmp bl, 42
    je .i8_al

    cmp bl, 43
    je .i8_ax

    cmp bl, 44
    je .dx_al

    cmp bl, 45
    je .dx_ax
    ret

.ax_i8: ; Печатать AX/EAX

    call print_ax
    WSYMB ','
    call .imm8
    ret

.al_dx: 

    mov  al, 142 ; al,dx
    call wstr
    ret    

.ax_dx:

    call print_ax
    WSYMB ','
    mov  al, 18 ; "dx"
    call wstr
    ret    

.i8_al:

    call .imm8
    WSYMB ','
    mov  al, 8
    call wstr      
    ret    

.i8_ax:

    call .imm8
    WSYMB ','
    call print_ax
    ret    

.dx_al:

    mov  al, 159
    call wstr
    ret    

.dx_ax:

    mov  al, 18 ; "dx"
    call wstr
    WSYMB ','
    call print_ax
    ret        

; ------------------------- Группировочные операнды -----------------
.grp_reg: ; Номер регистра

    mov ah, al
    mov al, [f_modrm]
    and al, 0x38
    shr al, 3 
    ret

; ---
.grp3_1:    

    call .grp_reg
    cmp al, 2
    jb .rm8_i8

    ; rm/8
    mov  [regbit], byte 8
    mov  al, [f_modrm]
    call ptr_write 
    call print_modm

    ret

.grp3_2:

    call .grp_reg
    cmp al, 2
    jb .rm16_i16

    ; r/m/16/32
    call dreg2regbit
    mov  al, [f_modrm]
    call ptr_write 
    call print_modm
    ret

; ---
.grp4_1:    

    call .grp_reg    
    cmp al, 2
    jnb .write_inv ; если >=2, операнд не считается правильным

    mov  [regbit], byte 8
    mov  al, [f_modrm]
    call ptr_write 
    call print_modm
    ret

.grp4_2:    

    call .grp_reg
    cmp al, 2
    jb .grp4_2_id
    cmp al, 7
    je .write_inv

    test al, 1
    je .grp4_2_id
    jmp .callf

; inc/dec 16/32
.grp4_2_id:

    call dreg2regbit
    mov  al, [f_modrm]
    call ptr_write
    call print_modm
    ret

; неправильный операнд
.write_inv:

    mov al, 160
    call wstr
    ret