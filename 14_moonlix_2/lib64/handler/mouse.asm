include 'ico/pointer.asm'

; Указетель на память (статичная), для сохранения курсора мыши
memarea_mcursor_bk dq 0

ps2_x    dq 0 ; x
ps2_y    dq 0 ; y
ps2_s    db 0 ; state -- статус кнопок
ps2_a    db 0 ; accessed=0/1 Если стоит 1, значит было прерывания от мыши
ps2_bk   dq 0 ; адрес буфера для сохранения фона мыши
ps2_show db 0 ; 0=не показана, 1=показана мышь

; ---
ps2_info dd 0 ; Системные данные

; -----
mouse:

    saveall

    mov rdi, ps2_info 
    call ps2_get_data  ; [lib64/ps2.asm]

    ; Скрыть мышь, чтобы переместиться в другую точку экрана
    call mouse_hide

    ; Вычислить смещение +offset_x
    ; ---
    xor  rdx, rdx
    xor  rax, rax
    mov  al, byte [ps2_info + 1]
    test byte [ps2_info], byte 0x10 ; overflow_x?
    je @f
    or  eax, 0xffffff00
    cdqe
@@: add [ps2_x], rax
    jns @f
    mov [ps2_x], rdx


    ; Вычислить смещение +offset_y
    ; ---
@@: xor  rax, rax
    mov  al, byte [ps2_info + 2]
    test byte [ps2_info], byte 0x20 ; overflow_y?
    je @f
    or  eax, 0xffffff00
    cdqe
@@: sub [ps2_y], rax
    jns @f
    mov [ps2_y], rdx

    ; Установить состояние кнопок
    ; ---
@@: mov al, byte [ps2_info]
    mov [ps2_s], al

    ; ---
    mov rax, [vesa_w]
    dec rax
    cmp [ps2_x], rax
    jb  @f
    mov [ps2_x], rax

    ; ---
@@: mov rax, [vesa_h]
    dec rax
    cmp [ps2_y], rax
    jb  @f
    mov [ps2_y], rax

@@: ; ---
    mov al, 0x20
    out 0xA0, al
    out 0x20, al

    ; Еслим мышь двинулась, то установить ps_a = 0xff
    mov [ps2_a], byte 0xFF

    ; Показать мышь
    call mouse_show

    loadall
    iretq

; Скрыть мышь (восстановить фон)
; ------------------------
mouse_hide:
    
    ; если мышь не показана, незачем скрывать ее снова
    cmp [ps2_show], 0 
    je @f
    
    mov [ps2_show], 0
    vc5 copy_from_block,[ps2_x],[ps2_y],16,18,[ps2_bk]

@@: ret

; Показать мышь
mouse_show:
   
    cmp [ps2_show], 1 ; мышь показана
    je @f
    
    mov [ps2_show], 1
    vc5 copy_to_block,[ps2_x],[ps2_y],16,18,[ps2_bk]  ; Скопировать область экрана в ps2_bk
    vc3 canvas_ico,[ps2_x],[ps2_y],mptr_ordinary      ; Показать мышь "mptr_ordinary" (обычный тип)

@@: ret    