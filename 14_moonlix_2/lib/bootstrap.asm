
; Порты для инициализации PIC
; ------------------------------------------------------------------------------
PIC1             EQU 0x20  ; IO базовый адрес для master PIC */
PIC2             EQU 0xA0  ; IO базовый адрес для slave PIC */

PIC1_COMMAND     EQU PIC1
PIC1_DATA        EQU (PIC1+1)

PIC2_COMMAND     EQU PIC2
PIC2_DATA        EQU (PIC2+1)

PIC_EOI          EQU 0x20  ; End-of-interrupt command code */

ICW1_ICW4        EQU 0x01  ; ICW4 (not) needed */
ICW1_SINGLE      EQU 0x02  ; Single (cascade) mode */
ICW1_INTERVAL4   EQU 0x04  ; Call address interval 4 (8) */
ICW1_LEVEL       EQU 0x08  ; Level triggered (edge) mode */
ICW1_INIT        EQU 0x10  ; Initialization - required! */
 
ICW4_8086        EQU 0x01  ; 8086/88 (MCS-80/85) mode */
ICW4_AUTO        EQU 0x02  ; Auto (normal) EOI */
ICW4_BUF_SLAVE   EQU 0x08  ; Buffered mode/slave */
ICW4_BUF_MASTER  EQU 0x0C  ; Buffered mode/master */
ICW4_SFNM        EQU 0x10  ; Special fully nested (not) */


; ------------------------------------------------------------------------------
IRQ_redirect:

    ; Отключение APIC
    mov ecx, 0x1B
    rdmsr
    and eax, 0xfffff7ff ; Сбрасываем 11-й бит в MSR 1Bh (APIC=0)
    wrmsr

    ; Запуск последовательности инициализации (в режиме каскада)
    outb_wait PIC1_COMMAND, ICW1_INIT + ICW1_ICW4
    outb_wait PIC2_COMMAND, ICW1_INIT + ICW1_ICW4
    
    outb_wait PIC1_DATA, 0x20 ; ICW2: Master PIC vector offset 0x20 .. 0x27    
    outb_wait PIC2_DATA, 0x28 ; ICW2: Slave PIC vector offset 0x28 .. 0x2F
    
    outb_wait PIC1_DATA, 4 ; ICW3: послать сигнал на Master PIC, что существует slave PIC at IRQ2 (0000 0100)    
    outb_wait PIC2_DATA, 2 ; ICW3: сигнал Slave PIC на идентификацию каскада (0000 0010)

    ; 8086/88 (MCS-80/85) режим (master/slave)
    outb_wait PIC1_DATA, ICW4_8086
    outb_wait PIC2_DATA, ICW4_8086
   
    ; Отключить все прерывания
    outb_wait PIC1_DATA, 0xFF
    outb_wait PIC2_DATA, 0xFF

    ; Размаскировать некоторые прерывания
    IRQ_mask PIC1_DATA, bl
    IRQ_mask PIC2_DATA, bh

    ret

; Создать шлюзы прерываний
; ------------------------------------------------------------------------------
INT_setup:

    mov bx,  8
    xor cx, cx
    mov dx, 256

    ; Создаем 256 шт. INTERRUPT_NULL (заглушки)
    ; Необходимы, чтобы при вызове прерывания, был простой IRETD   
    mov edi, IDT_start
@@: create_idt_descriptor INTERRUPT_NULL
    dec dx
    jne @b

    ; Создание всех системных дескрипторов-шлюзов IDT [lib/interrupts.asm]
    mov edi, IDT_start
    create_idt_descriptor INTERRUPT_00_DE
    create_idt_descriptor INTERRUPT_01_DB
    create_idt_descriptor INTERRUPT_02_NMI
    create_idt_descriptor INTERRUPT_03_BP
    create_idt_descriptor INTERRUPT_04_OF
    create_idt_descriptor INTERRUPT_05_BR
    create_idt_descriptor INTERRUPT_06_UD
    create_idt_descriptor INTERRUPT_07_NM
    create_idt_descriptor INTERRUPT_08_DF
    create_idt_descriptor INTERRUPT_09_FPU_seg
    create_idt_descriptor INTERRUPT_0A_TS
    create_idt_descriptor INTERRUPT_0B_NP
    create_idt_descriptor INTERRUPT_0C_SS
    create_idt_descriptor INTERRUPT_0D_GP
    create_idt_descriptor INTERRUPT_0E_PF
    create_idt_descriptor INTERRUPT_0F
    create_idt_descriptor INTERRUPT_10_MF
    create_idt_descriptor INTERRUPT_11_AC
    create_idt_descriptor INTERRUPT_12_MC
    create_idt_descriptor INTERRUPT_13_XF
    create_idt_descriptor INTERRUPT_14_VE
    create_idt_descriptor INTERRUPT_1E_SX

    mov edi, IDT_start + 0x0100 ; IRQ 0x20 .. 0x2F [lib/irq.asm]

    ; То случай, когда надо создать задачу
    ; create_task_gate TASK_timer  ; Шлюз задачи на прерывание IRQ 0 [timer]
    ; mov bx, 0x8 ; Восстанавливаем селектор BX

    create_idt_descriptor IRQ_0
    create_idt_descriptor IRQ_1
    create_idt_descriptor IRQ_2
    create_idt_descriptor IRQ_3
    create_idt_descriptor IRQ_4
    create_idt_descriptor IRQ_5
    create_idt_descriptor IRQ_6
    create_idt_descriptor IRQ_7
    create_idt_descriptor IRQ_8
    create_idt_descriptor IRQ_9
    create_idt_descriptor IRQ_A
    create_idt_descriptor IRQ_B
    create_idt_descriptor IRQ_C
    create_idt_descriptor IRQ_D
    create_idt_descriptor IRQ_E
    create_idt_descriptor IRQ_F

    ; Сервисные подпрограммы
    create_idt_descriptor INT_30

    ret

; --------------------------------------------------------
; Создание дескриптора IDT в защищенном режиме
; --------------------------------------------------------
; EAX - Адрес 32
; BX  - Селектор
; CX  - Конфигурация (=0)
; ES:EDI - Указатель
; -------------------------------------------------------- 

CREATE_idt_descriptor:

    stosw ; addr0..15   

    xchg ax, bx    
    stosw ; selector        
    xchg ax, bx

    mov ax, 0x8E00 ; => Present, 0x0E0 System | gate interrupt         
    or  ax, cx
    stosw ; configs

    shr eax, 16
    stosw ; addr16..31
    ret

; --------------------------------------------------------
; Создание дескриптора в защищенном режиме
; EAX    - Лимит 24
; EBX    - Адрес 32
; CX     - Конфигурация
; ES:EDI - Указатель на элемент GDT
; --------------------------------------------------------

CREATE_descriptor:

    stosw ; limit
    
    xchg  eax, ebx
    stosw ; address 0..15
    
    shr   eax, 16
    stosb ; addr 16..23

    xchg  eax, ebx
    mov   al, cl
    stosb ; config low

    shr   eax, 16
    or    al, ch
    stosb ; config + limit

    xchg  eax, ebx
    shr   ax, 8
    stosb ; addr 24..31

    ret

; --------------------------------------------------------
; Создание шлюза TSS для IRQ/INT. BX - селектор, ES:EDI ptr
; --------------------------------------------------------

;Структура шлюза задачи
;=======================
;
;   63                  48  47  46 45  44      40  39  37 36     32
; +-----------------------+---+------+-----------+-------+---------+
; |                       | P | DPL  | 0 0 1 0 1 |                 |
; +-----------------------+---+------+-----------+-------+---------+
; 
;   31                  16 15                                     0
; +-----------------------+----------------------------------------+
; | Селектор TSS          |                                        |
; +-----------------------+----------------------------------------+7
;
; GATE_TASK tss_selector
; {
;    dw 0 ; +0
;    dw tss_selector ; +2
;    db 0 ; +4
;    db 10000101b ; +5 Present, DPL=0
;    dw 0 ; +6
; }

CREATE_task_gate:
   
    xor ax, ax
    stosw
    xchg ax, bx
    stosw ; селектор
    mov ax, 0x8500 ; 0x5 - Task Gate, DPL=0, Present
    stosw
    xor ax, ax
    stosw
    ret    

; Очистка системной памяти с 0x00140000 [3 Мб]
CLEAR_memory:

    mov edi, 0x00140000
    mov ecx, 0x00386000 shr 2
    xor eax, eax
    rep stosd
    ret    

; Инициализация RTC-таймера (задача ядра)
TIMER_init:

    mov al, 0x34
    out 0x43, al
    mov al, 0x9B
    out 0x40, al ; lsb
    mov al, 0x2E
    out 0x40, al ; msb    

    ret

; Создание задачи ядра, AX - селектор, EBX - адрес TSS, EDX - ука
TASK_create_0:

    ; 1. Сначала, создаем дескриптор TSS (селектор AX), размером 104 байта, адрес EBX
    ; -----    
    movzx eax, ax
    mov   edi, GDT_start
    add   edi, eax ; edi = ax * 8 + GDT_start
    mov   eax, 103 ; 104 - 1
    mov   cx, 0x89 ; SYS_SEGMENT_AVAIL_386_TSS (0x9) + SEG_PRES(0x80)
    push  ebx
    call  CREATE_descriptor
    pop   edi

    ; 2. Инициализация TSS (Task Segment State)

    ;  http://wiki.osdev.org/TSS
    ; -----+-- 31..16 --+-- 15..0 --+
    ; 0x00 | ---        | LINK      | Ссылка на предыдущую задачу
    ; 0x04 | ESP0                   | Стек (SS0:ESP0) для уровня 0
    ; 0x08 | ---        | SS0       |
    ; 0x0C | ESP1                   |
    ; 0x10 | ---        | SS1       |
    ; 0x14 | ESP2                   |
    ; 0x18 | ---        | SS2       |
    ;      +------------+-----------+
    ; 0x1C | CR3                    | Указатель на механизм страничной адресации
    ; 0x20 | EIP                    |
    ; 0x24 | EFLAGS                 |
    ; 0x28 | EAX                    |
    ; 0x2C | ECX                    |
    ; 0x30 | EDX                    |
    ; 0x34 | EBX                    |
    ; 0x38 | ESP                    |
    ; 0x3C | EBP                    |
    ; 0x40 | ESI                    |
    ; 0x44 | EDI                    |
    ;      +------------+-----------+
    ; 0x48 | ---        | ES        |
    ; 0x4C | ---        | CS        |
    ; 0x50 | ---        | SS        |
    ; 0x54 | ---        | DS        |
    ; 0x58 | ---        | FS        |
    ; 0x5C | ---        | GS        |
    ; 0x60 | ---        | LDTR      |
    ; 0x64 |IOPB offset | ---       |
    ;      +------------+-----------+

    stosde 0 ; link = 0
    stosde 0x20000 ; esp0
    stosde 0x18 ; ss0
    stosde 0x28000 ; esp1
    stosde 0x18 ; ss1
    stosde 0x24000 ; esp2
    stosde 0x18 ; ss2
    stosde cr3 ; cr3

    ; Выставляется EIP
    stosde edx ; EIP
    stosde 0x202 ; EFLAGS

    xor eax, eax
    stosd ; eax
    stosd ; ecx
    stosd ; edx
    stosd ; ebx
    stosde 0x20000 ; ESP
    xor eax, eax
    stosd ; ebp
    stosd ; esi
    stosd ; edi

    stosde 0x0020 ; ES
    stosde 0x0008 ; CS
    stosde 0x0018 ; SS
    stosde 0x0010 ; DS

    xor eax, eax
    stosd ; FS
    stosd ; GS
    stosd ; LDTR
    stosd ; IOPB offset
    ret    

; Инициализация виртуального режима x86 (для BIOS)
; ------------------------------------------------
VM_initialize:

    mov [es:TSS_VM + 0x24 + 2], byte 0x02 ; Flags: VM = 1, AC=RF=VIF=VIP = 0

    ; INT все равно обрабатывается как обычные INT
    and [es:TSS_VM + 0x24 + 1], byte 0x0D ; IF=0   

    ; Проставить DPL=3
    or [es:GDT_start + TASK_vm + 0x05], byte 0x60 ; DPL=3

    ; Запись новых сегментов
    mov edi, TSS_VM + 0x48     
    xor eax, eax
    stosd ; es
    stosd ; cs
    stosd ; ss
    stosd ; ds
    stosd ; fs
    stosd ; gs

    mov [es:TSS_VM + 0x50], word 0x9000 ; 0x90000 - сегмент стека
    mov [es:TSS_VM + 0x38], dword 0 ; стек по умолчанию = 0, спуск вниз
    mov [es:TSS_VM + 0x20], dword VM ; по умолчанию, VM указывает на базовый обработчик

    ; @TODO Инициализация прерываний BIOS

    ret