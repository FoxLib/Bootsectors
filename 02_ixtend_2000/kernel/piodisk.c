// http://wiki.osdev.org/ATA_PIO_Mode

// Распределение портов
#define PIO_DATA_PORT 0
#define PIO_FEATURES  1
#define PIO_SECTORS   2
#define PIO_LBA_LO    3
#define PIO_LBA_MID   4
#define PIO_LBA_HI    5
#define PIO_DEVSEL    6
#define PIO_CMD       7

#define ATADEV_UNKNOWN 0
#define ATADEV_PATAPI  1
#define ATADEV_SATAPI  2
#define ATADEV_PATA    3
#define ATADEV_SATA    4
#define ATADEV_FAILED  5

// id = 0..3 [ATA PRIMARY/SECONDARY MASTER/SLAVE]
uint8_t pio_drive_detection(uint8_t id) {

    uint16_t i;
    uint16_t ioaddr1 = 0x170 + ((id & 2) ? 0 : 0x80); // PRI=1F0h | SEC=170h
    uint16_t ioaddr2 = ioaddr1 | 0x200;             // PRI=3F0h | SEC=370h
    uint16_t slave = id & 1;    
    uint16_t pio2_devsel = ioaddr2 + PIO_DEVSEL;

    // 1. SOFTWARE RESET
    IoWrite8(pio2_devsel, 4);  // "software reset" on the bus
    IoWrite8(pio2_devsel, 0);  // reset the bus to normal operation
    for (i = 0; i < 4; i++) IoRead8(pio2_devsel); 
    
    // Сброс для поиска готовности
    i = 0;     
    
    // check BSY and RDY; want BSY clear and RDY set     
    while ( (IoRead8(pio2_devsel) & 0xC0) == 0x00 ) 
        if (i++ > 1024)
            return ATADEV_FAILED;

    // 2. Шлем команду на определение девайса
    IoWrite8(ioaddr1 + PIO_DEVSEL, 0xA0 | (slave << 4));
    
    // 3. Ждать...
    for (i = 0; i < 4; i++) IoRead8(pio2_devsel); 
    
    // 4. Signature
    uint8_t cl = IoRead8(ioaddr1 + PIO_LBA_MID);
	uint8_t ch = IoRead8(ioaddr1 + PIO_LBA_HI);
    
    /* Определим ATA, ATAPI, SATA and SATAPI */
	if (cl == 0    && ch == 0)    return ATADEV_PATA;
	if (cl == 0x14 && ch == 0xEB) return ATADEV_PATAPI;
	if (cl == 0x69 && ch == 0x96) return ATADEV_SATAPI;
	if (cl == 0x3c && ch == 0xc3) return ATADEV_SATA;

	return ATADEV_UNKNOWN;    
}

// Отправка IDENTIFY и сохранение его в ADDR
uint8_t pio_drive_identify(uint8_t id, uint64_t addr) {
    
    uint16_t i;
    uint16_t ioaddr1 = 0x170 + ((id & 2) ? 0 : 0x80); // PRI=1F0h | SEC=170h
    uint16_t ioaddr2 = ioaddr1 | 0x200;               // PRI=3F0h | SEC=370h
    uint16_t slave   = id & 1;    

    IoWrite8(ioaddr1 + PIO_DEVSEL,   0xA0 | (slave << 4));   // Send 0xA0 for the "master" or 0xB0 for the "slave"
    IoWrite8(ioaddr1 + PIO_SECTORS,  0x00);
    IoWrite8(ioaddr1 + PIO_LBA_LO,   0x00);
    IoWrite8(ioaddr1 + PIO_LBA_MID,  0x00);
    IoWrite8(ioaddr1 + PIO_LBA_HI,   0x00);
    
    // Identify Command
    IoWrite8(ioaddr1 + PIO_CMD, 0xEC);
    
    // Статус устройства
    uint8_t stat = IoRead8(ioaddr1 + PIO_CMD);
    
    // ERR? Возможно, SATA
    if (stat & 0x01) {
        
        uint8_t cl = IoRead8(ioaddr1 + PIO_LBA_MID);
        uint8_t ch = IoRead8(ioaddr1 + PIO_LBA_HI);
        
        // SATA Device
        if (cl == 0x3C && ch == 0xC3) {
            return 4;
        }
    }
    
    // Устройства нет?
    if (stat == 0) {
        return 1;
    }
    
    // Ждать освобождения (BSY=0)
    i = 0; while (IoRead8(ioaddr1 + PIO_CMD) & 0x80) if (i++ > 2048) return 2;

    // DRQ=0x08 or ERR=0x01?
    i = 0; while ((IoRead8(ioaddr1 + PIO_CMD) & 0x09) == 0) if (i++ > 2048) return 3;
    
    // Читать данные в специальный сектор IDENTIFY
    IoReadSW(ioaddr1 + PIO_DATA_PORT, addr, 256);        
    
    return 0;
}

// Подготовка к чтению/записи из PIO48
uint8_t __pio_rw_prepare(uint8_t id, uint64_t lba, uint16_t num, uint8_t cmd) {
        
    uint16_t i;
    uint16_t ioaddr1 = 0x170 + ((id & 2) ? 0 : 0x80); // PRI=1F0h | SEC=170h
    uint16_t ioaddr2 = ioaddr1 | 0x200;               // PRI=3F0h | SEC=370h
    uint16_t slave   = id & 1;    
    uint8_t  state = 0, status;

    IoWrite8(ioaddr1 + PIO_DEVSEL,  0x40 | (slave << 4));   // Send 0x40 for the "master" or 0x50 for the "slave"
    IoWrite8(ioaddr1 + PIO_SECTORS, 0xff & (num >> 8));     // sectorcount high byte
    IoWrite8(ioaddr1 + PIO_LBA_LO,  0xff & (lba >> 24));    // LBA4
    IoWrite8(ioaddr1 + PIO_LBA_MID, 0xff & (lba >> 32));    // LBA5
    IoWrite8(ioaddr1 + PIO_LBA_HI,  0xff & (lba >> 40));    // LBA6
    IoWrite8(ioaddr1 + PIO_SECTORS, 0xff & num);
    IoWrite8(ioaddr1 + PIO_LBA_LO,  0xff & (lba));
    IoWrite8(ioaddr1 + PIO_LBA_MID, 0xff & (lba >> 8));
    IoWrite8(ioaddr1 + PIO_LBA_HI,  0xff & (lba >> 16));
    
    // 24h = READ SECTORS EXT
    // 34h = WRITE SECTORS EXT
    IoWrite8(ioaddr1 + PIO_CMD,     cmd);
    
    // 1. Попытка чтения с 1-го раза
    for (i = 0; i < 4; i++) {
        
        // BSY=0, DRQ=0? 
        if ((IoRead8(ioaddr1 + PIO_CMD) & 0x88) == 0x00) {
            
            state = 1;
            break;
        }        
    }
    
    // 2. Устройство ещё занято, ждём
    if (state == 0) {
        
        // Подождать, пока не будет BSY=0
        while (IoRead8(ioaddr1 + PIO_CMD) & 0x80);
        
        // ERR=0 и DF=0 ? Это хорошо
        if ((IoRead8(ioaddr1 + PIO_CMD) & 0x21) == 0x00) {
            state = 1;
        }        
    }
    
    // 3. Конечный статус
    return state ? 0 : 1;    
}

// Чтение сектора в PIO-режиме
// id - drive (0..3)
// lba - сектор, num - кол-во секторов, addr - адрес
// если ошибка - то возврат > 0, если успех - то 0
uint8_t pio_read_sector(uint8_t id, uint64_t lba, uint16_t num, uint64_t addr) {
    
    // Запись адреса, проверка готовности, отправка команды
    if (__pio_rw_prepare(id, lba, num, 0x24) == 0) {
    
        uint16_t i;
        uint16_t ioaddr_data = 0x170 + PIO_DATA_PORT + ((id & 2) ? 0 : 0x80); // PRI=1F0h | SEC=170h
        
        for (i = 0; i < num; i++) {
             
            IoReadSW(ioaddr_data, addr, 256);
            addr += 512;        
        }    
        
        return 0;    
    }

    return 1;
}
