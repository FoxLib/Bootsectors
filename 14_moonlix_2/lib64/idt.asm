
create_idt:

    xor    rsi, rsi

    ; Создать IDT в линейном адресе 0
    xor    rdi, rdi         
    mov    ecx, 21

    ; Создать заглушку исключения
    ; --------------

.make_exc:        

    mov    esi, exception_gate
    movsq
    movsq
    loop .make_exc

    ; Создать заглушку прерывания
    ; --------------

    mov    ecx, 256-21

.make_int:                 ; make gates for the other interrupts

    mov    esi, interrupt_gate
    movsq
    movsq
    loop .make_int

    ; Создать прерывания на клавиатуру и таймер
    mov    word [qword 20h*16], clock       ; set IRQ 0 handler [lib64/handlers/clock.asm]
    mov    word [qword 21h*16], keyboard    ; set IRQ 1 handler [lib64/handlers/keyb.asm]
    mov    word [qword 22h*16], cascade     ; set IRQ 2 handler : Каскад
    mov    word [qword 2Ch*16], mouse       ; set IRQ C handler [lib64/handlers/mouse.asm]

    ; Загружаем регистр IDT
    lidt    [IDTR]        
    ret

; --------------------------------------------------------------------------------

IDTR:                                        ; Регистр дескриптора прерываний
  dw 256*16-1                                ; Лимит IDT (размер - 1)
  dq 0                                       ; линейный адрес IDT

; Шлюз исключения (0x8E)
exception_gate:

  dw exception and 0FFFFh, LONG_SELECTOR
  dw 8E00h, exception shr 16
  dd 0, 0

; Шлюз прерывания (0x8E)
; Шлюз ловушки (0x8F)
; http://www.ijack.org.uk/HTML/S/131.html#L73

interrupt_gate:

  dw interrupt and 0FFFFh, LONG_SELECTOR
  dw 8E00h, interrupt shr 16
  dd 0, 0
