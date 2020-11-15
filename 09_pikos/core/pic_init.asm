;
; Инициализация PIC - Programmable Interrupt Controller
;

PIC1             EQU 0x20  ; IO базовый адрес для master PIC 
PIC2             EQU 0xA0  ; IO базовый адрес для slave PIC 

PIC1_COMMAND     EQU PIC1
PIC1_DATA        EQU (PIC1+1)

PIC2_COMMAND     EQU PIC2
PIC2_DATA        EQU (PIC2+1)

PIC_EOI          EQU 0x20  ; End-of-interrupt command code 

ICW1_ICW4        EQU 0x01  ; ICW4 (not) needed 
ICW1_SINGLE      EQU 0x02  ; Single (cascade) mode 
ICW1_INTERVAL4   EQU 0x04  ; Call address interval 4 (8)
ICW1_LEVEL       EQU 0x08  ; Level triggered (edge) mode
ICW1_INIT        EQU 0x10  ; Initialization - required!
 
ICW4_8086        EQU 0x01  ; 8086/88 (MCS-80/85) mode
ICW4_AUTO        EQU 0x02  ; Auto (normal) EOI
ICW4_BUF_SLAVE   EQU 0x08  ; Buffered mode/slave
ICW4_BUF_MASTER  EQU 0x0C  ; Buffered mode/master
ICW4_SFNM        EQU 0x10  ; Special fully nested (not)

macro IoWait {
        jecxz $+0
        jecxz $+0
}

; Отключить APIC
core.ApicDisable:

        mov     ecx, 0x1B
        rdmsr
        and     eax, 0xFFFFF7FF
        wrmsr
        ret

; Инициализировать PIC
core.PicInit:

        call    core.ApicDisable
                
        xor     bx, 0xFFFF
        xor     edx, edx

        ; Запуск последовательности инициализации (в режиме каскада)
        ; IoWrite8(PIC1_COMMAND, ICW1_INIT + ICW1_ICW4); IoWait;
        mov     dl, PIC1_COMMAND
        mov     al, ICW1_INIT + ICW1_ICW4
        out     dx, al
        IoWait
        
        ; IoWrite8(PIC2_COMMAND, ICW1_INIT + ICW1_ICW4); IoWait;
        mov     dl, PIC2_COMMAND
        out     dx, al
        IoWait
        
        ; ICW2: Master PIC vector offset 0x20 .. 0x27 
        mov     dl, PIC1_DATA
        mov     al, 0x20
        out     dx, al
        IoWait
                
        ;  IoWrite8(PIC2_DATA, 0x28); IoWait; // ICW2: Slave PIC vector offset 0x28 .. 0x2F   
        mov     dl, PIC2_DATA
        mov     al, 0x28
        out     dx, al
        IoWait
        
        ; ICW3: послать сигнал на Master PIC, что существует slave PIC at IRQ2 (0000 0100)    
        mov     dl, PIC1_DATA
        mov     al, 4
        out     dx, al
        IoWait

        ; ICW3: сигнал Slave PIC на идентификацию каскада (0000 0010)
        mov     dl, PIC2_DATA
        mov     al, 2
        out     dx, al
        IoWait
        
        ; 8086/88 (MCS-80/85) режим (master/slave)
        ; IoWrite8(PIC1_DATA, ICW4_8086); IoWait;        
        mov     dl, PIC1_DATA
        mov     al, ICW4_8086
        out     dx, al
        IoWait
        
        ;  IoWrite8(PIC2_DATA, ICW4_8086); IoWait;
        mov     dl, PIC2_DATA
        out     dx, al
        IoWait
        
        ;  Записать маски (полностью блокировать прерывания)
        ;  IoWrite8(PIC1_DATA, 0xff); IoWait;
        mov     dl, PIC1_DATA
        mov     al, 0xFF
        out     dx, al
        IoWait
        
        ;  IoWrite8(PIC2_DATA, 0xff); IoWait;
        mov     dl, PIC2_DATA
        out     dx, al
        IoWait
  
        ; Размаскировать некоторые прерывания
        ; ---------------------------------------
        
        ; IoWrite8(PIC1_DATA, IoRead8(PIC1_DATA) & (~bitmask & 0xff));
        mov     dl, PIC1_DATA
        in      al, dx
        and     al, bl
        out     dx, al
        IoWait
        
        ; IoWrite8(PIC2_DATA, IoRead8(PIC2_DATA) & ((~bitmask >> 8) & 0xff)); 
        mov     dl, PIC2_DATA
        in      al, dx
        and     al, bh
        out     dx, al
        ret
