#include "io.h"
#include "ata.h"

int ata_soft_reset(int devctl) {

    int i;

    IoWrite8(devctl, 4);
    IoWrite8(devctl, 0);

    // 400 ns
    IoRead8(devctl);
    IoRead8(devctl);
    IoRead8(devctl);
    IoRead8(devctl);

    for (i = 0; i < 4096; i++) {
        if ((IoRead8(devctl) & 0xC0) == 0x40) {
            return 0;
        }
    }

    return 1;
}

void ata_drive_select(int slavebit, struct ATA_DEVICE* ctrl) {

    // Send command for init (LBA | Select m/s)
    IoWrite8(ctrl->base + ATA_REG_DEVSEL, 0xA0 | 0x40 | slavebit << 4);

    // 400 ns
    IoRead8(ctrl->dev_ctl);
    IoRead8(ctrl->dev_ctl);
    IoRead8(ctrl->dev_ctl);
    IoRead8(ctrl->dev_ctl);
}

int ata_detect_devtype(int slavebit, struct ATA_DEVICE* ctrl) {

    if (ata_soft_reset(ctrl->dev_ctl)) {
        return DISK_DEV_UNKNOWN;
    }

    ata_drive_select(slavebit, ctrl);

    byte cl = IoRead8(ctrl->base + ATA_REG_LBA_MID);
    byte ch = IoRead8(ctrl->base + ATA_REG_LBA_HI);

    switch ((ch<<8) + cl) {

        case 0x0000: return DISK_DEV_PATA;
        case 0xc33c: return DISK_DEV_SATA;
        case 0xeb14: return DISK_DEV_PATAPI;
        case 0x9669: return DISK_DEV_SATAPI;
    }

    return DISK_DEV_UNKNOWN;
}

void ata_prepare_lba(int device_id, uint32_t lba, int count, int command) {

    int base   = device_ata[ device_id ].base;
    int devctl = device_ata[ device_id ].dev_ctl;

    lba += device_ata[ device_id ].start;

    IoWrite8(base + ATA_REG_DEVSEL, 0xA0 | 0x40 | (device_id & 1) << 4 | ((lba >> 24) & 0x0F));

    // 400 ns
    IoRead8(devctl);
    IoRead8(devctl);
    IoRead8(devctl);
    IoRead8(devctl);

    // 2^48
    IoWrite8(base + ATA_REG_COUNT,   (count >> 8) & 0xff);
    IoWrite8(base + ATA_REG_LBA_LO,  (lba >> 24)  & 0xff);
    IoWrite8(base + ATA_REG_LBA_MID, 0);
    IoWrite8(base + ATA_REG_LBA_HI,  0);

    IoWrite8(base + ATA_REG_COUNT,   (count     ) & 0xff);
    IoWrite8(base + ATA_REG_LBA_LO,  (lba)        & 0xff);
    IoWrite8(base + ATA_REG_LBA_MID, (lba >> 8)   & 0xff);
    IoWrite8(base + ATA_REG_LBA_HI,  (lba >> 16)  & 0xff);

    IoWrite8(base + ATA_REG_LBA_CMD, command);
}

void ata_pio_read(int base, byte* address) {

    asm volatile ("pushl %%ecx" ::: "ecx");
    asm volatile ("pushl %%edx" ::: "edx");
    asm volatile ("pushl %%edi" ::: "edi");

    asm volatile ("movl  %0, %%edi" :: "r"(address));
    asm volatile ("movl  %0, %%edx" :: "r"(base));
    asm volatile ("movl  $0x100, %%ecx" ::: "ecx");
    asm volatile ("rep   insw");

    asm volatile ("popl  %%edi" ::: "edi");
    asm volatile ("popl  %%edx" ::: "edx");
    asm volatile ("popl  %%ecx" ::: "ecx");
}

void ata_pio_write(int base, byte* address) {

    asm volatile ("pushl %%ecx" ::: "ecx");
    asm volatile ("pushl %%edx" ::: "edx");
    asm volatile ("pushl %%esi" ::: "esi");

    asm volatile ("movl  %0, %%esi" :: "r"(address));
    asm volatile ("movl  %0, %%edx" :: "r"(base));
    asm volatile ("movl  $0x100, %%ecx" ::: "ecx");
    asm volatile ("rep   outsw");

    asm volatile ("popl  %%esi" ::: "esi");
    asm volatile ("popl  %%edx" ::: "edx");
    asm volatile ("popl  %%ecx" ::: "ecx");
}

int ata_identify(int device_id) {

    int i;

    if (device_ata[ device_id ].type == DISK_DEV_UNKNOWN) {
        return 0;
    }

    int slavebit = device_id & 1;

    struct ATA_DEVICE* ctl = & device_ata[ device_id ];

    ata_drive_select(slavebit, ctl);

    IoWrite8(ctl->base + ATA_REG_COUNT,   0);
    IoWrite8(ctl->base + ATA_REG_LBA_LO,  0);
    IoWrite8(ctl->base + ATA_REG_LBA_MID, 0);
    IoWrite8(ctl->base + ATA_REG_LBA_HI,  0);

    // Identify
    IoWrite8(ctl->base + ATA_REG_LBA_CMD, 0xEC);

    int w = IoRead8(ctl->base + ATA_REG_LBA_CMD);
    if (w == 0) return 0;

    for (i = 0; i < 4096; i++) {

        if ((IoRead8(ctl->base + ATA_REG_LBA_CMD) & 0x80) == 0) {

            ata_pio_read(ctl->base, ctl->identify);
            return 0;
        }
    }

    return 1;
}

int ata_read(byte* address, int device_id, int lba, int count) {

    int i;
    int base = device_ata[ device_id ].base;
    int cmd  = base + ATA_REG_LBA_CMD;

    ata_prepare_lba(device_id, lba, count, 0x24);

    for (i = 0; i < 4096; i++) {

        // BSY=0
        if ((IoRead8(cmd) & 0x80) == 0) {

            // DRQ=1, ERR=0, CORR=0, IDX=0, RDY=1, DF=0
            if ((IoRead8(cmd) & 0x6F) == 0x48) {

                ata_pio_read(base, address);
                return 0;
            }
        }
    }

    return 1;
}

void init_ata_devices() {

    int devid;
    for (devid = 0; devid < 4; devid++) {

        device_ata[devid].base    = devid < 2 ? 0x1F0 : 0x170;
        device_ata[devid].dev_ctl = devid < 2 ? 0x3F6 : 0x376;
        device_ata[devid].start   = 0;
        device_ata[devid].type    = ata_detect_devtype(devid & 1, & device_ata[ devid ]);
    }
}
