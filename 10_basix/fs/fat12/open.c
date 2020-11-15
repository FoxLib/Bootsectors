/*
 * Поиск и открытие виртуального файла
 */

uint32_t fs_fat12_open(const char* filename) {

    int i;
    int file_id = 0;    

    // Поиск свободного дескриптора
    for (i = 1; i < VFS_MAX_FILES; i++) {

        if (fat12_desc[i].busy == 0) {

            file_id = i;
            break;
        }
    }

    // Найти запрошенную директорию
    if (file_id && *filename) {

        // Не реализованы другие варианты
        if (fat12_desc[ file_id ].device_id != FAT12_DEVICE_RAM) {
            return -1;
        }

        // Расчет параметров диска FAT12
        uint8_t  start_fat  = mm_readb(INITRD_START + FAT_ResvdSecCnt);
        uint8_t  start_root = start_fat   + mm_readb(INITRD_START + FAT_NumFATs) * mm_readw(INITRD_START + FAT_FAT16sz);
        uint16_t start_data = start_root + (mm_readw(INITRD_START + FAT_RootEntCnt) >> 4);

        // Инициализация
        fat12_desc[ file_id ].start_fat = start_fat;
        fat12_desc[ file_id ].start_root = start_root;
        fat12_desc[ file_id ].start_data = start_data;
        fat12_desc[ file_id ].root_entries = mm_readw(INITRD_START + FAT_RootEntCnt);
        fat12_desc[ file_id ].per_cluster = mm_readb(INITRD_START + FAT_SecInCluster);
        fat12_desc[ file_id ].dir_entry = 0;
        fat12_desc[ file_id ].current = 0;
        fat12_desc[ file_id ].file_size = 0;
        fat12_desc[ file_id ].cluster_current = 0;
        fat12_desc[ file_id ].cluster_dir = 0;
        fat12_desc[ file_id ].valid = 0;
        
        // Найти файл
        fs_fat12_search(file_id, filename);     
        
        // Файл не открыт, не найден
        if (fat12_desc[ file_id ].valid == 0) {
            return 0;
        }   
        
        // Текущий кластер файла == найденному последнему файлу
        fat12_desc[ file_id ].cluster_current = fat12_desc[ file_id ].cluster_dir;
        fat12_desc[ file_id ].busy = 1;
    }

    return file_id;
}

// Закрыть дескриптор
void fs_fat12_close(int file_id) {

    fat12_desc[ file_id ].busy = 0;
}
