; ---
; 1. Чтение ACK из 0x64
; 2. Чтение символа из 0x60

kb_read:

    push    ecx  edx
    mov     ecx, 0xffff

kr_wait:

    in      al, 0x64
    test    al, 1
    jnz     kr_ready
    loop    kr_wait

    mov     ah, 1
    jmp     kr_exit

kr_ready:

    push    ecx
    mov     ecx, 32

kr_delay:

    loop    kr_delay
    pop     ecx
    in      al, 0x60
    xor     ah, ah

kr_exit:

    pop     edx ecx
    ret

; ---
; 1. Ожидание готовности записи (бит 5, 0x20) из 0x60
; 2. Чтение байта из 0x60
; 3. Ожидание готовности чтения (бит 2, 0x02) из 0x64
; 4. Запись в 0x60
; 5. Ожидание готовности (бит 2, 0x02) из 0x64, 0x0ffff чтений
; 6. Ожидание готовности (бит 1, 0x02) из 0x64, 0x8FFFF чтений

kb_write:

    push    ecx edx

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

    pop     edx ecx
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

; ---
; ps2 mouse enable
; http://wiki.osdev.org/Mouse_Input#USB_Mouse

init_ps2_mouse:
  
    mov     bl,0xa8                 ; Enable Auxiliary Device command (0xA8) 
    call    kb_cmd                  ; This will generate an ACK response from the keyboard
    call    kb_read                 ; (which you must wait to receive) read status

    mov     bl, 0x20                ; get command byte (You need to send the command byte 0x20)
    call    kb_cmd
    call    kb_read

    or      al, 3                    ; enable interrupt
    mov     bl, 0x60                 ; write command

    push    eax
    call    kb_cmd
    pop     eax
    call    kb_write

    mov     bl,0xD4                 ; for mouse
    call    kb_cmd

    mov     al,0xF4                 ; Enable Data Reporting
    call    kb_write
    call    kb_read                 ; read status return

    ; --- com1 mouse enable --- 
    mov   bx, 0x3f8 ; combase

    mov   dx, bx
    add   dx, 3
    mov   al, 0x80
    out   dx, al ; out (combase + 3), 0x80

    mov   dx, bx
    add   dx, 1
    mov   al, 0
    out   dx, al ; out (combase + 1), 0x00

    mov   dx, bx
    add   dx, 0
    mov   al, 0x30 * 2   
    out   dx, al ; out (combase + 0), 0x60

    mov   dx, bx
    add   dx, 3
    mov   al, 2        
    out   dx, al ; out (combase + 3), 0x02

    mov   dx, bx
    add   dx, 4
    mov   al, 0x0B
    out   dx, al ; out (combase + 4), 0x0B

    mov   dx, bx
    add   dx, 1
    mov   al, 1
    out   dx, al ; out (combase + 1), 0x01

    ; --- com2 mouse enable --- 
    mov   bx, 0x2f8 ; combase

    mov   dx, bx
    add   dx, 3
    mov   al, 0x80
    out   dx, al

    mov   dx, bx
    add   dx, 1
    mov   al, 0
    out   dx, al

    mov   dx, bx
    add   dx, 0
    mov   al, 0x30 * 2
    out   dx, al

    mov   dx, bx
    add   dx, 3
    mov   al, 2
    out   dx, al

    mov   dx, bx
    add   dx, 4
    mov   al, 0x0B
    out   dx, al

    mov   dx, bx
    add   dx, 1
    mov   al, 1
    out   dx, al

    ret

; -----------------------------------------------
; Обработка прерывания мыши
; ds:data
; http://wiki.osdev.org/Mouse_Input#PS2_Mouse_Subtypes
; -----------------------------------------------

IRQ_0C:

    ; Системные данные
    mov ax, ds
    mov gs, ax
    mov ax, SGN_DATA
    mov ds, ax

    pushad

    ; Послать команду на извлечение данных
    mov   bl,0xAD
    call  kb_cmd

    ; Читаем 3 байта (CMD, X shift, Y shift)
    mov   cx,  3
    xor   edi, edi

IRQ_0C_RdPacket: 

    push  cx
    call  kb_read  
    pop   cx

    or    ah, ah
    jnz   IRQ_0C_RdPacket

    cmp di, 0
    je @irqc_write_status ; edi = 0
    cmp di, 1
    je @irqc_diff_x ; edi = 1?
 
       movzx eax, al
       mul [ui_mouse_multiplier]

    ; Смещение мыши по Y (edi = 2)
    mov ah, [ui_mouse_keys]
    and ah, 20h ; sign Y бит
    shr ah, 5
    neg ah
    cwde
    sub [ui_mouse_y], eax
    jmp @irqc_next
   
; Смещение мыши по X (edi = 1)
@irqc_diff_x:

    movzx eax, al
    mul [ui_mouse_multiplier]
    
    ; ---
    mov ah, [ui_mouse_keys]
    and ah, 10h ; sign x бит
    shr ah, 4
    neg ah
    cwde
    add [ui_mouse_x], eax
    jmp @irqc_next

; Запись статуса кнопок
@irqc_write_status:

    mov [ui_mouse_keys], al

@irqc_next:

    inc   di
    loop  IRQ_0C_RdPacket

    ; Проверка на превышение границ
    mov  eax, dword [ui_mouse_x]
    test eax, 0x80000000
    je @ircq_ok1

    xor eax, eax
    mov dword [ui_mouse_x], eax

@ircq_ok1:

    cmp eax, [SCREEN_WIDTH]
    jb @ircq_ok2

    mov eax, [SCREEN_WIDTH]
    dec eax
    mov dword [ui_mouse_x], eax

@ircq_ok2:    

    mov eax, dword [ui_mouse_y]
    test eax, 0x80000000
    je @ircq_ok3

    xor eax, eax
    mov dword [ui_mouse_y], eax

@ircq_ok3:

    cmp eax, [SCREEN_HEIGHT]
    jb @ircq_ok4

    mov eax, [SCREEN_HEIGHT]
    dec eax
    mov dword [ui_mouse_y], eax

@ircq_ok4:    

    ; Отправить команду на включение прерываний от клавиатуры
    mov   bl, 0xAE
    call  kb_cmd

    ; Было смещение по X? 
    mov eax, [ui_mouse_xold]
    cmp [ui_mouse_x], eax
    jne @irqc_move

    ; Если не было смещения и по Y, мышь не двигалась
    mov eax, [ui_mouse_yold]
    cmp [ui_mouse_y], eax
    je  @irqc_no_move

; Мышь перемещалась?
@irqc_move:

    call ui_mouse_disable    
    call ui_mouse_enable

@irqc_no_move:

    ; Поиск событий по событиям мыши
    call events_mouse_detector
    
    ; Сохранение текущих значений координат мыши
    mov eax, [ui_mouse_x]
    mov [ui_mouse_xold], eax

    mov eax, [ui_mouse_y]
    mov [ui_mouse_yold], eax

    mov al, [ui_mouse_keys]
    mov [ui_mouse_keys_old], al

    ; EOI
    mov al,   0x20
    out 0xA0, al
    out 0x20, al

    ; Возврат предыдущего сегмента DS
    mov ax, gs
    mov ds, ax

    popad
    iret

; --------------------------------------------------------
; Обработка COM 2/4
; --------------------------------------------------------

IRQ_03:

    brk

    in al, 0x20
    out 0x20, al ; Отправить EOI
    iret    

; --------------------------------------------------------
; Обработка COM 1/3
; --------------------------------------------------------

IRQ_04:

    brk

    mov ah, 0x01

    in al, 0x20
    out 0x20, al ; Отправить EOI
    iret        
