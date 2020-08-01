#include "io.h"
#include "vga.h"
#include "ps2mouse.h"

// Обработчик мыши
void ps2_mouse_handler() {

    // Команда и блокировка клавиатуры
    kb_cmd(0xAD);

    // Считывание результата
    int cmd = kb_read();
    int x   = kb_read();
    int y   = kb_read();

    // Знаковое расширение (x,y)
    if (cmd & 0x10) x = -((x ^ 0xFF) + 1);
    if (cmd & 0x20) y = -((y ^ 0xFF) + 1);

    // Новое значение
    ps2.cmd  = cmd;
    ps2.x   += x;
    ps2.y   -= y;

    // Ограничители
    if (ps2.x >= vg.width)  ps2.x = vg.width - 1;
    if (ps2.y >= vg.height) ps2.y = vg.height - 1;
    if (ps2.x <  0) ps2.x = 0;
    if (ps2.y <  0) ps2.y = 0;

    // Разблокировка клавиатуры
    kb_cmd(0xAE);
}

// Задержка
void kb_delay() {

    int i;
    for (i = 0; i < 8; i++) {
        asm volatile("nop");
    }
}

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

    kb_wait(0x20);          // (May be "receive time-out" or "second PS/2 port output buffer full") Ожидание готовности
    IoRead8(0x60);          // Чтение данных из порта (не имеет значения)

    kb_wait(2);             // Ждать для записи
    IoWrite8(0x60, data);   // Записать данные

    kb_wait(2);             // Ждать для записи
    kb_wait_not();          // Подождать, пока будет =1 на чтение
}

// Чтение данных
int kb_read() {

    kb_wait_not();
    kb_delay();
    return IoRead8(0x60);
}

// Инициализацировать мышь
void ps2_init_mouse() {

    uint a;

    kb_cmd(0xA8);     kb_read();
    kb_cmd(0x20); a = kb_read();
    kb_cmd(0x60);
    kb_write(a | 3);

    // Отослать команду для разрешения PS/2
    kb_cmd  (0xD4);
    kb_write(0xF4);
    kb_read();

    // Инициализировать переменные
    ps2.pressed     = 0;
    ps2.time_at     = 0;
    ps2.mouse_state = 0;

    ps2.cmd    = 0;
    ps2.x      = 0;
    ps2.y      = 0;
}
