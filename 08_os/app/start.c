
/* 
 * Перерисовать рабочий стол
 */
void app_desktop_redraw() {

    // Рисуем рабочий стол
    vga_fillrect(0,0,639,454,0x3); 

    // рисовать все приложения

}

/*
 * Затемнить весь рабочий стол
 */

void app_ui_shadow()
{
    int i, j;
    for (i = 0; i < 455; i++) {
        for (j = i%2; j < 640; j+=2) {
            vga_pixel(j,i,0);
        }
    }
}

/*
 * Добавить новую задачу
 */

void app_add_task(u8 app_class) {

    u8 i;
    SysTask T;

    // Очистить флаг активности задачи
    for (i = 0; i < sys_task_last; i++) {
        data_sys_task[i].flags &= ~APP_FLAG_ACTIVE;
    }

    T.app_class = app_class;
    T.flags     = APP_FLAG_ACTIVE;   

    // Новая задача
    data_sys_task[ sys_task_last++ ] = T;
}

/*
 * Работа с "Пуском"
 */
 
void app_start() {

    // Получение номера нажатой клавиши
    u8 kc = dev_keyb_get();   

    if (!(kc & 0x80)) {

        // Действия при открытом пуске
        // -----------------------------------------------------------------------
        if (ui_start_expand && kc) {

            // Скан-код ВНИЗ
            if (kc == KEYSCAN_DOWN) { 

                ui_start_curr++;
                ui_start_menu();

            // ВВЕРХ
            } else if (kc == KEYSCAN_UP) { 

                ui_start_curr--;
                ui_start_menu();

            // Запустить приложение или активировать его. Также,  проверить, что CTRL не был нажат
            } else if (kc == KEYSCAN_ENTER && !dev_key_test(KEY_LCTRL)) {

                // В любом случае сначала перерисовать рабочий стол
                ui_start_expand = 0;
                app_desktop_redraw();

                // @todo добавление новой задачи
                app_add_task(CLASSID_COMMANDER);

                // Нарисовать новую
                ui_start_bar();
            }
        }

        // Реакция на только что нажатую клавишу
        if (kc) {

            kc = dev_key_ascii(kc); // ASCII

            // Пуск сработает только тогда, когда нажмется CTRL+ENTER
            // -----------------------------------------------------------------------
            if (kc == 10 && dev_key_test(KEY_LCTRL)) {

                // Статус пуска
                ui_start_expand ^= 1;

                // Только что было свернуто, перерисовать рабочий стол
                if (ui_start_expand == 0) {
                    app_desktop_redraw();
                } 

                // Пуск перерисовать
                ui_start_bar();

            }

        }
    }
}