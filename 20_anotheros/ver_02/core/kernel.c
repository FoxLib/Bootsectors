/** Определение максимального объема памяти */
void detect_max_memory_size() {

    byte* m   = (byte*)1;
    uint  max = 0xDFFFFFFF;
    uint  min = 0x00200000;
    uint  mid;

    while (min < max) {

        mid = (min + max) >> 1;

        // Область страниц совпала. Максимальное количество памяти в `max`
        if ((min & 0xfffff000) + 0x1000 >= (max & 0xfffff000)) {

            mm_real_max = (max & 0xfffff000);
            mm_syst_max = SYSTEM_MEMORY_MB << 20;
            mm_syst_max = max < mm_syst_max ? max : mm_syst_max;
            break;
        }

        // Проверка на способность памяти измениться в этой точке
        volatile byte a = peek(mid); m[ mid-1 ] ^= 0x55;
        volatile byte b = peek(mid); m[ mid-1 ] ^= 0x55;

        if (a == b) {
            max = mid; // Здесь mid слишком высок
        } else {
            min = mid; // Поднять mid
        }
    }
}

/** Выделение резидентной памяти */
void* kalloc(uint size) {

    mm_syst_max -= size;
    return (void*) mm_syst_max;
}

/** Создание нового сегмента в GDT */
int create_gdt(dword address, dword limit, byte access) {

    word   i;
    qword  g;

    asm volatile("sgdt %0" : "=m"(g) : : "memory");

    word   cnt = ((g & 0xFFFF) >> 3) + 1;
    word   found = 0;
    byte   granular = 0;

    // Указатель на GDT
    struct GDT_item* gdt = (struct GDT_item*)(g >> 16);

    // Уменьшить лимит
    if (limit > 0xFFFFFF) {
        limit >>= 12;
        granular = 0x80;
    }

    // Искать свободный дескриптор
    for (i = 1; i < cnt; i++) {
        if ((gdt[i].access & D_PRESENT) == 0) {
            found = i;
            break;
        }
    }

    // Свободного дескриптора нет, создать новый
    if (found == 0) {

        found = cnt;
        g = (g & ~0xffff) | ((g & 0xffff) + 8);
        asm volatile("lgdt %0" : : "m"(g) : "memory");
    }

    // Установка параметров
    gdt[ found ].addrlo =  address & 0xFFFF;
    gdt[ found ].addrhl = (address >> 16) & 0xFF;
    gdt[ found ].addrhh = (address >> 24) & 0xFF;

    // Предел 1 мб
    gdt[ found ].limit   = (limit) & 0xffff;
    gdt[ found ].limithi = ((limit >> 16) & 0xf) | (0x40 | granular);

    // Байты типа и доступа
    gdt[ found ].access  = D_PRESENT | access;

    return found;
}

/** Инициалиазция нового GDT из старых данных */
void copy_GDT() {

    uint i;
    qword GDT_mem_base;

    // Выделить системную память под новую
    byte* m = (byte*) kalloc(65536);

    // Записать адрес таблицы
    GDT = (struct GDT_item*)m;

    // Сохранение старого GDT
    asm volatile("sgdt %0" : "=m"(GDT_mem_base) : : "memory");

    // Получение предыдущего адреса
    dword GDT_addr  =  GDT_mem_base >> 16;
    dword GDT_limit = (GDT_mem_base & 0xFFFF) + 1;

    // Копирование из предыдущего GDT
    byte* s = (byte*)GDT_addr;

    // Перенос старых данных и полная очистка таблицы
    for (i = 0; i < GDT_limit; i++) m[i] = s[i];
    for (i = GDT_limit; i < 65536; i++) m[i] = 0;

    // Количество дескрипторов будет пока что тоже самое
    GDT_mem_base = ((qword)m << 16) | (GDT_limit - 1);

    // Загрузить новый GDT
    asm volatile("lgdt %0" : : "m"(GDT_mem_base) : "memory");
}

/** Установка страничной адресации */
void init_paging() {

    int i, j;

    dword  cr0;
    dword* pte;     // Указатель на каталог страниц

    // Выровнять память для PDBR
    kalloc(mm_syst_max - (mm_syst_max & ~0xFFF));

    // Выделить память под PDBR Ring 0
    PDBR  = kalloc(4096);

    // Выделить память под страницы 4mb = 4kb
    pte  = kalloc((mm_real_max >> 10) & ~0xFFF);

    // Разметка страниц PDBR 1:1
    for (i = 0; i < 1024; i++) {

        // Адрес каталогов страниц
        dword* ptc = pte + (i << 10);

        // Просматриваем PDBR
        if ((i << 22) < mm_real_max) {

            PDBR[i] = (dword)ptc | (PTE_RW | PTE_PRESENT);

            // Разметить страницы по 4Мб
            for (j = 0; j < 1024; j++) {

                dword mp = (i << 22) | (j << 12);
                ptc[j] = (mp < mm_real_max ? mp | (PTE_RW | PTE_PRESENT) : 0);
            }
        }
        // Страница пуста
        else PDBR[i] = 0;
    }

    // Поместить в CR3 значение PDBR
    asm volatile("movl %0, %%cr3"       : : "r" (PDBR) );
    asm volatile("movl %%cr0, %0"       : : "r" (cr0) );
    asm volatile("orl  $0x80000000, %0" :   "=r"(cr0) );
    asm volatile("movl %0, %%cr0"       :   "=r"(cr0) );
    asm volatile("jmp  localm");
    asm volatile("localm:");
}

/** Создание и переключение на главный TSS */
void init_main_task() {

    // Занять место под задачу
    TSS_Main = (struct TSS_item*)kalloc(104);

    // @todo Выделение стека разного уровня

    // Добавление дескриптора
    word id = create_gdt((dword)TSS_Main, 103, T_TSS_AVAIL);

    // Загрузка первой задачи TI=0, CPL=00
    asm volatile("ltr %0" : : "r" ((word)(id << 3)) );
}

/** Процедура инициализации ядра */
void kernel_init() {

    apic_disable();

    /* Переназначить новые прерывания */
    irq_init(IRQ_TIMER | IRQ_KEYB | IRQ_CASCADE | IRQ_PS2MOUSE | IRQ_FDC);

    /* Инициализировать клавиатуру и мышь */
    kbd_init();
    ps2_init_mouse();

    /* Определение размера памяти */
    detect_max_memory_size();

    /* Перенести GDT */
    copy_GDT();

    /* Инициализация видеоподсистемы */
    init_vg();

    /* Создание главной задачи */
    init_main_task();

    /* Создание страниц */
    init_paging();

    /* Инициализация дисков */
    init_disk();
}
