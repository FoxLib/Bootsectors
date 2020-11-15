// Процедура очистки FloppyDisk от лишнего мусора для лучшей компрессии
// gcc cleandisk.c -o cleandisk && ./cleandisk

/*
 * 0200h 1-й сектор FAT (18 секторов)
 * 2600h 19-й сектор начало RootEntries (224 записи, 14 секторов)
 * 4200h 33-й сектор начало данных (2847 секторов = 2880 - 18 - 14 - 1)
 */

#include <stdlib.h>
#include <stdio.h>

int main() {
    
    unsigned char fatbuffer[1024];
    unsigned char onesector[512];

    FILE* floppy = fopen("initrd.img", "rb+");
    printf("Start cleaning floopy...\n");
    
    int j;
    int fatsector = -1;   
    int cluster_id;
    
    // Всего на диске максимум
    for (cluster_id = 0; cluster_id < 2847; cluster_id++) { 
        
        // Номе байта в FAT
        int fb = (3 * cluster_id) >> 1;
        int fs = fb >> 9;
        int fn = fb % 512;
        int clid;
        
        // Загрузить буфер
        if (fs != fatsector) {
                
            fseek(floppy, (1 + fs) * 512, SEEK_SET);
            fread(fatbuffer, 1, 1024, floppy);
            fatsector = fs;
        }
        
        clid = fatbuffer[ fn ] + 256*fatbuffer[ fn+1 ];
        
        // Нечетный кластер
        if ((cluster_id % 2) == 1) {        
            clid = (clid >> 4) & 0xfff;
        } else {
            clid = clid & 0xfff;            
        }
        
        // Сектор должен быть чист. Скачать и проверить.
        if (clid == 0) {
            
            fseek(floppy, (31 + cluster_id)*512, SEEK_SET);
            fread(onesector, 1, 512, floppy);
            
            int dirty = 0;
            for (j = 0; j < 512; j++) {
                if (onesector[j] != 0) {
                    
                    dirty++;
                    onesector[j] = 0;
                }
            }
            
            if (dirty) {
                
                fseek(floppy, (31 + cluster_id)*512, SEEK_SET);
                fwrite(onesector, 1, 512, floppy);
                
                printf("cluster %x dirty (%d%%)\n", cluster_id, (100 * dirty) / 512);
            }
        }
    }
    
    fclose(floppy);

    return 0;
}
