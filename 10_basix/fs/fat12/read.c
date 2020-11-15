/*
 * Последовательное скачивание файла по кластерам
 */

uint32_t fs_fat12_read(uint32_t addr, uint32_t size, int file_id) {
    
    struct FS_FAT12* file = & fat12_desc[ file_id ];

    uint32_t fetched = 0;
    uint32_t i;    
    uint16_t cluster = file->cluster_current;    
    uint16_t cluster_size = (512 * file->per_cluster);    
    uint32_t cluster_start = INITRD_START + 512 * file->start_data + (cluster - 2) * cluster_size;
    uint16_t cursor_in;
    uint32_t rootdir;
    
    if (cluster >= 0x0FF0) {
        return 0;
    }

    for (i = 0; i < size; i++) {
        
         cursor_in = file->current % cluster_size;
         mm_writeb(addr, mm_readb(cluster_start + cursor_in));
         
         addr++;
         fetched++;
             
         // К следующему кластеру (если есть)
         if (cursor_in == cluster_size - 1) {

            rootdir = INITRD_START + 512 * file->start_fat + ((3 * cluster) >> 1);        
            cluster = cluster % 2 ? mm_readw(rootdir) >> 4 : mm_readw(rootdir) & 0xfff;

            file->cluster_current = cluster;            
            cluster_start = INITRD_START + 512 * file->start_data + (cluster - 2) * cluster_size;

            // Обнаружен реальный конец файла, загрузка более невозможна
            if (cluster >= 0x0FF0) {
                break;
            }
         }
         
         file->current += 1;
         
         // Обнаружен конец файла
         // Запрошенное кол-во байт не будет скачано
         if (file->current >= file->file_size) {
             break;
         }
    }
    
    return fetched;
}

/*
 * Загрузка файла целиком в память с выделением новой памяти
 */
 
uint32_t fs_fat12_load(uint16_t file_id) {
    
    uint32_t size = fat12_desc[ file_id ].file_size;
    
    // Не давать скачать еще, если файл закончен
    if (fat12_desc[ file_id ].current + size > fat12_desc[ file_id ].file_size) {
        return 0;
    }

    // Выделить пространство
    uint32_t addr = kalloc(size);

    // Загрузка файла в память
    if (addr) {        
        fs_fat12_read(addr, size, file_id);    
    }

    return addr;
}
