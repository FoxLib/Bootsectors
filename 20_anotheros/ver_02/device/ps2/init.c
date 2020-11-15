
// bit=1 read, bit=2 write
void kb_wait(int rw) {

    int i;
    for (i = 0; i < KB_WAIT; i++)
        if ((IoRead8(0x64) & rw) == 0)
            return;
}

// Ожидание специального случая
void kb_wait_not() {

    int i;
    for (i = 0; i < 8*KB_WAIT; i++)
        if ((IoRead8(0x64) & 1))
            return;
}

// Отправка команды
void kb_cmd(int comm) {

    kb_wait(2);
    IoWrite8(0x64, comm);

    kb_wait(2);
}

// Запись данных
void kb_write(int data) {

    kb_wait(0x20);           // (May be "receive time-out" or "second PS/2 port output buffer full") Ожидание готовности
    IoRead8(0x60);           // Чтение данных из порта (не имеет значения)

    kb_wait(2);                 // Ждать для записи
    IoWrite8(0x60, data);       // Записать данные

    kb_wait(2);                 // Ждать для записи
    kb_wait_not();              // Подождать, пока будет =1 на чтение
}

// Чтение данных
int kb_read() {

    kb_wait_not();
    delay();
    return IoRead8(0x60);
}

// Обработчик МЫШ`и
void ps2_mouse_handler() {
    brk;
}

// Инициализацировать мышь
void ps2_init_mouse() {

    uint a;

    kb_cmd(0xA8);     kb_read();
    kb_cmd(0x20); a = kb_read();

    kb_cmd(0x60);
    kb_write(a | 3);

    // Отослать команду для PS/2 разрешени
    kb_cmd(0xD4);
    kb_write(0xF4);
    kb_read();

    // Инициализировать переменные
    ps2_pressed         = 0;
    ps2_time_at         = 0;
    ps2_mouse_state     = 0;

    // Определение обработчика
    pic.ps2mouse = & ps2_mouse_handler;
}
