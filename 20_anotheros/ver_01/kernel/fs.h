
#define REG_DATA    0
#define REG_ERR     1
#define REG_COUNT   2

#define REG_SEC_NUM 3
#define REG_LBA_LO  3

#define REG_CYL_LO  4
#define REG_LBA_MID 4

#define REG_CYL_HI  5
#define REG_LBA_HI  5

#define REG_DEVSEL  6
#define REG_CMD     7

#define ATADEV_UNKNOWN      0
#define ATADEV_PATAPI       1
#define ATADEV_SATAPI       2
#define ATADEV_PATA         3
#define ATADEV_SATA         4

// Типы FS
#define FS_TYPE_FAT12       0x01
#define FS_TYPE_FAT16       0x06
#define FS_TYPE_FAT32       0x0B

// Атрибуты
#define ATTR_LONG_NAME		0x0F
#define ATTR_READ_ONLY		0x01
#define ATTR_HIDDEN			0x02
#define ATTR_SYSTEM			0x04
#define ATTR_VOLUME_ID		0x08
#define ATTR_DIRECTORY		0x10
#define ATTR_ARCHIVE		0x20

// Устройство ATA
struct DEVICE {

    uint16_t base;          // Базовый адрес
    uint16_t start;         // Стартовый сектор (0 или 1)
    uint16_t dev_ctl;       // Управляющий
    uint8_t  type;          // Тип девайса, например ATADEV_PATA
    uint8_t  identify[512]; // Информация от устройства
};

// Блок раздела
struct __attribute__((__packed__)) MBR_BLOCK {

    uint8_t   active;
    uint8_t   start_head;
    uint8_t   start_sector;
    uint8_t   start_cylinder;
    uint8_t   type;
    uint8_t   end_head;
    uint8_t   end_sector;
    uint8_t   end_cylinder;
    uint32_t  lba_start;
    uint32_t  lba_limit;
};

// https://ru.wikipedia.org/wiki/%D0%91%D0%BB%D0%BE%D0%BA_%D0%BF%D0%B0%D1%80%D0%B0%D0%BC%D0%B5%D1%82%D1%80%D0%BE%D0%B2_BIOS

// Крайне важно установить упакованные атрибуты здесь
struct __attribute__((__packed__)) BPB_331 {

    // BPB 2.0
    uint8_t   volume[8];            // 8: Метка диска
    uint16_t  bytes2sector;         // 2: 512
    uint8_t   cluster_size;         // 1: Логических секторов в кластере
    uint16_t  reserved_sector;      // 2: Зарезервированых секторов
    uint8_t   fat_count;            // 1: Количество таблиц FAT
    uint16_t  entry_root_num;       // 2: Количество элементов корневого каталога
    uint16_t  count_sectors;        // 2: Количество секторов
    uint8_t   media_type;           // 1: Тип носителя
    uint16_t  fat_sectors;          // 2: Логических секторов в FAT

    // BPB 3.3.1
    uint16_t  physical_sectors;     // Физические секторов на дорожке
    uint16_t  physical_heads;       // Количество головок
    uint32_t  hidden_sectors;       // Скрытых секторов
    uint32_t  total_sectors;        // Всего логических секторов
};

// FAT32 блок
struct __attribute__((__packed__)) BPB_71 {

    uint32_t  fat_sectors;
    uint8_t   flags1;
    uint8_t   flags2;
    uint16_t  version;
    uint32_t  root_dir;             // Корневой каталог в кластерах
    uint16_t  fsi;                  // Расположение FSI-структур
    uint16_t  reserved_sectors;     // Расположение резервных секторов
    uint8_t   reserved[12];         // Зарезервировано (имя файла загрузки)
    uint8_t   drive_num;            // Номер физического диска
    uint8_t   flags;
    uint8_t   extboot;
    uint32_t  volume;
    uint8_t   label[11];
    uint8_t   filetype[8];

};

// Блок файловой системы
struct FAT_BLOCK {

    uint8_t   fs_type;          // Тип файловой системы
    uint8_t   device_id;        // Где была найдена, device_id=[1..4] -- ATA, 0-не найдено
    uint32_t  lba_start;        // Стартовый сектор fs
    uint32_t  lba_limit;        // Длина раздела

    // Информация о FAT
    uint16_t  root_dirsec;      // Количество секторов в ROOT
    uint16_t  root_cluster;     // Кластер корневой директории FAT32
    uint16_t  cluster_size;     // Количество секторов в кластере
    uint32_t  data_start;       // Стартовый сектор данных
    uint32_t  data_sectors;     // Всего секторов в данных
    uint32_t  fat_start;        // Старт FAT
    uint32_t  fat_size;         // Размер FAT в секторах

    struct BPB_331 bpb331;
    struct BPB_71  bpb71;       // FAT32
    //struct BPB_40  bpb40;     // FAT12/16/HPFS -- пока нет у меня
};

// Структура одного элемента
struct __attribute__((__packed__)) FAT_ITEM {

    uint8_t   name[11];
    uint8_t   attr;
    uint8_t   ntres;            // Windows NT
    uint8_t   crttime_tenth;    // Счётчик десятков миллисекунд времени создания файла, значения 0-199
    uint16_t  crttime;          // Время создания файла с точностью до 2 секунд.

    uint16_t  crtdate;          // Дата создания файла.
    uint16_t  lstaccdate;       // Дата последнего доступа к файлу
    uint16_t  fstclushi;        // Номер первого кластера файла (HI)
    uint16_t  wrttime;          // Время последней записи в файл
    uint16_t  wrtdate;          // Дата последней записи в файл
    uint16_t  fstcluslo;        // Номер первого кластера файла (LO)
    uint32_t  filesize;         // Размер файла
};

// Текущий элемент каталога
struct FS_CURRENT {

    int       fs_id;                // Выбранная fatfs[ fs_id ]
    uint32_t  dir_root;             // Кластер с корневым каталогом
    uint32_t  dir;                  // Кластер текущей директории
    uint32_t  cur_cluster;          // Текущий просматриваемый кластер (позиция на диске)
    uint16_t  cur_item;             // Текущий просматриваемый элемент (в кластере, 0..n-1)
    uint16_t  cnt_item;             // Количество элементов в кластере
    uint8_t   filename[12];         // 8.3 запрошенное имя
    struct FAT_ITEM items[2048];    // Элементы кластера 2048 x 32 = 64Kb
};

// Открытый файл
struct File {

    int       fs_id;                // Указатель fatfs[ fs_id ]
    int       opened;               // Файл был открыт
    uint32_t  dir;                  // Указатель на директорию, откуда получен файл
    uint32_t  cluster_first;        // Стартовый кластер
    uint32_t  cluster_current;      // Текущий кластер
    uint32_t  seek;                 // Позиция курсора в файле
    uint32_t  seek_cl;              // Позиция курсора относительно кластера
    uint32_t  filesize;             // Размер файла
    struct FAT_ITEM file;           // Информация о файле
};

// ---------------------------------------

int fat_found;  // Количество найденных FAT

// Список драйвов
struct DEVICE     drive[4];  // 4 канала
struct FAT_BLOCK  fatfs[16]; // До 16 файловых систем на 4 разделах
struct FS_CURRENT fs;        // Текущий статус
