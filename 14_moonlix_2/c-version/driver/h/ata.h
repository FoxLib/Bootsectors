// Структура регистров ATA
#define REG_DATA           0 // Data port
#define REG_FEATURES       1 // Usually used for ATAPI devices.
#define REG_SECT_COUNT     2 // Number of sectors to read/write (0 is a special value).
#define REG_LBA_LO         3 // LBAlo
#define REG_LBA_MID        4 // LBAmid
#define REG_LBA_HI         5 // LBAhi
#define REG_DEVSEL         6 // Drive 
#define REG_CMD_STATUS     7 // Command port / Regular Status port

#define ATADEV_PATA    1
#define ATADEV_PATAPI  2
#define ATADEV_SATA    3
#define ATADEV_SATAPI  4
#define ATADEV_UNKNOWN 0xff

struct DEVICE {
    int base;
    int slavebit;
    int dev_ctl;   
    int type;      // Тип устройства
    int lba_start; // Откуда начинается LBA=0/1?
};

struct PARTITION_DISK
{
    uint32_t lba_start; // Начало (+0)
    uint32_t lba_size;  // Размер диска (+4)
    int      fs_type;   // Тип ФС (+8)
};