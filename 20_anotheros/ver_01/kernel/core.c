// Сохранение указателя GDT
uint64_t save_gdt() {

    uint64_t gdt_mem_base;

    __asm__ __volatile__("sgdt %0"
                        : "=m"(gdt_mem_base)
                        :
                        : "memory");

    // Сохраняются данные также в gdt
    // uint64_t gdtaddr = SGDT((uint64_t) &GDT);

    return gdt_mem_base;
}

// Загрузка нового GDT
void load_gdt(uint64_t gdt_mem_base) {

    __asm__ __volatile__("lgdt %0"
                    :
                    : "m"(gdt_mem_base)
                    : "memory");
}

// Создание нового сегмента GDT
int create_gdt(uint32_t address, uint32_t limit, uint8_t access) {

    uint16_t  i;
    uint64_t  g   =  save_gdt();
    uint16_t  cnt = ((g & 0xFFFF) >> 3) + 1;
    uint16_t  found = 0;
    uint8_t   Granular = 0;

    // Указатель на GDT
    struct GDT_item* gdt = (struct GDT_item*)(g >> 16);

    // Уменьшить лимит
    if (limit > 0xFFFFFF) {
        limit >>= 12;
        Granular = 0x80;
    }

    // Искать свободный дескриптор
    for (i = 1; i < cnt; i++) {
        if ((gdt[i].access & DESC_PRESENT) == 0) {
            found = i;
            break;
        }
    }

    // Свободного дескриптора нет, создать новый
    if (found == 0) {
        found = cnt;
        load_gdt((g & ~0xffff) | ((g & 0xffff) + 8));
    }

    // Установка параметров
    gdt[ found ].addrlo =  address & 0xFFFF;
    gdt[ found ].addrhl = (address >> 16) & 0xFF;
    gdt[ found ].addrhh = (address >> 24) & 0xFF;

    // Предел 1 мб
    gdt[ found ].limit   = (limit) & 0xffff;
    gdt[ found ].limithi = ((limit >> 16) & 0xf) | (0x40 | Granular);

    // Байты типа и доступа
    gdt[ found ].access  = DESC_PRESENT | access;

    return found;
}

// Инициалиазция GDT из старых данных
void init_gdt() {

    uint32_t i;

    // Выделить системную память под новую
    uint8_t* m = (uint8_t*)kalloc(65536);
    
    // @todo очистить память GDT

    // Записать адрес таблицы
    GDT = (struct GDT_item*)m;

    // Получение предыдущего адреса
    uint64_t GDT_prev  =  save_gdt();
    uint32_t GDT_addr  =  GDT_prev >> 16;
    uint32_t GDT_limit = (GDT_prev & 0xFFFF) + 1;

    // Копирование из предыдущего GDT
    uint8_t* s = (uint8_t*)GDT_addr;

    // Перенос старых данных
    for (i = 0; i < GDT_limit; i++) m[i] = s[i];

    // Количество дескрипторов будет пока что тоже самое
    uint64_t g = ((uint64_t)m << 16) | (GDT_limit - 1);
    load_gdt(g);
}

// Очистка регионов памяти. fsblock = 1 блокировать исполнение без fs
void init(int fsblock) {

    int mask = IRQ_KEYB | IRQ_CASCADE | IRQ_PS2MOUSE | IRQ_TIMER;

    init_irq(mask);         // Назначить обработчики IRQ
    init_ps2_mouse();       // Инициализировать мышь
    init_memory();          // Определить размер памяти
    init_gdt();             // Инициализация
    init_main_task();       // Создание главной задачи
    init_ata_drives();      // Инициализация дисков
    init_vg();              // Подготовить видеоподсистему
    init_windows();         // Инициализация окон
    init_paging();          // Страничная адресация (в последнюю очередь)

    // Проверка на наличие файловых систем
    if (fat_found == 0 && fsblock) {
        colorat(8,8,0xffffff,0); print("Panic! FAT not found"); for(;;);
    }
    fs_init(0);             // Установка основной fs
}
