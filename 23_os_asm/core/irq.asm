
; ----------------------------------------------------------------------
ivt:    ; Таблица векторов прерываний
; ----------------------------------------------------------------------

.vec0:  jmp     dword [.irq_0]  ; Таймер
.vec1:  jmp     dword [.irq_1]  ; Клавиатура
        jmp     dword [.irq_2]  ; Каскад
        jmp     dword [.irq_3] 
        jmp     dword [.irq_4]
        jmp     dword [.irq_5]
        jmp     dword [.irq_6]  ; Флоппи-диск
        jmp     dword [.irq_7]
        jmp     dword [.irq_8]
        jmp     dword [.irq_9]
        jmp     dword [.irq_A]
        jmp     dword [.irq_B]
        jmp     dword [.irq_C]  ; PS/2
        jmp     dword [.irq_D]
        jmp     dword [.irq_E]
        jmp     dword [.irq_F]

; Ссылки на обработчики IRQ: Могут меняться драйверами
; ----------------------------------------------------------------------

.irq_0: dd      irq.timer
.irq_1: dd      irq.keyb
.irq_2: dd      irq.master
.irq_3: dd      irq.master
.irq_4: dd      irq.master
.irq_5: dd      irq.master
.irq_6: dd      fdc_irq
.irq_7: dd      irq.master

.irq_8: dd      irq.slave
.irq_9: dd      irq.slave
.irq_A: dd      irq.slave
.irq_B: dd      irq.slave
.irq_C: dd      irq.ps2
.irq_D: dd      irq.slave
.irq_E: dd      irq.slave
.irq_F: dd      irq.slave

irq:

; Таймер
; ----------------------------------------------------------------------
.timer:
        pusha
        inc     [irq_timer]
        call    fdc_timeout
        popa
        jmp     .slave


; Клавиатура
; ----------------------------------------------------------------------
.keyb:  pusha
        in      al, $60
        popa
        jmp     .master

; Мышь
; ----------------------------------------------------------------------
.ps2:   pusha
        call    ps2_handler
        popa
        jmp     .slave


; Master IRQ
; ----------------------------------------------------------------------
.master:
        push    eax
        mov     al, $20
        out     $20, al
        pop     eax
        iretd

; Slave IRQ
; ----------------------------------------------------------------------
.slave: push    eax
        mov     al, $20
        out     $20, al
        out     $A0, al
        pop     eax
        iretd  
