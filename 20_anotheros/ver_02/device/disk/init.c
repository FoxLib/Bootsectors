#include "ata.c"
#include "floppy.c"

// Получение типа диска
int disk_get_type(byte disk_id) {

    switch (disk_id) {

        case 0: /* ata bus pri master */
        case 1: /* ata bus pri slave */
        case 2: /* ata bus sec master */
        case 3: /* ata bus sec slave */
            return ata_drive[ disk_id ].type;

        case 4: /* fd 0: primary */
        case 5: /* fd 1: fail */
        case 6: /* fd 2: fail */
        case 7: /* fd 3: fail */
            return fdc.enabled ? DISK_DEV_FLOPPY : DISK_DEV_UNKNOWN;
    }

    return DISK_DEV_UNKNOWN;
}

// Инициализация дисковой подсистемы
void init_disk() {

    int device_id;

    // Диск выключен
    fdc.status      = FDC_STATUS_NONE;
    fdc.irq_ready   = 0;
    fdc.enabled     = 0;
    fdc.motor       = 0;

    // Назначить методы
    pic.fdc = & fdc_irq;

    // Прототипы
    disk.get_type = & disk_get_type;

    // Подготовка DMA
    fdc_dma_init();
    
    // Проверить наличие FD

    // Просмотр всех ATA-устройств
    for (device_id = 0; device_id < 4; device_id++) {

        // Определить тип устройства
        ata_drive[ device_id ].base    = device_id < 2 ? 0x1F0 : 0x170;
        ata_drive[ device_id ].dev_ctl = device_id < 2 ? 0x3F6 : 0x376;
        ata_drive[ device_id ].type    = ata_detect_devtype(device_id & 1, & ata_drive[ device_id ]);

        // Если устройство не готово
        if (!ata_identify(device_id)) {
            ata_drive[ device_id ].type = DISK_DEV_UNKNOWN;
        }
    }
}
