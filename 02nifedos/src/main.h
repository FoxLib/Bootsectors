// Инициализация устройств
void startup() {

    // Простановка IRQ
    irq_init(IRQ_KEYB | IRQ_FDC | IRQ_CASCADE | IRQ_PS2MOUSE);

    // Найти ATA
    init_ata_devices();

    // Инициализировать FDD
    fdc_init();

    // Обнаружить мышь
    ps2_init_mouse();

    // Инициализировать видеоадаптер
    vg_init();

    // Включить прерывания
    sti;
}
