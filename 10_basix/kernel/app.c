#include "app.h"

/*
 * Загрузить в память новое приложение RAW
 * Оно не может превышать 8 мб по код (4мб) + данные (4мб)
 * Это нечто 32-х битного аналога COM
 *
 * .raw  код в 4`00000h, данные в 8`00000h
 * Но данные создаются потом, но нужный локальный PDBR подготавливается
 */
 
int app_load_raw(char* filename) {
    
    int cat_ref = 0;
    int fd = fopen(filename);
    int app_id = 0, page_id, i;
    
    if (fd) {
        
        // Перебор и поиск свободных процессов
        for (i = 1; i < PROCESS_MAX; i++) {
            
            if (apps[i].busy == 0) {
                apps[i].busy = 1;
                app_id = i;
                break;
            }
        }
        
        // Процессов слишком много 
        if (app_id == 0) {
            return 0;
        }
        
        // Назначение генеральной страницы
        apps[ app_id ].cr3_map = palloc();
        apps[ app_id ].type = PROCESS_TYPE_RAW;
        
        // Прописать первые 4 Мб как "СИСТЕМНЫЕ"
        mm_writed(apps[ app_id ].cr3_map, CATALOG_FIRST4MB | PT_PRESENT | PT_RW | PT_FULL);
        
        // Создание второй/третьей страницы (4 мб), куда грузить 
        uint32_t  catalog_code = palloc();
        uint32_t  catalog_data = palloc();
        
        uint32_t* ref_code = (uint32_t*)catalog_code;
        uint32_t* ref_data = (uint32_t*)catalog_data;
        
        // Выделение 2-х сегментов
        mm_writed(apps[ app_id ].cr3_map + 4, catalog_code | PT_PRESENT | PT_RW | PT_US);
        mm_writed(apps[ app_id ].cr3_map + 8, catalog_data | PT_PRESENT | PT_RW | PT_US);
        
        // Ограничение загрузки большого файла
        int fs = fsize(fd);
        fs = fs >= 4194304 ? 4194303 : fs;
        
        while (fs > 0) {

            uint32_t link = palloc();
            
            // Создать ссылку на новую страницу
            ref_code[ page_id++ ] = link | PT_PRESENT | PT_RW | PT_US;
           
            // Загрузить данные
            fread((void*)link, 4096, fd);
            
            fs -= 4096;            
        }
        
        // Записать EIP в локальный TSS
        mm_writed( ((uint32_t)apps[ app_id ].tss) + 0x20, 0x400000 );
        
        // Вершина стека сегмента находится в C`00000 (на самом верху)
        mm_writed( ((uint32_t)apps[ app_id ].tss) + 0x14, 0xC00000 );
        
    }
    
    fclose(fd);        
    return app_id;
}

/*
 * Запуск и выполнение приложения в его квант времени
 */

void app_start(int app_id) {
    
    // Задать исполняемый ID
    app_id_current = app_id;
    
    // Запуск кванта
    app_exec( (uint32_t)apps[app_id].tss, apps[app_id].cr3_map );

}
