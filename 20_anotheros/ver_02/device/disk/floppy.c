// https://wiki.osdev.org/ISA_DMA
// https://wiki.osdev.org/Floppy_Disk_Controller :: Programming Details
// http://bos.asmhackers.net/docs/floppy/docs/floppy_tutorial.txt

/** Установка DMA Channel 2 на передачу данных в [0x1000 - 0x33ff] */
void fdc_dma_init() {

    IoWrite8(0x0A, 0x06);       // mask DMA channel 2 and 0 (assuming 0 is already masked)

    // Запись адреса
    IoWrite8(0x0C, 0xFF);       // reset the master flip-flop
    IoWrite8(0x04, 0x00);       // address to 0x00 (low byte)
    IoWrite8(0x04, 0x10);       // address to 0x10 (high byte)

    // Запись количества
    IoWrite8(0x0C, 0xFF);       // reset the master flip-flop
    IoWrite8(0x05, 0xFF);       // count to 0x23ff (low byte)
    IoWrite8(0x05, 0x23);       // count to 0x23ff (high byte)

    // Верхний адрес
    IoWrite8(0x81, 0x00);       // external page register to 0 for total address of 00 10 00
    IoWrite8(0x0A, 0x02);       // unmask DMA channel 2
}

/** Подготовить диск на чтение */
void fdc_dma_read() {

    IoWrite8(0x0A, 0x06);       // mask DMA channel 2 and 0 (assuming 0 is already masked)
    IoWrite8(0x0B, 0x56);       // 01010110 single transfer, address increment, autoinit, read, channel2)
    IoWrite8(0x0A, 0x02);       // unmask DMA channel 2
}

/** Ожидание получения данных */
void fdc_wait(int bits) {
    while (((IoRead8(MAIN_STATUS_REGISTER)) & bits) != bits);
}

/** Подготовить диск на запись */
void fdc_dma_write() {

    IoWrite8(0x0A, 0x06);       // mask DMA channel 2 and 0 (assuming 0 is already masked)
    IoWrite8(0x0B, 0x5A);       // 01011010 single transfer, address increment, autoinit, write, channel2)
    IoWrite8(0x0A, 0x02);       // unmask DMA channel 2
}

/** Запись данных */
void fdc_write_reg(byte reg) {

    fdc_wait(0x80);
    IoWrite8(DATA_FIFO, reg);
}

/** Чтение данных */
byte fdc_read_reg() {

    fdc_wait(0xc0);
    return IoRead8(DATA_FIFO);
}

/** Включение мотора */
void fdc_motor_on() {

    fdc.motor = 1;
    fdc.timem = get_timer();
    IoWrite8(DIGITAL_OUTPUT_REGISTER, 0x1C);
}

/** Выключить мотор */
void fdc_motor_off() {

    fdc.motor = 0;
    fdc.timem = 0;
    IoWrite8(DIGITAL_OUTPUT_REGISTER, 0);
}

/** Проверить IRQ-статус после SEEK/CALIBRATE/.. */
byte fdc_sensei() {

    // Отправка запроса
    fdc_write_reg(SENSE_INTERRUPT);
    fdc_wait(0xD0);

    // Получение результата
    fdc.st0 = fdc_read_reg();
    fdc_wait(0xD0);

    // Возвращается номер цилиндра
    return fdc_read_reg();
}

/** Конфигурирование */
void fdc_configure() {

    fdc_write_reg(SPECIFY);
    fdc_write_reg(0);           // steprate_headunload
    fdc_write_reg(0);           // headload_ndma
}

/** Рекалибрация */
void fdc_calibrate() {

    fdc_motor_on();

    fdc_write_reg(RECALIBRATE);     // Команда
    fdc_write_reg(0);               // Drive = A:

    /* Ожидать и принять данные от рекалибрации */
    fdc.status = FDC_STATUS_SENSEI;
    fdc.irq_ready = 0; while (!fdc.irq_ready);
}

/** Сбросить контроллер перед работой с диском */
void fdc_reset() {

    // Отключить и включить контроллер
    IoWrite8(DIGITAL_OUTPUT_REGISTER, 0x00);
    IoWrite8(DIGITAL_OUTPUT_REGISTER, 0x0c);

    // Подождать IRQ
    fdc.status = FDC_STATUS_SENSEI;
    fdc.irq_ready = 0; while (!fdc.irq_ready);

    // Конфигурирование
    IoWrite8(CONFIGURATION_CONTROL_REGISTER, 0);

    fdc_configure();
    fdc_calibrate();
}

/** Сбор результирующих данных: если > 0, то ошибка */
int fdc_get_result() {

    fdc.st0         = fdc_read_reg();
    fdc.st1         = fdc_read_reg();
    fdc.st2         = fdc_read_reg();
    fdc.cyl         = fdc_read_reg();
    fdc.head_end    = fdc_read_reg();
    fdc.head_start  = fdc_read_reg();
    fdc_read_reg();

    return (fdc.st0 & 0xc0);
}

/** Чтение и запись в DMA => IRQ #6
 * write = 0 READ; 1 WRITE
 * head=0..1
 * cyl=0..79
 * */
void fdc_rw(byte write, byte head, byte cyl, byte sector) {

    // MFM_bit = 0x40 | (W=0x45 | R=0x46)

    /* 0 */ fdc_write_reg(write ? 0x45 : 0x46);
    /* 1 */ fdc_write_reg(head << 2);
    /* 2 */ fdc_write_reg(cyl);
    /* 3 */ fdc_write_reg(head);
    /* 4 */ fdc_write_reg(sector);
    /* 5 */ fdc_write_reg(2);       // Размер сектора (2 ~> 512 bytes)
    /* 6 */ fdc_write_reg(18);      // Последний сектор в цилиндре
    /* 7 */ fdc_write_reg(0x1B);    // Длина GAP3
    /* 8 */ fdc_write_reg(0xFF);    // Длина данных, игнорируется

    fdc.irq_ready = 0;
    fdc.status    = FDC_STATUS_RW;
}

/** Конвертировать LBA -> CHS */
void fdc_lba2chs(int lba) {

    fdc.r_sec = (lba % 18) + 1;
    lba /= 18;
    fdc.r_head = lba & 1;
    fdc.r_cyl = (lba >> 1);
}

/** Поиск дорожки => IRQ #6 */
void fdc_seek(byte head, byte cyl) {

    fdc_write_reg(0x0F);
    fdc_write_reg(head << 2);
    fdc_write_reg(cyl);

    fdc.irq_ready = 0;
    fdc.status    = FDC_STATUS_SEEK;
}

/** Подготовить драйв к чтению/записи */
void fdc_prepare(int lba) {

    fdc_lba2chs(lba);

    // Отметить, что ошибок пока нет
    fdc.error = 0;
    fdc.timem = get_timer();

    // Включить мотор, если нужно
    if (fdc.motor == 0) { fdc_reset(); }

    // Начать поиск дорожки
    fdc_seek(fdc.r_head, fdc.r_cyl);

    // Ждать IRQ
    while (fdc.irq_ready == 0);
}

/** Чтение сектора в $1000 -> IRQ #6 */
void fdc_read(int lba) {

    fdc_prepare(lba); // Подготовка
    fdc_dma_read();   // Настроить DMA на чтение
    fdc_rw(0, fdc.r_head, fdc.r_cyl, fdc.r_sec); // Читать
}

/** Запись сектора из $1000 -> IRQ #6 */
void fdc_write(int lba) {

    fdc_prepare(lba); // Подготовка
    fdc_dma_write();  // Настроить DMA на запись
    fdc_rw(1, fdc.r_head, fdc.r_cyl, fdc.r_sec); // Писать
}

/** Обработчик прерывания от FDC */
void fdc_irq() {

    switch (fdc.status) {

        /** Проверка статуса RESET */
        case FDC_STATUS_SENSEI:

            fdc_sensei();
            break;

        /** Поиск дорожки */
        case FDC_STATUS_SEEK:

            fdc.cyl = fdc_sensei();
            break;

        /** Чтение или запись */
        case FDC_STATUS_RW:

            if (fdc_get_result()) {
                fdc.error = 1;
            }

            break;
    }

    fdc.irq_ready = 1;
}
