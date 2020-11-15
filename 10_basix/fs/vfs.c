#include "vfs.h"
#include "fat12.h"

/*
 * Инициализация файловых дескрипторов в NULL
 */

void fs_init() {
    
    int i;
    
    // Размаппить на RAM-диск, т.к. реального диска все равно не будет
    for (i = 0; i < VFS_MAX_FILES; i++) { 
               
        fat12_desc[i].busy = 0;
        
        // Указатель на ROOT-директорию
        fat12_desc[i].cluster_dir = 0;
        
        // Все FAT12 находятся в RAM
        fat12_desc[i].device_id = FAT12_DEVICE_RAM;
    }    
    
}

/*
 * Открытие файла из VFS
 */
 
uint32_t fopen(const char* filename) {
    
    // Пока что только из FAT12
    return fs_fat12_open(filename);
    
}

/*
 * Чтение файла или его части из VFS
 */
 
uint32_t fread(void* ptr, uint32_t size, uint32_t file_id) {
    
    // Пока что только FAT12
    return fs_fat12_read((uint32_t)ptr, size, file_id);    
}

/*
 * Закрытие файла
 */
 
void fclose(file_id) {
    
    // Пока что только FAT12
    if (file_id) {        
        fs_fat12_close(file_id);
    }
    
}

/*
 * Получить размер файла из его описателя
 */

uint32_t fsize(int file_id) {
    
    return fat12_desc[ file_id ].file_size;
}
