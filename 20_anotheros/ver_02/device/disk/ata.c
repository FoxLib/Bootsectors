
// Куда читать сектор
static inline void ata_pio_read(int base, byte* address) {

    asm volatile("pushl %%ecx" ::: "ecx");
    asm volatile("pushl %%edx" ::: "edx");
    asm volatile("pushl %%edi" ::: "edi");
    asm volatile("movl  $0x100, %%ecx" ::: "ecx");
    asm volatile("movl  %0, %%edx" :: "r"(base) : "edx" );
    asm volatile("movl  %0, %%edi" :: "r"(address) : "edi" );
    asm volatile("rep   insw");
    asm volatile("popl  %%edi" ::: "edi");
    asm volatile("popl  %%edx" ::: "edx");
    asm volatile("popl  %%ecx" ::: "ecx");
}

/** SRST сигнал */
int ata_soft_reset(int devctl) {

    int i;

    IoWrite8(devctl, 4); // do a "software reset" on the bus
    IoWrite8(devctl, 0); // reset the bus to normal operation

    IoRead8(devctl);
    IoRead8(devctl);
    IoRead8(devctl);
    IoRead8(devctl);

    // want BSY clear and RDY set
    for (i = 0; i < 4096; i++) {
        if ((IoRead8(devctl) & 0xC0) == 0x40)
            return 0;
    }

    return 1;
}

/** Выбор устройства для работы */
void ata_drive_select(int slavebit, struct ATA_DEVICE* ctrl) {

    // Выбор устройства (primary | slave) | 0x40=Set LBA Bit
    IoWrite8(ctrl->base + ATA_REG_DEVSEL, 0xA0 | 0x40 | slavebit << 4);

    // Ожидать 400ns, пока драйв включится в работу
    IoRead8(ctrl->dev_ctl);
    IoRead8(ctrl->dev_ctl);
    IoRead8(ctrl->dev_ctl);
    IoRead8(ctrl->dev_ctl);
}

/** id = [0..3], номер ATA */
int ata_identify(int id) {

    int i;

    // Не использовать идентификацию для нерабочего устройства
    if (ata_drive[id].type == DISK_DEV_UNKNOWN)
        return 0;

    int slavebit = id & 1;
    struct ATA_DEVICE * ctrl = & ata_drive[id];

    // Установить рабочий драйв
    ata_drive_select(id & 1, & ata_drive[id]);

    // Команда на считывание информации о диске
    IoWrite8(ctrl->base + ATA_REG_COUNT,   0x00);
    IoWrite8(ctrl->base + ATA_REG_LBA_LO,  0x00);
    IoWrite8(ctrl->base + ATA_REG_LBA_MID, 0x00);
    IoWrite8(ctrl->base + ATA_REG_LBA_HI,  0x00);

    // IDENTIFY
    IoWrite8(ctrl->base + ATA_REG_CMD,     0xEC);

    int w = IoRead8(ctrl->base + ATA_REG_CMD);

    // Ошибка драйва?
    if (w == 0) return 0;

    // Ожидание устройства
    for (i = 0; i < 4096; i++) {

        // Ждем BSY=0
        if ((IoRead8(ctrl->base + ATA_REG_CMD) & 0x80) == 0) {

            // Читаем 1 сектор в режиме PIO
            ata_pio_read(ctrl->base, ctrl->identify);

            // Определяем стартовый сектор #0
            ata_drive[id].start = 0;

            return 1;
        }
    }

    return 0;
}

/** Primary bus:
 * ctrl->base    = 0x1F0
 * ctrl->dev_ctl = 0x3F6
 */
int ata_detect_devtype(int slavebit, struct ATA_DEVICE* ctrl) {

    // Ждать, пока устройство будет готово
    if (ata_soft_reset(ctrl->dev_ctl)) {
        return DISK_DEV_UNKNOWN;
    }

    // Выбор устройства (primary | slave)
    ata_drive_select(slavebit, ctrl);

    // Получение битов сигнатуры
	unsigned cl = IoRead8(ctrl->base + ATA_REG_LBA_MID);
	unsigned ch = IoRead8(ctrl->base + ATA_REG_LBA_HI);

	// Различение ATA, ATAPI, SATA и SATAPI
	if (cl == 0x14 && ch == 0xEB) return DISK_DEV_PATAPI;
	if (cl == 0x69 && ch == 0x96) return DISK_DEV_SATAPI;
	if (cl == 0x00 && ch == 0x00) return DISK_DEV_PATA;
	if (cl == 0x3c && ch == 0xc3) return DISK_DEV_SATA;

	return DISK_DEV_UNKNOWN;
}

/** Подготовка устройства к запросу на чтение или запись
 * command = 0x24 READ; 0x34 WRITE */
void ata_prepare_lba(int device_id, uint lba, int count, int command) {

    int base   = ata_drive[ device_id ].base;
    int devctl = ata_drive[ device_id ].dev_ctl;

    // Коррекция
    lba += ata_drive[ device_id ].start;

    // Выбор устройства (primary | slave) | 0x40=Set LBA Bit | LBA[27:24]
    IoWrite8(base + ATA_REG_DEVSEL, 0xA0 | 0x40 | (device_id & 1) << 4 | ((lba >> 24) & 0xF) );

    // Ожидать 400ns, пока драйв включится в работу
    IoRead8(devctl);
    IoRead8(devctl);
    IoRead8(devctl);
    IoRead8(devctl);

    // Старшие разряды
    IoWrite8(base + ATA_REG_COUNT,   (count >>  8) & 0xFF);
    IoWrite8(base + ATA_REG_LBA_LO,  (lba   >> 24) & 0xFF);
    IoWrite8(base + ATA_REG_LBA_MID, 0);
    IoWrite8(base + ATA_REG_LBA_HI,  0);

    // Младшие
    IoWrite8(base + ATA_REG_COUNT,   (count    ) & 0xFF);
    IoWrite8(base + ATA_REG_LBA_LO,  (lba      ) & 0xFF);
    IoWrite8(base + ATA_REG_LBA_MID, (lba >>  8) & 0xFF);
    IoWrite8(base + ATA_REG_LBA_HI,  (lba >> 16) & 0xFF);

    // Запрос чтения
    IoWrite8(base + ATA_REG_CMD, command);
}

/** Чтение сектора с выбранного ATA */
int ata_read_sectors(byte* address, int device_id, int lba, int count) {

    int i;
    int base = ata_drive[ device_id ].base;

    // Подготовить для чтения
    ata_prepare_lba(device_id, lba, count, 0x24);

    // Ждем BSY=0
    for (i = 0; i < 4096; i++)
    if ((IoRead8(base + ATA_REG_CMD) & 0x80) == 0) {

        // При DRQ=1, ERR=0, CORR=0, IDX=0, RDY=1, DF=0
        if ((IoRead8(base + ATA_REG_CMD) & 0x6F) == 0x48) {
            ata_pio_read(base, address);
            return 0;
        }
    }

    return 1;
}

