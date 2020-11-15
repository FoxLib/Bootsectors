
; ----------------------------------------------------------------------
; Простановка редиректов
; ----------------------------------------------------------------------

irq_init:

        pushfd                  ; размещение регистра EFLAGS в стеке
        pop     eax             ; извлечение значения EFLAGS в EAX
        mov     ebx, eax        ; сохранение значения в EBX
        xor     eax, 200000h    ; изменение 21-го бита CPUID 486
        push    eax             ; размещение нового значения в стеке
        popfd                   ; сохранение нового значения в EFLAGS
        pushfd                  ; снова размещение EFLAGS в стеке
        pop     eax             ; значение EFLAGS теперь в EAX
        xor     eax, ebx        ; проверка 21-го бита
        je      @f              ; если он не изменился, то CPUID не поддерживается

        ; Отключение APIC
        mov     ecx, 0x1b
        rdmsr
        and     eax, 0xfffff7ff
        wrmsr
        mov     [pentium], byte 1   ; это пентиум

@@:     ; Выполнение запросов
        mov     ecx, 10
        xor     edx, edx
        mov     esi, .data
@@:     lodsw
        mov     dl, al
        mov     al, ah
        out     dx, al
        jcxz    $+2
        jcxz    $+2
        loop    @b

        ; Часы на 100 гц
        mov     al, $34
        out     $43, al
        mov     al, $9b
        out     $40, al
        mov     al, $2e
        out     $40, al
        ret

.data:  ; Данные для отправки команд
        db      PIC1_COMMAND, ICW1_INIT + ICW1_ICW4
        db      PIC2_COMMAND, ICW1_INIT + ICW1_ICW4
        db      PIC1_DATA,    0x20
        db      PIC2_DATA,    0x28
        db      PIC1_DATA,    0x04
        db      PIC2_DATA,    0x02
        db      PIC1_DATA,    ICW4_8086
        db      PIC2_DATA,    ICW4_8086
        db      PIC1_DATA,    0xFF xor (IRQ_TIMER or IRQ_CASCADE or IRQ_FDC) ; or IRQ_KEYB
        db      PIC2_DATA,    0xFF xor (IRQ_PS2)

; ----------------------------------------------------------------------
; Инициализация IVT
; Для IRQ используются "обертки" - устанавливаются ссылки в .irq_X
; ----------------------------------------------------------------------

ivt_init:

        ; Очистка IVT
        mov     eax, .unk
        xor     edi, edi
        mov     ecx, 256
@@:     call    .make
        loop    @b

        ; Установка ссылок на обработчики IRQ #n
        mov     cx,  16
        mov     esi, ivt_links
        mov     edi, $20 shl 3
@@:     lodsd
        call    .make
        add     eax, 4
        loop    @b
        ret

.make:  ; eax - адрес прерывания, edi - адрес ivt
        mov     [edi+0], eax
        mov     [edi+4], eax
        mov     [edi+2], dword $8E000010
        add     edi, 8
        ret

.unk:   iretd

; ----------------------------------------------------------------------
irq_master:

        push    eax
        mov     al, $20
        out     $20, al         ; EOI Primary
        pop     eax
        iretd

irq_slave:

        push    eax
        mov     al, $20
        out     $20, al         ; EOI Primary
        out     $A0, al         ; EOI Slave
        pop     eax
        iretd

; ----------------------------------------------------------------------
; Список ссылок на прерывания
; ----------------------------------------------------------------------

ivt_links:
; pic-1
        dd      irq_timer           ; 0 Таймер
        dd      irq_master          ; 1 Клавиатура
        dd      irq_master          ; 2 Каскад
        dd      irq_master          ; 3
        dd      irq_master          ; 4
        dd      irq_master          ; 5
        dd      fdc_irq             ; 6 FDC
        dd      irq_master          ; 7
; pic-2
        dd      irq_slave           ; 8
        dd      irq_slave           ; 9
        dd      irq_slave           ; A
        dd      irq_slave           ; B
        dd      ps2_irq             ; C PS/2
        dd      irq_slave           ; D
        dd      irq_slave           ; E
        dd      irq_slave           ; F

; ----------------------------------------------------------------------
irq_timer:
; ----------------------------------------------------------------------

        push    eax
        mov     al, $20
        out     $20, al

        ; Увеличение системного времени
        inc     [irq_timer_counter]
        pop     eax
        iretd
