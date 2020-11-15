
// http://wiki.osdev.org/Interrupt_Descriptor_Table#IDT_in_IA-32e_Mode_.2864-bit_IDT.29
// attrb = 8Eh Interrupt
// attrb = 8Fh Trap

/** Процедура, которая переводит IRQ с их стандартных позиции из R-Mode в P-Mode */
void irq_redirect(uint bitmask) {

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
    IoWrite8(PIC1_DATA, IoRead8(PIC1_DATA) & ((~bitmask)      & 0xff));
    IoWrite8(PIC2_DATA, IoRead8(PIC2_DATA) & ((~bitmask >> 8) & 0xff));
}

/** Создать вектор в памяти */
void irq_make(dword id, void* ptr, byte attrb) {

    // Преобразуем указатель в адрес
    dword addr = (dword)ptr;

    // Дескрипторы IDT начинаются с 0 и занимают 256 x 16 = 4096 байт
    /* Тупой хак, но иначе компилятор меня не понимает */
    struct IDT_Item * item = (struct IDT_Item*) 8;

    id--;

    // Адрес
    item[ id ].low_addr = addr & 0xffff;
    item[ id ].hi_addr  = (addr >> 16) & 0xffff;

    // Параметры
    item[ id ].selector = 0x0010;        // Селектор кода
    item[ id ].attr     = (attrb << 8);  // Атрибуты, 8E00h
}

/** Инициализация Interrupt Service Routines */
void irq_init(uint bitmask) {

    int i;

    irq_redirect(bitmask);

    // Назначить 256 заглушек
    for (i = 0; i < 256; i++) {
        irq_make(i, & INT_null, 0x8E);
    }

    // Обработчики Exception
    // irq_make(0x0E, & err_page_fault, 0x8E);
    // irq_make(0x0D, & err_prot_fault, 0x8E);

    // Назначить вектора прерываний
    irq_make(0x20, & IRQ_timer,    0x8E); // 0 Таймер
    irq_make(0x21, & IRQ_keyboard, 0x8E); // 1 Клавиатура
    irq_make(0x22, & IRQ_cascade,  0x8E); // 2 Каскад
    irq_make(0x23, & IRQ_master,   0x8E); // 3
    irq_make(0x24, & IRQ_master,   0x8E); // 4
    irq_make(0x25, & IRQ_master,   0x8E); // 5
    irq_make(0x26, & IRQ_fdc,      0x8E); // 6
    irq_make(0x27, & IRQ_master,   0x8E); // 7
    irq_make(0x28, & IRQ_slave,    0x8E); // 8
    irq_make(0x29, & IRQ_slave,    0x8E); // 9
    irq_make(0x2A, & IRQ_slave,    0x8E); // A
    irq_make(0x2B, & IRQ_slave,    0x8E); // B
    irq_make(0x2C, & IRQ_ps2mouse, 0x8E); // C Мышь PS/2
    irq_make(0x2D, & IRQ_slave,    0x8E); // D
    irq_make(0x2E, & IRQ_slave,    0x8E); // E
    irq_make(0x2F, & IRQ_slave,    0x8E); // F

    // 100 Hz системный таймер
    IoWrite8(0x43, 0x34);
    IoWrite8(0x40, 0x9B);
    IoWrite8(0x40, 0x2E);

    timer = 0;
}

/** Получение значения таймера */
dword get_timer() {
    return timer;
}

/** Обработчик прерывания от таймера */
void pic_timer() {
    timer++;
}

/** Обработчик прерывания от клавиатуры */
void pic_keyboard() { pic.keyboard(); }

/** Обработчик FDC */
void pic_fdc() { pic.fdc(); }

/** Обработчик прерывания от мыши */
void pic_ps2mouse() { pic.ps2mouse(); }
