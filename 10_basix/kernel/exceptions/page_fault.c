// http://wiki.osdev.org/Exceptions#Page_Fault
// в code_id расшифровка, что происходит и откуда

#define PAGE_REQUIRE_PRESENT    0x001
#define PAGE_REQUIRE_WRITE      0x002
#define PAGE_REQUIRE_USER       0x004
#define PAGE_REQUIRE_IFETCH     0x010

void ui_handler(uint32_t* stack);

/*
 * Обработчик PAGE EXCEPTION
 * 
 * создание необходимых страниц по мере их запроса
 */

// address -- запрошенный адрес
// code_id -- код ошибки с Page Fault

void handler_page_fault(uint32_t address, uint32_t code_id, uint32_t stack) {

    // Вызов из CPL=3
    if (code_id & PAGE_REQUIRE_USER) {
        
        // RAW-приложение, ранги допустимых запросов
        // -------------------------------------------------------------
        if (apps[ app_id_current ].type == PROCESS_TYPE_RAW) {
        
            // Вызов был верным (на данные), надо предоставить данные
            if (address >= 0x800000 && address < 0xC00000) {

                // Переключиться на адреса ядра
                SetCR3( PDBR_ADDRESS );

                uint32_t page = (address - 0x400000) & 0xfffff000;
                
                // Адрес каталога
                uint32_t* catalog_ref = (uint32_t*)(mm_readd(apps[ app_id_current ].cr3_map + 4*2) & 0xfffff000);
                                
                // Назначить новую страницу
                catalog_ref[ (page >> 12) & 0x3ff ] = palloc() | PT_PRESENT | PT_RW | PT_US;
                
                // Установка CR3 снова на локальный PDBR
                SetCR3( apps[ app_id_current ].cr3_map );
                
            }
            // Обращение к несуществующей области памяти. Срочно закрыть.
            else if (address > 0x400000) {
                
                // покинуть приложение с ошибкой
                
            }
            // Возможны некоторые адреса обращений к системным данным
            else {
brk;
                switch (address) {
                    
                    /*
                     * Видеосервис
                     */

                    case 1: ui_handler((uint32_t*)stack); break;
                    
                }
                
                // SetCR3( PDBR_ADDRESS );                
                // --------
                
                // --------
                // SetCR3( apps[ app_id_current ].cr3_map );

                // ..
                
            }
        }
        // -------------------------------------------------------------      
        
    } else {
        
        // Ужасный баг...        
    }
}
