; ----------------------------------------------------------------------
; ps2 mouse enable
; http://wiki.osdev.org/Mouse_Input#USB_Mouse

PS2Mouse.Init:

        ; Проставить IRQ
        call    PS2Mouse.IRQReloc
        
        ; Начать инициализацию
        mov     bl, 0xa8                ; Enable Auxiliary Device command (0xA8)
        call    kb_cmd                  ; This will generate an ACK response from the keyboard
        call    kb_read                 ; (which you must wait to receive) read status

        mov     bl, 0x20                ; get command byte (You need to send the command byte 0x20)
        call    kb_cmd
        call    kb_read

        or      al, 3                   ; enable interrupt
        mov     bl, 0x60                ; write command

        push    eax
        call    kb_cmd
        pop     eax
        call    kb_write

        mov     bl, 0xD4                ; for mouse
        call    kb_cmd

        mov     al,0xF4                 ; Enable Data Reporting
        call    kb_write
        call    kb_read                 ; Read Status Return
        
        ; 12*21/2 = 126 байт для курсора
        sub     [FreeBlock], 128
        mov     ax, [FreeBlock]
        mov     [PS2Mouse.CursorA], ax

        ret

; ----------------------------------------------------------------------

PS2Mouse.IRQReloc:

        mov     al, 11h
        out     20h, al
        jcxz    $+2
        jcxz    $+2

        out     0A0h, al
        jcxz    $+2
        jcxz    $+2

        ; Первый байт данных (смещения)
        ; ICW2: Slave PIC vector offset
        
        mov     al, 70h
        out     0A1h, al
        jcxz    $+2
        jcxz    $+2

        ; ICW2: Master PIC vector offset
        mov     al, 08h
        out     21h,  al
        jcxz    $+2
        jcxz    $+2

        ; ICW3: сообщить, что это slave, и его cascade identity (0000 0010)
        mov     al, 02
        out     0A1h, al
        jcxz    $+2
        jcxz    $+2

        ; ICW3: сообщить Master PIC, что есть slave PIC на IRQ2 (0000 0100)
        mov     al, 04
        out     21h, al 
        jcxz    $+2
        jcxz    $+2

        ; outb(PIC2_DATA, ICW4_8086): Окружение 8086/88 (MCS-80/85) режим
        mov     al, 01
        out     0A1h, al
        jcxz    $+2
        jcxz    $+2

        ; outb(PIC1_DATA, ICW4_8086): Окружение 8086/88 (MCS-80/85) режим
        out     21h,  al
        jcxz    $+2
        jcxz    $+2

        ; Разрешить бит 4 (12-е прерывание на Slave PIC)
        ; Timer+Keyboard+Cascade
        in      al, 0A1h
        and     al, 0xEF
        out     0A1h, al
        
        in      al, 021h
        and     al, 11111000b
        out     21h, al
        
        ; --------------------
        
        ; IRQ#0
        push    es
        mov     ax, 3508h
        int     21h
        mov     word [PS2Mouse.irq_0 + 0], bx
        mov     word [PS2Mouse.irq_0 + 2], es
        pop     es        
        mov     ax, 2508h
        mov     dx, PS2Mouse.IRQ0
        int     21h

        ; IRQ#1
        push    es
        mov     ax, 3509h
        int     21h
        mov     word [PS2Mouse.irq_1 + 0], bx
        mov     word [PS2Mouse.irq_1 + 2], es
        pop     es        
        mov     ax, 2509h
        mov     dx, PS2Mouse.IRQ1
        int     21h
        
        ; IRQ#2
        push    es
        mov     ax, 350Ah
        int     21h
        mov     word [PS2Mouse.irq_2 + 0], bx
        mov     word [PS2Mouse.irq_2 + 2], es
        pop     es        
        mov     ax, 250Ah
        mov     dx, PS2Mouse.IRQ2
        int     21h

        ; Установить прерывание 12h -> Int 74h
        mov     ax, 2574h
        mov     dx, PS2Mouse.IRQ
        int     21h
        ret


; ----------------------------------------------------------------------
; 1. Чтение ACK из 0x64 -> AL
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

; ----------------------------------------------------------------------
; 1. Ожидание готовности записи (бит 5, 0x20) из 0x64
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

kw_ok1: in      al,  0x60
        mov     ecx, 0xffff

kw_loop:

        in      al, 0x64
        test    al, 2
        jz      kw_ok
        loop    kw_loop

        mov     ah,1
        jmp     kw_exit

kw_ok:  mov     al,   dl
        out     0x60, al
        mov     ecx,  0xffff

kw_loop3:

        in      al, 0x64
        test    al, 2
        jz      kw_ok3

        loop    kw_loop3
        mov     ah,1
        jmp     kw_exit

kw_ok3: mov     ah, 8

kw_loop4:

        mov     ecx, 0xffff

kw_loop5:

        in      al, 0x64
        test    al, 1
        jnz     kw_ok4
        loop    kw_loop5

        dec     ah
        jnz     kw_loop4

kw_ok4: xor     ah,ah

kw_exit:

        pop     edx ecx
        ret

; ----------------------------------------------------------------------
; 1. Прием команды готовности с 0x64-го порта
; 2. Отсылка команды на 0x64-й порт
; 3. Ожидание готовности

kb_cmd:

        mov     ecx, 0xffff
c_wait: in      al, 0x64
        test    al, 2
        jz      c_send
        loop    c_wait
        jmp     c_error

c_send: mov     al,   bl
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
c_ok:   xor     ah, ah
c_exit: ret
