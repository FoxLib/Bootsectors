; МЫШЬ PS/2

ps2_mouse:

    mov     bl,0xa8                 ; Enable Auxiliary Device command (0xA8) 
    call    kb_cmd                  ; This will generate an ACK response from the keyboard
    call    kb_read                 ; (which you must wait to receive) read status

    mov     bl, 0x20                ; get command byte (You need to send the command byte 0x20)
    call    kb_cmd
    call    kb_read

    or      al, 3                    ; enable interrupt
    mov     bl, 0x60                 ; write command

    push    rax
    call    kb_cmd
    pop     rax
    call    kb_write

    mov     bl,0xd4                 ; for mouse
    call    kb_cmd

    mov     al,0xf4                 ; Enable Data Reporting
    call    kb_write
    call    kb_read                 ; read status return

    ; --- выделить память

    mov  rax, 32*32*4 ; размер иконки
    call memalloc
    mov  [ps2_bk], rdi

    ret

; --- Получение данных (es:rdi) ---
ps2_get_data:

    ; Послать команду на извлечение данных
    mov  bl, 0xAD
    call kb_cmd    

    ; Читаем 3 байта (cmd, X смещение, Y смешение)    
    mov  cx, 3 
@@: call kb_read  
    or   ah, ah
    jnz  @b
    stosb ; записать прочтенный байт
    loop @b

    ret

; -----------------------------------------------------------------------------------------------------------
; Код скопирован из MenuetOS
; -----------------------------------------------------------------------------------------------------------
; 1. Чтение ACK из 0x64
; 2. Чтение символа из 0x60

kb_read:

    push    rcx  rdx
    mov     ecx, 0xffff

kr_wait:

    in      al, 0x64
    test    al, 1
    jnz     kr_ready
    loop    kr_wait

    mov     ah, 1
    jmp     kr_exit

kr_ready:

    push    rcx
    mov     ecx, 32

kr_delay:

    loop    kr_delay
    pop     rcx
    in      al, 0x60
    xor     ah, ah

kr_exit:

    pop     rdx rcx
    ret

; ---
; 1. Ожидание готовности записи (бит 5, 0x20) из 0x60
; 2. Чтение байта из 0x60
; 3. Ожидание готовности чтения (бит 2, 0x02) из 0x64
; 4. Запись в 0x60
; 5. Ожидание готовности (бит 2, 0x02) из 0x64, 0x0ffff чтений
; 6. Ожидание готовности (бит 1, 0x02) из 0x64, 0x8FFFF чтений

kb_write:

    push    rcx rdx

    mov     dl, al
    mov     ecx, 0xffff

kw_loop1:    

    in      al, 0x64
    test    al, 0x20
    jz      kw_ok1
    loop    kw_loop1

    mov     ah,1
    jmp     kw_exit

kw_ok1:

    in      al,  0x60
    mov     ecx, 0xffff

kw_loop:

    in      al, 0x64
    test    al, 2
    jz      kw_ok
    loop    kw_loop

    mov     ah,1
    jmp     kw_exit

kw_ok:

    mov     al,   dl
    out     0x60, al
    mov     ecx,  0xffff

kw_loop3:

    in      al, 0x64
    test    al, 2
    jz      kw_ok3

    loop    kw_loop3
    mov     ah,1
    jmp     kw_exit

kw_ok3:

    mov     ah, 8

kw_loop4:

    mov     ecx, 0xffff

kw_loop5:

    in      al, 0x64
    test    al, 1
    jnz     kw_ok4
    loop    kw_loop5

    dec     ah
    jnz     kw_loop4

kw_ok4:

    xor     ah,ah

kw_exit:

    pop     rdx rcx
    ret

; ---
; 1. Прием команды готовности с 0x64-го порта
; 2. Отсылка команды на 0x64-й порт
; 3. Ожидание готовности

kb_cmd:

    mov     ecx, 0xffff

c_wait:

    in      al, 0x64
    test    al, 2
    jz      c_send
    loop    c_wait
    jmp     c_error

c_send:

    mov     al,   bl
    out     0x64, al
    mov     ecx,  0xffff

c_accept:

    in      al, 0x64
    test    al, 2
    jz      c_ok
    loop    c_accept

c_error:

    mov     ah, 1
    jmp     c_exit

c_ok:

    xor     ah, ah

c_exit:

    ret