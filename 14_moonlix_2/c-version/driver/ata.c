// http://wiki.osdev.org/ATA_PIO_Mode
// http://wiki.osdev.org/ATA/ATAPI_using_DMA

#include <stdint.h>
#include "h/ata.h"
#include "../headers/memory.h"

#define BRK asm("xchg bx,bx");

// Структуры дисков
struct DEVICE disks[8] = { 

    // ata-0
    {0x1F0, 0, 0x3F6, 0, 0},
    {0x1F0, 1, 0x3F6, 0, 0}, 

    // ata-1
    {0x170, 0, 0x376, 0, 0},
    {0x170, 1, 0x376, 0, 0},

    // ata-2
    {0x1E0, 0, 0x3E6, 0, 0},
    {0x1E0, 1, 0x3E6, 0, 0},

    // ata-3
    {0x160, 0, 0x1F6, 0, 0}, 
    {0x160, 1, 0x1F6, 0, 0},
};

// Чтение с диска с учетом смещения (алиас от pio_ata_read)
void ata_read(int disk, uint32_t lba, int sectors) {    
    pio_ata_rw(disk, lba + disks[disk].lba_start, sectors, 0); // 0 = read
}

// Инициализация жестких дисков
// --------------------------------------------------------
void drive_initialize()
{
    int i, j, c;

    uint32_t t, float_part;

    for (i = 0; i < 8; i++) 
    {
        disks[i].type = detect_devtype(&disks[i]);

        // Чтение байт 512 байт данных
        if (disks[i].type != ATADEV_UNKNOWN) {

            // Чтение параметров диска
            outsw_512(i, disks[i].base);

            // Определить возможность читать с 0 LBA
            if (disks[i].type == ATADEV_PATA) 
            {   
                // Чтение 0-го сектора
                c = pio_ata_rw(i, 0, 1, 0);

                // Если не удалось прочитать 0-й сектор, то тогда чтение будет с 1-го
                disks[i].lba_start = (c == 0) ? 1 : 0;

                // Чтение первого сектора и разбор информации о разделах  
                ata_read(i, 0, 1);

                // Разбор инфомации о разделах
                for (j = 0; j < 4; j++) {

                    float_part = PARTITIONS_DATA + j*16 + i*64;

                    // Записать начало раздела
                    write(float_part,      read(ATA_BUFFER  + 0x1be + j*0x10 + 8));  // lba_start
                    write(float_part + 4,  read(ATA_BUFFER  + 0x1be + j*0x10 + 12)); // lba size
                    write(float_part + 8,  readb(ATA_BUFFER + 0x1be + j*0x10 + 4));  // fs type
                    write(float_part + 12, readb(ATA_BUFFER + 0x1be + j*0x10 + 0));  // bootable?
                }
            }
        }
    }
}

// Определение типа диска по запросу IDENTIFY на диск
// --------------------------------------------------------
int detect_devtype(struct DEVICE *ctrl)
{
    char cl, ch, st;

    int poll = 262144;
    int slavebit = ctrl->slavebit;
    int status   = ctrl->base + REG_CMD_STATUS;

    outb(ctrl->base + REG_DEVSEL, 0xA0 | ((slavebit & 1) << 4)); // Номер драйва

    // Обязательно заполнить данные о кол-ве сеекторов = 0
    outb(ctrl->base + REG_SECT_COUNT, 0);
    outb(ctrl->base + REG_LBA_LO,     0);
    outb(ctrl->base + REG_LBA_MID,    0); // 4
    outb(ctrl->base + REG_LBA_HI,     0); // 5

    // Отсылка команды IDENTIFY
    outb(status, 0xEC);

    // Драйв не существует, если 0 в статусе
    if (inb(status) == 0) {
        return ATADEV_UNKNOWN;
    }

    // Ожидание освобождения устройства в течении некоторого времени
    while (poll > 0) {

        st = inb(status);

        cl = inb(ctrl->base + REG_LBA_MID);
        ch = inb(ctrl->base + REG_LBA_HI);

        // Есть определенные типы устройств
        if (cl == 0x14 && ch == 0xEB) return ATADEV_PATAPI;
        if (cl == 0x69 && ch == 0x96) return ATADEV_SATAPI;        
        if (cl == 0x3c && ch == 0xc3) return ATADEV_SATA;

        // Статусы
        if (!(st & 0x80)) break;              // BSY=0 Устройство освободилось 
        if (st & 0x08) break;                 // DRQ=1 Устройство готово принять данные)
        if (st & 0x01) return ATADEV_UNKNOWN; // ERR=1 Ошибка устройства

        poll--;
    }

    // Устройство недоступно
    if (!poll) {
        return ATADEV_UNKNOWN;
    }

    // Точно ли это жесткий диск?
    if (cl == 0 && ch == 0) {        
        return ATADEV_PATA;
    }

    return ATADEV_UNKNOWN;    
}

// conf = 0 (disk type)
// =1 base addr
// =2 lba offset
uint32_t get_disk_info(int disk, int conf) {

    struct DEVICE* dev = &disks[disk];

    switch (conf)
    {
        case 0: return dev->type;
        case 1: return dev->base;
        case 2: return dev->lba_start;
    }
    
    return 0;
}

// Чтение/Запись на диск
// ----
// device_id = 0..7
// lba=1...n (начинается всегда с 1)
// sectors = кол-во секторов
// type = 0 (чтение), 1 (запись) в буфер
// ----
int pio_ata_rw(int disk, uint32_t lba, uint32_t sectors, int type) {

    char st, poll = 4, i, k;

    int base   = disks[disk].base;
    int status = disks[disk].base + 7;

    // Адресация до 2 Тб жесткий диск
    outb (base + 2, (sectors & 0xff00) >> 8);
    outb (base + 3, (lba >> 24) & 0xff); 
    outb (base + 4, 0);             // lba5 = 0
    outb (base + 5, 0);             // lba6 = 0

    outb (base + 2, sectors & 0xff);
    outb (base + 3, lba & 0xff);         // lba1
    outb (base + 4, (lba >> 8) & 0xff);  // lba2
    outb (base + 5, (lba >> 16) & 0xff); // lba3

    int slavebit = disks[disk].slavebit;
    outb(base + 6, 0xA0 | ((slavebit & 1) << 4)); // Номер драйва

    // Отослать команду "read ext"
    outb(status, 0x24);

    // 400 ns задержка
    while (poll > 0)
    {
        int st = inb(status);
        if (!(st & 0x80)) break;
        if (st & 0x08) break;

        poll--;
    }

    for (k = 0; k < sectors; k++)
    {
        // Все еще не получены данные?
        if (poll == 0) 
        {
            while (1)
            {
                st = inb(status);
                if (!(st & 0x80)) break;
                if (st & 0x21) return 0; // Ошибка - ни одного сектора не получено                             
            }        
        }

        // Чтобы прочитать следующий сектор
        poll = 0;

        // Если DRQ=0, значит, команда оборвана
        st = inb(status);
        if (!(st & 0x08)) return 0;

        // Записываем данные
        outsw_data(base, k);

        // 400 ns задержка
        for (i = 0; i < 4; i++) inb(status);        
    }    

    return sectors;
}
