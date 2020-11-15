/** ШИНЫ
 ------------------
 * 00-03 ATA
 * 04-05 FLOPPY
 * 08-FF PCI
 ------------------
 */

// Для доступа к I/O ATA
#define ATA_REG_DATA    0
#define ATA_REG_ERR     1
#define ATA_REG_COUNT   2
#define ATA_REG_SEC_NUM 3
#define ATA_REG_LBA_LO  3
#define ATA_REG_LBA_MID 4
#define ATA_REG_LBA_HI  5
#define ATA_REG_DEVSEL  6
#define ATA_REG_CMD     7

// Тип устройства
#define DISK_DEV_UNKNOWN      0
#define DISK_DEV_PATAPI       1
#define DISK_DEV_SATAPI       2
#define DISK_DEV_PATA         3
#define DISK_DEV_SATA         4
#define DISK_DEV_FLOPPY       5

enum FloppyRegisters {

    STATUS_REGISTER_A                = 0x3F0, // read-only
    STATUS_REGISTER_B                = 0x3F1, // read-only
    DIGITAL_OUTPUT_REGISTER          = 0x3F2,
    TAPE_DRIVE_REGISTER              = 0x3F3,
    MAIN_STATUS_REGISTER             = 0x3F4, // read-only
    DATARATE_SELECT_REGISTER         = 0x3F4, // write-only
    DATA_FIFO                        = 0x3F5,
    DIGITAL_INPUT_REGISTER           = 0x3F7, // read-only
    CONFIGURATION_CONTROL_REGISTER   = 0x3F7  // write-only
};

enum FloppyStatus {

    FDC_STATUS_NONE     = 0x0,
    FDC_STATUS_SEEK     = 0x1,
    FDC_STATUS_RW       = 0x2,
    FDC_STATUS_SENSEI   = 0x3,
};

enum FloppyCommands {

    READ_TRACK =                 2,  // generates IRQ6
    SPECIFY =                    3,  // * set drive parameters
    SENSE_DRIVE_STATUS =         4,
    WRITE_DATA =                 5,  // * write to the disk
    READ_DATA =                  6,  // * read from the disk
    RECALIBRATE =                7,  // * seek to cylinder 0
    SENSE_INTERRUPT =            8,  // * ack IRQ6, get status of last command
    WRITE_DELETED_DATA =         9,
    READ_ID =                    10, // generates IRQ6
    READ_DELETED_DATA =          12,
    FORMAT_TRACK =               13, // *
    DUMPREG =                    14,
    SEEK =                       15, // * seek both heads to cylinder X
    VERSION =                    16, // * used during initialization, once
    SCAN_EQUAL =                 17,
    PERPENDICULAR_MODE =         18, // * used during initialization, once, maybe
    CONFIGURE =                  19, // * set controller parameters
    LOCK =                       20, // * protect controller params from a reset
    VERIFY =                     22,
    SCAN_LOW_OR_EQUAL =          25,
    SCAN_HIGH_OR_EQUAL =         29
};

// Устройство ATA
struct ATA_DEVICE {

    word base;          // Базовый адрес
    word start;         // Стартовый сектор (0 или 1)
    word dev_ctl;       // Управляющий
    byte type;          // Тип девайса, например ATADEV_PATA
    byte identify[512]; // Информация от устройства
};

// Информация о FDC
struct FDC_DEVICE {
    
    // Параметры
    byte    enabled;            // Устройство присутствует
    byte    motor;              // Мотор включен
    dword   timem;              // Время включения мотора
    
    // Запрошенные параметры CHS
    byte    r_cyl;
    byte    r_head;
    byte    r_sec;

    // Результат
    byte    st0;
    byte    st1;
    byte    st2;
    byte    cyl;
    byte    head_end;
    byte    head_start;
    byte    error;

    // Для IRQ
    byte    status;
    volatile byte irq_ready;
};

struct ATA_DEVICE ata_drive[4];  // 4 канала
struct FDC_DEVICE fdc;
