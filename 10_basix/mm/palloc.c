#include "mm.h"

/*
 * Поиск свободной страницы
 * 
 * Ситуация 1. Свободных страниц осталось 1, необходимо выделить 4 кб
 * еще для того, чтобы записать новый каталог из PDBR.
 * 
 * Ситуация 2. Памяти вообще не осталось. Это определяется через размер,
 * который задал loader. Важно.
 * 
 * @RETURN  0 -- память вся занята
 */
 
uint32_t palloc() {

    int dir_id, id, k;
    
    // Сначала пройтись по каталогам
    uint32_t* pdbr = (uint32_t*)PDBR_ADDRESS;
    
    // Пересмотреть все 3Гб каталогов
    for (id = 0; id < 768; id++) {

        uint32_t* dir_addr = (uint32_t*)(pdbr[ id ] & 0xFFFFF000);
        uint16_t  dir_attr = pdbr[ id ] & 0x0FFF;
        
        // Каталог не должен быть полным, иначе нет смысла смотреть
        if (dir_attr & PT_FULL) {        
            continue;
        
        }
        // Каталог в памяти представлен, просмотреть его        
        else if (dir_attr & PT_PRESENT) {

            // Поиск свободных страниц
            for (dir_id = 0; dir_id < 1024; dir_id++) {
                
                uint32_t page_addr = (id << 22) | (dir_id << 12);
                uint16_t page_attr = dir_addr[ dir_id ] & 0x0FFF;

                // Не превышает максимум памяти?
                if (page_addr >= mm_top) {
                    return 0;
                }
                
                // Данная страница в этом каталоге не занята? 
                if (!(page_attr & PT_PRESENT)) {                    
                    
                    // Занять страницу!                
                    dir_addr[ dir_id ] = page_addr | 3;
                    
                    // Очистить эту страницу
                    uint32_t* tmp_addr = (uint32_t*) page_addr;
                    for (k = 0; k < 1024; k++) {
                        tmp_addr[k] = 0;
                    }
                    
                    return page_addr;
                }
            }
            
        // В ранее просмотренных каталогах ничего нет. Выделить новый.
        } else {

            uint32_t page_raw = (id << 22);

            // Отметить предыдущий как "полный" (не найдено свободных)
            // Указатель директории каталогов указывает на новый каталог

            pdbr[ id - 1] |= PT_FULL;
            pdbr[ id    ]  = page_raw | 3;            
            
            // Адрес 4000h-4FFFh теперь указывает на [page_raw .. +4095]
            uint32_t *page_reloc = (uint32_t*)0x2010;
                     *page_reloc = page_raw | 3;

            // Через смаппленный 4xxxh мы записываем новый каталог
            uint32_t* temp_table = (uint32_t*)TEMPAGE_ADDRESS;

            // Первая страница каталога всегда будет указывать на себя
            for (k = 0; k < 1024; k++) {
                
                if (k == 0) {                
                    temp_table[k] = page_raw | 3;
                } 
                else if (k == 1) {
                    temp_table[k] = (page_raw + 0x1000) | 3;
                                        
                } else {
                    temp_table[k] = 0;
                }
            }            

            // Очистка этой страницы 4kb -> ZERO
            uint32_t* page_addr = (1024 + (uint32_t*)page_raw);
                        
            for (k = 0; k < 1024; k++) {
                page_addr[k] = 0;
            }

            return (page_raw + 0x1000);
        }
    }
 
    return 0;   
}
