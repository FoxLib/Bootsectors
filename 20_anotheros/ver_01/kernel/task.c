// Создание и переключение на главный TSS
void init_main_task() {

    TSS_Main = (struct TSS_item*)kalloc(104);

    // @todo Выделение стека разного уровня

    // Добавление дескриптора
    uint16_t id = create_gdt((uint32_t)TSS_Main, 103, TYPE_TSS_AVAIL);

    // Загрузка первой задачи TI=0, CPL=00
    __asm__ __volatile__ ("ltr %0" : : "r"((uint16_t)(id << 3)) );
}
