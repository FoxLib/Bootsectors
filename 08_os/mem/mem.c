
/*
 * Непрерываное выделение нового блока памяти
 * для системных целей
 */

u8* mem_sys_malloc(u32 size)
{
    u8* m = mem_top;
    mem_top += size;
    return m;
}

/*
 * Инициализация первых страниц
 */

void mem_paging_init()
{
    u32  i;
    u32* item = (u32*)0x00000000;

    // По адресу 0x00400000 - 0x007FFFFF располагается полная таблица страниц
    u32* mmap = (u32*)0x00400000;

    // Основная страница, которая располагается в первых 4096 байтах HMA
    data_pdbr = mem_sys_malloc(4096); for (i = 0; i < 4096; i++) data_pdbr[i] = 0;

    // Ссылка на глобальный каталог
    item = (u32*)data_pdbr;

    // Перечислить ссылки на все 1024 каталогов
    for (i = 0; i < 1024; i++) {

        // Если элемент каталога превышает объем памяти
        if (i*4096*1024 >= mem_size) {

            item[i] = 0;

        } else {

            // Записать в глобальный каталог адрес на каталог страниц
            item[i] = (0x00400000 + i*4096) | PG_US | PG_PRESENT;
        }

    }

    // Записать все возможные ссылки отображения памяти 1:1
    for (i = 0; i < 1024*1024; i++) {

        // Ограничить объем памяти
        if (i*4096 > mem_size) break;

        // Записать информацию о доступности страниц
        mmap[i] = (i*4096) | PG_US | PG_PRESENT;

    }

    // Переключить на страничную адресацию памяти
    asm volatile("mov eax, 0x00100000" "\n" "mov cr3, eax");
    asm volatile("mov eax, cr0" "\n" "or  eax, 0x80000000" "\n" "mov cr0, eax");

    // Сбросить буферы TLB
    asm volatile("jmp @f" "\n" "@@:");
}

/*
 * Работа с памятью
 */

void mem_init()
{
    u32 i;

    /*
     * Создание PAGING-модели памяти
     */

    mem_paging_init();

    /*
     * Другие области системной памяти
     */

    mem_sys = mem_sys_malloc(65536);

    mem_keyb_pressed = mem_sys_malloc(256);
    mem_keyb_buffer  = mem_sys_malloc(512);

    // Вектор со списком задач
    data_sys_task = (SysTask*) mem_sys_malloc(4096);
}