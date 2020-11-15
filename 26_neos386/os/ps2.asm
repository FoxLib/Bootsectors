
; ----------------------------------------------------------------------
; Инициализация
; ----------------------------------------------------------------------

ps2_init:

        mov     ah, $A8
        call    kb_cmd
        call    kb_read
        mov     ah, $20
        call    kb_cmd
        call    kb_read
        push    ax
        mov     ah, $60
        call    kb_cmd
        pop     ax
        or      al, 3
        call    kb_write
        mov     ah, $D4
        call    kb_cmd
        mov     al, $F4
        call    kb_write
        call    kb_read
        ret

; ----------------------------------------------------------------------
; Принять данные из порта
; ----------------------------------------------------------------------

ps2_irq:

        pusha

        mov     ah, $AD
        call    kb_cmd          ; Блокировка клавиатуры
        call    kb_read
        mov     [ps2.cmd], al
        call    kb_read
        mov     [ps2.dat_x], al
        call    kb_read
        mov     [ps2.dat_y], al
        mov     ah, $AE
        call    kb_cmd          ; Разблокировка клавиатуры
        test    [ps2.cmd], $10  ; Расширение знака
        je      @f
        or      [ps2.dat_x], $80
@@:     test    [ps2.cmd], $20
        je      .exit
        or      [ps2.dat_y], $80

.exit:  mov     al, $20
        out     $20, al
        out     $A0, al
        popa
        iretd

; Ожидание ответа с порта $64, параметр AH - маска
; Если AL=0, все в порядке, иначе ошибка
; ----------------------------------------------------------------------

kb_wait:

        mov     ecx, 65536
@@:     in      al, $64
        and     al, ah
        loopnz  @b
        ret

; Ожидание установки бита 1 в $64
; Если AL > 0, все в порядке, иначе ошибка
; ----------------------------------------------------------------------

kb_wait_not:

        mov     ecx, 8*65536
@@:     in      al, $64
        and     al, 1
        loopz   @b
        ret

; Отправить команду AH=comm
; ----------------------------------------------------------------------

kb_cmd: xchg    ah, bh
        mov     ah, 2
        call    kb_wait
        mov     al, bh
        out     $64, al
        mov     ah, 2
        call    kb_wait
        ret

; Запись команды AL
; ----------------------------------------------------------------------

kb_write:

        mov     bl, al
        mov     ah, 0x20
        call    kb_wait         ; Ожидание готовности
        in      al, $60         ; Чтение данных из порта (не имеет значения)
        mov     ah, $02
        call    kb_wait         ; Ждать для записи
        mov     al, bl
        out     $60, al         ; Записать данные
        mov     ah, $02
        call    kb_wait         ; Ждать для записи
        call    kb_wait_not     ; Подождать, пока будет =1 на чтение
        ret

; ----------------------------------------------------------------------
; Прочитать данные
; ----------------------------------------------------------------------

kb_read:

        call    kb_wait_not
        mov     ecx, 65536
@@:     loop    @b
        in      al, $60
        ret


; ----------------------------------------------------------------------
; com1/2 mouse enable
; https://wiki.osdev.org/Serial_Ports
; ----------------------------------------------------------------------

com_mouse_init:

        ; --------------------------
        ; com1 mouse enable
        ; --------------------------
        mov     bx, 0x3f8       ; combase

        mov     dx, bx
        add     dx, 3
        mov     al, 0x80
        out     dx, al

        mov     dx, bx
        add     dx, 1
        mov     al, 0
        out     dx, al

        mov     dx, bx
        add     dx, 0
        mov     al, 0x30*2    ; 0x30 / 4
        out     dx, al

        mov     dx, bx
        add     dx, 3
        mov     al, 2         ; 3
        out     dx, al

        mov     dx, bx
        add     dx, 4
        mov     al, 0xb
        out     dx, al

        mov     dx, bx
        add     dx, 1
        mov     al, 1
        out     dx, al

        ; --------------------------
        ; com2 mouse enable
        ; --------------------------
        
        mov     bx, 0x2f8 ; combase
        lea     dx, [bx + 3]
        ;mov     dx, bx
        ;add     dx, 3
        mov     al, 0x80
        out     dx, al

        mov     dx, bx
        add     dx, 1
        mov     al, 0
        out     dx, al

        mov     dx, bx
        add     dx, 0
        mov     al, 0x30*2
        out     dx, al

        mov     dx, bx
        add     dx, 3
        mov     al, 2
        out     dx, al

        mov     dx, bx
        add     dx, 4
        mov     al, 0xb
        out     dx, al

        mov     dx, bx
        add     dx, 1
        mov     al, 1
        out     dx, al
        ret

