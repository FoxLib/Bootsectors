// Состояние кнопки ПУСК
u8 ui_start_expand = 0;
i8 ui_start_curr = 0;

/*
 * Перерисовка окна
 */

void ui_window(u16 x1, u16 y1, u16 x2, u16 y2, char* title) {

    // Внешняя рамка
    vga_rect(x1, y1, x2, y2, 0);

    // Тени
    x1++; y1++; x2--; y2--;
    vga_line(x1, y2, x2, y2, 8);
    vga_line(x2, y1, x2, y2, 8);
    vga_line(x1, y1, x2, y1, 15);
    vga_line(x1, y1, x1, y2, 15);

    // Само окно
    x1++; y1++; x2--; y2--;
    vga_fillrect(x1,y1,x2,y2,7);

    // Строка заголовка
    vga_fillrect(x1+2,y1+2,x2-2,y1+24,1);    

    // Печать строки
    vga_put_zstring(x1+8, y1+6, title, 15);
}

/*
 * Нарисовать кнопку с текстом
 */

void ui_button(u16 x1, u16 y1, u16 x2, u16 y2, char* text, u8 pressed) {

    // Подложка
    vga_fillrect(x1,y1,x2,y2,7);

    // Нажата ли клавиша
    if (pressed) {

        vga_line(x1, y1, x2, y1, 8);
        vga_line(x1, y1, x1, y2, 8);
        vga_line(x1, y2, x2, y2, 15);
        vga_line(x2, y1, x2, y2, 15);

        vga_put_zstring(x1+5,y1+3,text,0);

    } else {

        vga_line(x1, y1, x2, y1, 15);
        vga_line(x1, y1, x1, y2, 15);
        vga_line(x1, y2, x2, y2, 8);
        vga_line(x2, y1, x2, y2, 8);

        vga_put_zstring(x1+4,y1+2,text,0);

    }

    vga_rect(x1+1, y1+1, x2-1, y2-1, 8);   
}

/*
 * Отрисовать только меню с ограничием на несколько элементов
 */

void ui_start_menu() {

    // Ограничение
    if (ui_start_curr < 0) { ui_start_curr = 0; return; }
    if (ui_start_curr > 2) { ui_start_curr = 2; return; }

    // Перерисовать подложку
    vga_fillrect(4, 270, 196, 450, 7);

    // Высветить текущую позицию
    vga_fillrect(4,280-4 + 20*ui_start_curr, 196, 300-4 + 20*ui_start_curr,0);

    // Нарисовать меню
    vga_put_zstring(10,280,"File Manager", ui_start_curr == 0 ? 15 : 0);
    vga_put_zstring(10,300,"Console",      ui_start_curr == 1 ? 15 : 0);
    vga_put_zstring(10,320,"Text Editor",  ui_start_curr == 2 ? 15 : 0);

}

/*
 * Рисовать окно "Пуска"
 */
void ui_start_bar() {

    int i;

    vga_fillrect(0,456,639,479,7);
    vga_fillrect(0,455,639,455,8);
    vga_fillrect(0,456,639,456,15);

    // В зависимости от того, как нажата или не нажата кнопка
    ui_button(2,458,50,476, "START", ui_start_expand);

    if (ui_start_expand) {

        ui_window(0, 240, 200, 454, "Manage Applications");
        ui_start_menu();
    }

    // Смещения
    u16 s = 62;

    // Рисовать список окон
    for (i = 0; i < sys_task_last; i++) {

        ui_button(s,458,s+100,476, "***", (data_sys_task[i].flags & APP_FLAG_ACTIVE) );

        s += 104;

    }
}