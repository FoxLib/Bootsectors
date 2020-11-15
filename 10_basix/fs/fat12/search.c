// Фактически, открытие файла
void fs_fat12_setcurrent(int file_id, uint32_t rootdir) {
    
    // Запись текущей позиции (от начала диска)
    fat12_desc[ file_id ].dir_entry = rootdir - INITRD_START;
    
    // Неважно, директория это или файл - одинаковое значение кластера
    fat12_desc[ file_id ].cluster_dir = mm_readw(rootdir + 0x1A);
    fat12_desc[ file_id ].file_size = mm_readd(rootdir + 0x1C);
}

// Найти файл в текущей директории
int fs_fat12_find(int file_id) {
    
    int id, k;

    // Поиск файла производится в главной директории (после FAT)
    if (fat12_desc[ file_id ].cluster_dir == 0) {
        
        // Точка входа в директорию
        uint32_t rootdir = INITRD_START + fat12_desc[ file_id ].start_root * 512;

        // Пройтись по всем записям
        for (id = 0; id < fat12_desc[ file_id ].root_entries; id++) {
            
            int found = 1;
            
            // Тест на полное совпадение запрошенного имени
            for (k = 0; k < 11; k++) {                
                if (mm_readb(rootdir + id*32 + k) != FAT12_ITEM[k]) {
                    found = 0;
                    break;
                }                
            }

            if (found) {

                fs_fat12_setcurrent(file_id, rootdir + id*32);
                return 1;
            }
        }
        
    // Либо ищется по кластерам
    } else {

        uint16_t cluster = fat12_desc[ file_id ].cluster_dir;
        uint16_t per_cluster = fat12_desc[ file_id ].per_cluster;
        uint32_t rootdir;
        
        for (;;) {
            
            rootdir = INITRD_START + (fat12_desc[ file_id ].start_data + cluster - 2) * (per_cluster * 512);
            
            // Просмотр кластеров
            for (id = 0; id < 16 * per_cluster; id++) {
                
                int found = 1;
                for (k = 0; k < 11; k++) {                
                    if (mm_readb(rootdir + id*32 + k) != FAT12_ITEM[ k ]) {
                        found = 0;
                        break;
                    }                
                }
                
                if (found) {

                    fs_fat12_setcurrent(file_id, rootdir + id*32);
                    return 1;
                }            
            }
            
            // Получить следующий кластер
            rootdir = INITRD_START + 512 * fat12_desc[ file_id ].start_fat + ((3*cluster)>>1);        
            cluster = cluster % 2 ? mm_readw(rootdir) >> 4 : mm_readw(rootdir) & 0xfff;

            // Последний кластер
            if (cluster >= 0x0FF0) {
                break;
            }
        }
        
    }
    
    return 0;
}

// Поиск части файла
uint8_t fs_fat12_part(int file_id, const char* filename) {
    
    int i;

    uint8_t fn_pos;
    uint8_t count = 0;
    uint8_t ltrim;
    char*   name = (char*)filename;

    // Подготовка
    for (i = 0; i < 11; i++) {
        FAT12_ITEM[i] = ' ';
    }
    
    ltrim = 1;
    fn_pos = 0;

    // Перевод в правильный вид
    for (;;) {

        char one_char = *name; name++;

        if (one_char) {

            // LTRIM
            if (one_char == ' ' && ltrim) {
                continue;
            } else {            
                ltrim = 0;
            }

            // Достигнуто окончание имени файла
            if (one_char == '/') {

                // Сброс директории
                if (count == 0) {
                    
                    fat12_desc[ file_id ].cluster_dir = 0;
                    return 1;
                    
                } else {
                    return fs_fat12_find(file_id) ? 1 + count : 0;
                }

            }
            // Определен разделитель имени файла и расширения
            else if (one_char == '.' && fn_pos < 8) {
                fn_pos = 8;

            }
            // Размер не должен быть превышен у имени файла
            else if (fn_pos < 11) {

                one_char = one_char >= 'a' && one_char <= 'z' ? one_char - 0x20 : one_char;
                FAT12_ITEM[fn_pos] = one_char;
                
                fn_pos++;
                count++;
            }

        // Достигнут конец строки (это файл)
        } else {
 
            if (fs_fat12_find(file_id)) {
                fat12_desc[ file_id ].valid = 1;
            }

            return 0;
        } 
    }
    
    return 0;
}


// Поиск конечного пути, из открытого дескриптора [file_id]
uint8_t fs_fat12_search(int file_id, const char* filename) {

//brk;    

    uint16_t idx = 0;
    
    for (;;) {
        
        uint8_t count = fs_fat12_part(file_id, filename + idx);
        
        if (count == 0) {
            break;
        }
        
        idx += count;    
    }
    
    return 0;
}
