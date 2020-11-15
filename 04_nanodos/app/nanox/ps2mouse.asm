
; OUT 64h, <CMD>
; ---
; 0xA7 (Disable mouse interface)    - PS/2 mode only.  Similar to "Disable keyboard interface" (0xAD) command.
; 0xA8 (Enable mouse interface)     - PS/2 mode only.  Similar to "Enable keyboard interface" (0xAE) command.
; 0xA9 (Mouse interface test)       - Returns 0x00 if okay, 0x01 if Clock line stuck low, 0x02 if clock line stuck high, 0x03 if data line stuck low, and 0x04 if data line stuck high.
; 0xAA (Controller self-test)       - Returns 0x55 if okay.
; 0xAB (Keyboard interface test)    - Returns 0x00 if okay, 0x01 if Clock line stuck low, 0x02 if clock line stuck high, 0x03 if data line stuck low, and 0x04 if data line stuck high.
; 0xAD (Disable keyboard interface) - Sets bit 4 of command byte and disables all communication with keyboard.
; 0xAE (Enable keyboard interface)  - Clears bit 4 of command byte and re-enables communication with keyboard.
; 0xAF (Get version)
; 0xC0 (Read input port)            - Returns values on input port (see Input Port definition.)
; 0xC1 (Copy input port LSn)        - PS/2 mode only. Copy input port's low nibble to Status register (see Input Port definition)
; 0xC2 (Copy input port MSn)        - PS/2 mode only. Copy input port's high nibble to Status register (see Input Port definition.)
; 0xD0 (Read output port)           - Returns values on output port (see Output Port definition.) 
; 0xD1 (Write output port)          - Write parameter to output port (see Output Port definition.)
; 0xD2 (Write keyboard buffer)      - Parameter written to input buffer as if received from keyboard.
; 0xD3 (Write mouse buffer)         - Parameter written to input buffer as if received from mouse.
; 0xD4 (Write mouse Device)         - Sends parameter to the auxillary PS/2 device.
; 0xE0 (Read test port)             - Returns values on test port (see Test Port definition.)
; 0xF0-0xFF (Pulse output port)     - Pulses command's lower nibble onto lower nibble of output port (see Output Port definition.)

; Текущее положение
PS2Mouse.x          dw 320
PS2Mouse.y          dw 240
PS2Mouse.CursorA    dw 0             ; TMP-область для записи цветов за курсором
PS2Mouse.irq_0      dd 0             ; Старая область IRQ #0 Timer
PS2Mouse.irq_1      dd 0             ; Старая область IRQ #1 Keyboard
PS2Mouse.irq_2      dd 0             ; Старая область IRQ #2 Cascade

include "ps2/mouse_init.asm"
include "ps2/mouse_show.asm"
include "ps2/mouse_hide.asm"

; ----------------------------------------------------------------------
; Обработка прерывания мыши
; ds:data
; http://wiki.osdev.org/Mouse_Input#PS2_Mouse_Subtypes
; ----------------------------------------------------------------------
;   7  6  5  4  3  2  1  0
; 0 yo xo ys xs ao bm br bl
; 1 xm 
; 2 ym
; ----------------------------------------------------------------------

PS2Mouse.irq.cmd db 0

PS2Mouse.IRQ:

        pushad
        push    ds es 
        
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
                
        ; Сначала убрать мышь
        ; @TODO улучшить - убрать мигание        
        
        ; Рисовать мышь только в режиме ОС
        cmp     [param.os_status], 0
        jne     @f
        call    PS2Mouse.Hide

@@:     ; Читаем 3 байта (CMD, X shift, Y shift)
        call    kb_read
        push    ax
        
        ; -------------------------- [+X]
        call    kb_read
        cbw
        mov     bx, [PS2Mouse.x]
        add     bx, ax
        jns     @f
        xor     bx, bx
@@:     cmp     bx, [ResolutionX]
        jb      @f
        mov     bx, [ResolutionX]
        dec     bx
@@:     mov     [PS2Mouse.x], bx
                    
        ; -------------------------- [-Y]
        call    kb_read
        cbw
        mov     bx, [PS2Mouse.y]
        sub     bx, ax
        jns     @f
        xor     bx, bx
@@:     cmp     bx, [ResolutionY]
        jb      @f
        mov     bx, [ResolutionY]
        dec     bx
@@:     mov     [PS2Mouse.y], bx
                
        ; Прорисовка мыши на новой позиции
        cmp     [param.os_status], 0
        jne     @f
        call    PS2Mouse.Show
        
@@:     pop     ax
        mov     [PS2Mouse.irq.cmd], al

        mov     al, 20h
        out     0A0h, al
        out     020h, al
        
        pop     es ds
        popad
        iret
        
; ----------------------------------------------------------------------
; IRQ#0 Таймер

timer   dd 0                    ; Количество тиков

PS2Mouse.IRQ0:

        pushad
        push    ds es
        mov     ax, cs
        mov     ds, ax
        mov     es, ax        
        
        inc     [timer]
        mov     al, 20h
        out     20h, al
        pop     es ds
        popad
        iret        

; ----------------------------------------------------------------------
; IRQ#1 Клавиатура

PS2Mouse.IRQ1:

        pushad
        push    ds es
        mov     ax, cs
        mov     dx, ax
        mov     es, ax
        
        ; Перехват клавиатуры
        in      al, 60h
                
        
        pushf
        call    far [cs: PS2Mouse.irq_1]
        
        pop     es ds
        popad
        iret

; ----------------------------------------------------------------------
; IRQ#2 Обратная совместимость        

PS2Mouse.IRQ2:

        brk
        iret


