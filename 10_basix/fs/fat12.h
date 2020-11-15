// Информация о файловой системе
#define FAT_SecInCluster        0x0D // 1 Секторов в кластере
#define FAT_ResvdSecCnt         0x0E // 1 Резервированных секторов перед FAT
#define FAT_NumFATs             0x10 // 1 Количество FAT
#define FAT_RootEntCnt          0x11 // 2 Количество записей в root (только fat12/16)
#define FAT_TotSec16            0x13 // 2 Количество секторов в целом (fat12/16)
#define FAT_FAT16sz             0x16 // 2 Размер FAT(16) в секторах
#define FAT_TotSec32            0x20 // 4 Количество секторов в целом (fat16/32)
#define FAT_FAT32sz             0x24 // 4 Размер FAT(32) в секторах
#define FAT_RootEnt_32          0x2C // 4 Номер кластера с Root Entries

// Типы устройств 
#define FAT12_DEVICE_FLOPPY     0
#define FAT12_DEVICE_ERR        0xFE
#define FAT12_DEVICE_RAM        0xFF

// Область памяти, откуда начинается виртуальный floppy-диск
#define INITRD_START        0x00200000

// Описатель дескриптора
struct FS_FAT12 {
    
    uint8_t     busy;                   // >0, открыт
    uint8_t     device_id;              // Номер устройства (0-Floppy, FE-error, FF-ram)
    uint16_t    cluster_dir;            // Указатель на текущую директорию
    uint16_t    cluster_current;        // Текущий кластер в файле
    uint8_t     per_cluster;            // Секторов на кластер
    uint32_t    file_size;              // Размер
    uint32_t    current;                // Текущая позиция в файле
    uint32_t    dir_entry;              // Точная позиция DIR_ENTRY найденного файла
    uint16_t    root_entries;           // Количество Root Entries
    uint8_t     valid;                  // Файл найден (=1)
    uint16_t    start_fat;              // Сектор начала FAT
    uint16_t    start_root;             // Сектор начала RootEntries
    uint16_t    start_data;             // Сектор начала DATA

};

// Описатели дескрипторов
struct FS_FAT12 fat12_desc[ VFS_MAX_FILES ];

// Одна файловая запись (11 байт = 8 + 3)
uint8_t FAT12_ITEM[11];

// ---------------------------------------------------------------------
// Обработчики
// ---------------------------------------------------------------------

#include "fat12/search.c"
#include "fat12/open.c"
#include "fat12/read.c"
