// https://wiki.osdev.org/ATA_PIO_Mode

// SRST
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

// Выбор устройства для работы
void drive_select(int slavebit, struct DEVICE* ctrl) {

    // Выбор устройства (primary | slave) | 0x40=Set LBA Bit
    IoWrite8(ctrl->base + REG_DEVSEL, 0xA0 | 0x40 | slavebit << 4);

    // Ожидать 400ns, пока драйв включится в работу
    IoRead8(ctrl->dev_ctl);
	IoRead8(ctrl->dev_ctl);
	IoRead8(ctrl->dev_ctl);
	IoRead8(ctrl->dev_ctl);
}

/* Primary bus:
 * ctrl->base    = 0x1F0
 * ctrl->dev_ctl = 0x3F6
 */
int detect_devtype(int slavebit, struct DEVICE* ctrl) {

    /* Ждать, пока девай будет готов */
    if (ata_soft_reset(ctrl->dev_ctl)) {
        return ATADEV_UNKNOWN;
    }

    // Выбор устройства (primary | slave)
    drive_select(slavebit, ctrl);

    // Получение битов сигнатуры
	unsigned cl = IoRead8(ctrl->base + REG_CYL_LO);
	unsigned ch = IoRead8(ctrl->base + REG_CYL_HI);

	// Различение ATA, ATAPI, SATA и SATAPI
	if (cl == 0x14 && ch == 0xEB) return ATADEV_PATAPI;
	if (cl == 0x69 && ch == 0x96) return ATADEV_SATAPI;
	if (cl == 0x00 && ch == 0x00) return ATADEV_PATA;
	if (cl == 0x3c && ch == 0xc3) return ATADEV_SATA;

	return ATADEV_UNKNOWN;
}

// Куда читать сектор
void drive_pio_read(int base, uint8_t* address) {

    __asm__ __volatile__("pushl %%ecx" ::: "ecx");
    __asm__ __volatile__("pushl %%edx" ::: "edx");
    __asm__ __volatile__("pushl %%edi" ::: "edi");
    __asm__ __volatile__("movl  $0x100, %%ecx" ::: "ecx");
    __asm__ __volatile__("movl  %0, %%edx" :: "r"(base) : "edx" );
    __asm__ __volatile__("movl  %0, %%edi" :: "r"(address) : "edi" );
    __asm__ __volatile__("rep   insw");
    __asm__ __volatile__("popl  %%edi" ::: "edi");
    __asm__ __volatile__("popl  %%edx" ::: "edx");
    __asm__ __volatile__("popl  %%ecx" ::: "ecx");
}

// id = [0..3], номер ata
int drive_identify(int id) {

    int i;

    // Не использовать идентификацию для нерабочего устройства
    if (drive[id].type == ATADEV_UNKNOWN)
        return 0;

    int slavebit = id & 1;
    struct DEVICE * ctrl = & drive[id];

    // Установить рабочий драйв
    drive_select(id & 1, & drive[id]);

    // Команда на считывание информации о диске
    IoWrite8(ctrl->base + REG_COUNT,   0x00);
    IoWrite8(ctrl->base + REG_LBA_LO,  0x00);
    IoWrite8(ctrl->base + REG_LBA_MID, 0x00);
    IoWrite8(ctrl->base + REG_LBA_HI,  0x00);

    // IDENTIFY
    IoWrite8(ctrl->base + REG_CMD,     0xEC);

    int w = IoRead8(ctrl->base + REG_CMD);

    // Ошибка драйва?
    if (w == 0) return 0;

    // Ожидание устройства
    for (i = 0; i < 4096; i++) {

        // Ждем BSY=0
        if ((IoRead8(ctrl->base + REG_CMD) & 0x80) == 0) {

            // Читаем 1 сектор в режиме PIO
            drive_pio_read(ctrl->base, ctrl->identify);

            // Определяем стартовый сектор #0
            drive[id].start = 0;

            return 1;
        }
    }

    return 0;
}

// Подготовка устройства к запросу на чтение или запись
// command = 0x24 READ; 0x34 WRITE
void drive_prepare_lba(int device_id, uint32_t lba, int count, int command) {

    int base   = drive[ device_id ].base;
    int devctl = drive[ device_id ].dev_ctl;

    // Коррекция
    lba += drive[ device_id ].start;

    // Выбор устройства (primary | slave) | 0x40=Set LBA Bit | LBA[27:24]
    IoWrite8(base + REG_DEVSEL, 0xA0 | 0x40 | (device_id & 1) << 4 | ((lba >> 24) & 0xF) );

    // Ожидать 400ns, пока драйв включится в работу
    IoRead8(devctl);
	IoRead8(devctl);
	IoRead8(devctl);
	IoRead8(devctl);

    // Старшие разряды
    IoWrite8(base + REG_COUNT,   (count >>  8) & 0xFF);
    IoWrite8(base + REG_LBA_LO,  (lba   >> 24) & 0xFF);
    IoWrite8(base + REG_LBA_MID, 0);
    IoWrite8(base + REG_LBA_HI,  0);

    // Младшие
    IoWrite8(base + REG_COUNT,   (count    ) & 0xFF);
    IoWrite8(base + REG_LBA_LO,  (lba      ) & 0xFF);
    IoWrite8(base + REG_LBA_MID, (lba >>  8) & 0xFF);
    IoWrite8(base + REG_LBA_HI,  (lba >> 16) & 0xFF);

    // Запрос чтения
    IoWrite8(base + REG_CMD, command);
}

// Чтение сектора с выбранного ATA
int drive_read_sectors(uint8_t* address, int device_id, int lba, int count) {

    int i;
    int base = drive[ device_id ].base;

    // Подготовить для чтения
    drive_prepare_lba(device_id, lba, count, 0x24);

    // Ждем BSY=0
    for (i = 0; i < 4096; i++)
    if ((IoRead8(base + REG_CMD) & 0x80) == 0) {

        // При DRQ=1, ERR=0, CORR=0, IDX=0, RDY=1, DF=0
        if ((IoRead8(base + REG_CMD) & 0x6F) == 0x48) {
            drive_pio_read(base, address);
            return 0;
        }
    }

    return 1;
}

// Определение FAT на устройстве
void fat_detect(int device_id) {

    int i, j;
    uint8_t sector[512];

    // Прочесть один сектор с диска для распознания MBR
    drive_read_sectors(sector, device_id, 0, 1);

    struct MBR_BLOCK* block = (struct MBR_BLOCK*)(sector + 0x1BE);
    struct FAT_BLOCK* fb;

    // Читаем MBR разделы
    for (i = 0; i < 4; i++) {

        switch (block[i].type) {

            case FS_TYPE_FAT12:
            case FS_TYPE_FAT16:
            case FS_TYPE_FAT32:

                fb = & fatfs[ fat_found ];

                fb->fs_type   = block[i].type;
                fb->device_id = device_id;
                fb->lba_start = block[i].lba_start;
                fb->lba_limit = block[i].lba_limit;

                // Дальнейшее сканирование сектора FAT
                drive_read_sectors(sector, device_id, fb->lba_start, 1);

                // Скопировать блок BPB2.0
                for (j = 0; j < sizeof(struct BPB_331); j++)
                    ((uint8_t*)&fb->bpb331)[j] = sector[0x03 + j];


                // Количество секторов
                fb->root_dirsec = (fb->bpb331.entry_root_num * 32) / fb->bpb331.bytes2sector;

                // Это FAT12/16 -- пока никак не обрабатываем
                if (fb->bpb331.entry_root_num) {

                    //total_sectors = fb->bpb331.count_sectors;
                }
                // Либо FAT32
                else {

                    // Скопировать блок BPB7.1
                    for (j = 0; j < sizeof(struct BPB_71); j++)
                        ((uint8_t*)&fb->bpb71)[j] = sector[0x24 + j];

                    // Общий размер FAT, кластеры и откуда fat начинается
                    fb->fat_size     = fb->bpb71.fat_sectors;
                    fb->cluster_size = fb->bpb331.cluster_size;
                    fb->fat_start    = fb->bpb331.reserved_sector;

                    // Начало данных
                    fb->data_start   = fb->bpb331.reserved_sector + (fb->bpb331.fat_count * fb->fat_size) + fb->root_dirsec;

                    // Количество секторов в данных
                    fb->data_sectors = fb->bpb331.total_sectors - fb->data_start;

                    // Корневой кластер
                    fb->root_cluster = fb->bpb71.root_dir;

                    fat_found++;
                }

                break;
        }
    }
}

// Найти ATA диски
void init_ata_drives() {

    fat_found = 0;

    int device_id;

    // Перечисление 4 типов шин
    for (device_id = 0; device_id < 4; device_id++) {

        // Определить тип устройства
        drive[device_id].base    = device_id < 2 ? 0x1F0 : 0x170;
        drive[device_id].dev_ctl = device_id < 2 ? 0x3F6 : 0x376;
        drive[device_id].type    = detect_devtype(device_id & 1, & drive[ device_id ]);

        // Устройство готов
        if (drive_identify(device_id)) {
            fat_detect(device_id);
        }
    }
}

// Загрузка кластера для `fs.cur_cluster`
void fs_update_cluster() {

    struct FAT_BLOCK* fb = & fatfs[ fs.fs_id ];

    // Найти данные
    uint32_t lba = fb->lba_start + fb->data_start + (fs.cur_cluster - 2) * fb->cluster_size;

    // Вычислить кол-во элементов в кластере
    fs.cnt_item = (fb->cluster_size<<4);

    // Загрузка кластера
    drive_read_sectors((uint8_t*)fs.items, fb->device_id, lba, fb->cluster_size);
}

// По текущему кластеру найти еще кластер FAT32
int fs_get_next_cluster32(uint32_t cluster) {

    uint32_t sector[128];

    struct FAT_BLOCK* fb = & fatfs[ fs.fs_id ];

    // 128 кластеров (4 байта на кластер) вмещается в сектор
    uint32_t lba = fb->lba_start + fb->fat_start + (fs.cur_cluster >> 7);

    // Загрузка сектора в память
    drive_read_sectors((uint8_t*)sector, fb->device_id, lba, 1);

    // Следующий кластер будет:
    return sector[ cluster & 0x7F ];
}

// Сброс в начало каталога
void fs_rewind() {

    // Не сбрасывать, есть равно
    if (fs.dir == fs.cur_cluster)
        return;

    fs.cur_cluster = fs.dir;
    fs.cur_item    = 0;
    fs_update_cluster();
}

// Открыть корневой каталог и установить его текущим,
// по номеру FS: fs_id = [0..15]
void fs_init(int fs_id) {

    fs.fs_id        = fs_id;    // Для запросов на девайс
    fs.dir_root     = fatfs[ fs_id ].root_cluster; // Установка корневого
    fs.dir          = fs.dir_root;      // Текущий каталог = корневой
    fs.cur_cluster  = 0;        // Текущий кластер = 0, чтобы потом перезагрузился
    fs_rewind();                // Перемотать на первый кластер, сектор и файл
}

// Переход к следующему элементу
// Если переход возможен, то ответ будет =1
int fs_next() {

    fs.cur_item++;

    // Найти следуюший кластер
    if (fs.cur_item >= fs.cnt_item) {

        // Получение нового кластера
        uint32_t nc = fs_get_next_cluster32(fs.cur_cluster);

        // Это был последний кластер, продолжения нет
        if (nc >= 0x0FFFFFF0) {
            return 0;

        } else {

            fs.cur_cluster = nc;
            fs.cur_item = 0;
            fs_update_cluster();
        }
    }

    return 1;
}

// Нормализовать к виду 8.3 имя файла
void fs_normalize(const char* name) {

    int i, c, o = 0;

    for (i = 0; i < 11; i++) fs.filename[i] = ' ';

    // Просмотр имени
    for (i = 0; i < 13; i++) {

        c = name[i];

        if (c == 0)
            return;

        // Перевод нижнего в верхний регистр
        if (c >= 'a' && c <= 'z')
            c -= 0x20;

        if (c == '.') {
            o = 8;

        } else {
            fs.filename[o] = c; o++;
        }
    }

    fs.filename[11] = 0;
}

// Сравнить имена 8.3 (11 символов)
int fs_cmpname83(char* s, char* d) {

    int i;
    for (i = 0; i < 11; i++) {

        if (s[i] != d[i]) {
            return 0;
        }
    }

    return 1;
}

// Найти файл в текущей директории
int fs_find(char* name) {

    int i;

    fs_normalize(name);     // Нормализовать для начала
    fs_rewind();            // Сброс на начало каталога

    do {

        struct FAT_ITEM* item = & fs.items[ fs.cur_item ];

        // Ничего не найдено
        if (item->name[0] == 0) {
            return 0;
        }

        // Сверить имя файла
        if (fs_cmpname83((char*)item->name, (char*)fs.filename)) {
            return 1 + fs.cur_item;
        }

    } while (fs_next());

    return 0;
}

// Получение кластера из FATITEM, file_id=0..n
int fs_get_cluster(file_id) {

    return (fs.items[ file_id ].fstclushi<<16) +
            fs.items[ file_id ].fstcluslo;
}

// Открыть новый дескриптор файла
// struct File fp = fopen("c:/wall/main.bmp");    
struct File fopen(const char* name) {

    struct File fp;

    char fn[256];
    int cursor = 0, cs = 0, file_id;

    // Инициализация
    bzero(&fp, sizeof(fp));

    // Запись указателя на корень
    fp.dir = fs.dir;

    trim(name, fn);
    strtoupper(fn);

    // Есть выбор номера диска
    if (strcmp(fn + 1, ":/") >= 0) {

        fp.fs_id = fn[0] - 'C';
        fs_init(fp.fs_id);
        cursor += 3;
    }

    // Искать либо "/", либо 0
    cs = cursor; while (fn[cursor]) {

        if (fn[cursor] == '/') {
            fn[cursor] = 0;

            // Файл или каталог был найден
            if ((file_id = fs_find(fn + cs))) {

                file_id--;

                // Если это директория, перемотать ее
                if (fs.items[file_id].attr & ATTR_DIRECTORY) {

                    fs.dir = fs_get_cluster(file_id);
                    fp.dir = fs.dir;
                    fs_rewind();
                }
            }
            // Если каталог не найден, это ошибка
            else {

                fp.opened = 0;
                return fp;
            }

            cs = cursor + 1;
        }

        cursor++;
    }

    // Найти файл и переписать его атрибуты
    if ((file_id = fs_find(fn + cs))) {
        
        file_id--;
        
        fp.cluster_first    = fs_get_cluster(file_id);
        fp.cluster_current  = fp.cluster_first;
        fp.file     = fs.items[ file_id ];
        fp.filesize = fp.file.filesize;
        fp.opened   = 1;
        fp.seek     = 0;
        fp.seek_cl  = 0;
    }

    return fp;
}
