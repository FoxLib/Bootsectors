// Программируемый контроллер прерываний

/* IVT Offset | INT #    | Description
; -----------+-----------+-----------------------------------
; 0x0000     | 0x00      | Divide by 0
; 0x0004     | 0x01      | Trace
; 0x0008     | 0x02      | NMI Interrupt
; 0x000C     | 0x03      | Breakpoint (INT3)
; 0x0010     | 0x04      | Overflow (INTO)
; 0x0014     | 0x05      | Bounds range exceeded (BOUND)
; 0x0018     | 0x06      | Invalid opcode (UD2)
; 0x001C     | 0x07      | Device not available (WAIT/FWAIT)
; -----------------------------------------------------------
; 0x0020     | 0x08      | Double fault
; 0x0024     | 0x09      | Coprocessor segment overrun
; 0x0028     | 0x0A      | Invalid TSS
; 0x002C     | 0x0B      | Segment not present
; 0x0030     | 0x0C      | Stack-segment fault
; 0x0034     | 0x0D      | General protection fault
; 0x0038     | 0x0E      | Page fault
; 0x003C     | 0x0F      | ---
; 0x0040     | 0x10      | x87 FPU error
; 0x0044     | 0x11      | Alignment check
; 0x0048     | 0x12      | Machine check
; 0x004C     | 0x13      | SIMD Floating-Point Exception
; 0x00xx     | 0x14-0x1F | ---
; 0x0xxx     | 0x20-0xFF | User defined
; -----------------------------------------------------------
*/

// Заглушка
void int_null() {

    brk;
}

// http://wiki.osdev.org/Interrupt_Descriptor_Table#IDT_in_IA-32e_Mode_.2864-bit_IDT.29
// attrb = 8Eh Interrupt
// attrb = 8Fh Trap

// Процедура, которая переводит IRQ с их стандартных позиции из R-Mode в P-Mode
void pic_init(int bitmask) {

    apic_disable();

    // Запуск последовательности инициализации (в режиме каскада)
    IoWrite8(PIC1_COMMAND, ICW1_INIT + ICW1_ICW4); IoWait;
    IoWrite8(PIC2_COMMAND, ICW1_INIT + ICW1_ICW4); IoWait;

    IoWrite8(PIC1_DATA, 0x20); IoWait; // ICW2: Master PIC vector offset 0x20 .. 0x27
    IoWrite8(PIC2_DATA, 0x28); IoWait; // ICW2: Slave PIC vector offset 0x28 .. 0x2F

    IoWrite8(PIC1_DATA, 4); IoWait; // ICW3: послать сигнал на Master PIC, что существует slave PIC at IRQ2 (0000 0100)
    IoWrite8(PIC2_DATA, 2); IoWait; // ICW3: сигнал Slave PIC на идентификацию каскада (0000 0010)

    // 8086/88 (MCS-80/85) режим (master/slave)
    IoWrite8(PIC1_DATA, ICW4_8086); IoWait;
    IoWrite8(PIC2_DATA, ICW4_8086); IoWait;

    // Записать маски (полностью блокировать прерывания)
    IoWrite8(PIC1_DATA, 0xff); IoWait;
    IoWrite8(PIC2_DATA, 0xff); IoWait;

    // Размаскировать некоторые прерывания
    IoWrite8(PIC1_DATA, IoRead8(PIC1_DATA) & (~bitmask & 0xff));
    IoWrite8(PIC2_DATA, IoRead8(PIC2_DATA) & ((~bitmask >> 8) & 0xff));
}

// Создать вектор в памяти
void irq_make(uint32_t id, void* ptr, uint8_t attrb) {

    // Преобразуем указатель в адрес
    uint32_t addr = (uint64_t)ptr;

    // Дескрипторы IDT начинаются с 0 и занимают 256 x 16 = 4096 байт
    struct IDT_Item * I = (struct IDT_Item*) 8; /* Тупой хак, но иначе компилятор меня не понимает */

    id--;

    // Адрес
    I[id].low_addr = addr & 0xffff;
    I[id].hi_addr  = (addr >> 16) & 0xffff;

    // Параметры
    I[id].selector = 0x0010;        // Селектор кода
    I[id].attr     = (attrb << 8);  // Атрибуты, 8E00h
}

// Инициализация Interrupt Service Routines
void init_irq(int bitmask) {

    int i;

    pic_init(bitmask);

    // Назначить 256 заглушек
    for (i = 0; i < 256; i++) {
        irq_make(i, & INT_null, 0x8E);
    }

    // Назначить вектора прерываний
    irq_make(0x20, & IRQ_timer,    0x8E); // timer
    irq_make(0x21, & IRQ_keyboard, 0x8E);
    irq_make(0x22, & IRQ_cascade,  0x8E);
    irq_make(0x23, & IRQ_master,   0x8E);
    irq_make(0x24, & IRQ_master,   0x8E);
    irq_make(0x25, & IRQ_master,   0x8E);
    irq_make(0x26, & IRQ_master,   0x8E);
    irq_make(0x27, & IRQ_master,   0x8E);

    irq_make(0x27, & IRQ_slave,    0x8E);
    irq_make(0x28, & IRQ_slave,    0x8E);
    irq_make(0x29, & IRQ_slave,    0x8E);
    irq_make(0x2A, & IRQ_slave,    0x8E);
    irq_make(0x2B, & IRQ_slave,    0x8E);
    irq_make(0x2C, & IRQ_ps2mouse, 0x8E);
    irq_make(0x2D, & IRQ_slave,    0x8E);
    irq_make(0x2E, & IRQ_slave,    0x8E);
    irq_make(0x2F, & IRQ_slave,    0x8E);

    // Обработчики Exception
    // irq_make(0x0E, & err_page_fault, 0x8E);
    // irq_make(0x0D, & err_prot_fault, 0x8E);
    
    timer = 0;
}
