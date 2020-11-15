/** Обработка прерываний с клавиатуры */
void kbd_handler() {

    brk;
    byte ch = IoRead8(0x60);
}

/** Инициализировать клавиатуру */
void kbd_init() {
    pic.keyboard = & kbd_handler;
}
