/*  
 * master - dev0 | dev1
 * slave  - dev0 | dev1
 */
 
enum ATARegisters {
    
    ATA_REG_DATA        = 0,
    ATA_REG_ERR         = 1,
    ATA_REG_COUNT       = 2,
    ATA_REG_SEC_NUM     = 3,
    ATA_REG_LBA_LO      = 3,
    ATA_REG_LBA_MID     = 4, // 24 bit - 48 bit
    ATA_REG_LBA_HI      = 5,
    ATA_REG_DEVSEL      = 6,
    ATA_REG_LBA_CMD     = 7
};

enum DiskDev {
    
    DISK_DEV_UNKNOWN   = 0,
    DISK_DEV_PATAPI    = 1,
    DISK_DEV_SATAPI    = 2,
    DISK_DEV_PATA      = 3,
    DISK_DEV_SATA      = 4,
    DISK_DEV_FLOPPY    = 5
};

struct ATA_DEVICE {
    
    unsigned short    base;           // port base address
    unsigned short    dev_ctl;        // port for ctrl    
    unsigned short    start;          // start sector
    unsigned char     type;           // type of device
    unsigned char     identify[512];  // information about device    
};

struct ATA_DEVICE device_ata[4];

// ---------------------------------------------------------------------
// Protypes
// ---------------------------------------------------------------------

int     ata_soft_reset(int devctrl);
void    ata_drive_select(int slavebit, struct ATA_DEVICE* ctrl);
int     ata_detect_devtype(int slavebit, struct ATA_DEVICE* ctrl);
int     ata_identify(int device_id);
void    ata_prepare_lba(int device_id, unsigned int lba, int count, int command);
void    ata_pio_read(int base, unsigned char* address);
void    ata_pio_write(int base, unsigned char* address);
int     ata_read(unsigned char* address, int device_id, int lba, int count);
void    init_ata_devices();
