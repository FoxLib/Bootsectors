// Очистка экрана
void cls(unsigned char color) {

    int i;

    // Заполнить цветом
    block(0, 0, 639, 479, color);

    // Инициализация курсора
    cursor.x = 0;
    cursor.y = 0;
    cursor.frcolor       = 0;
    cursor.bgcolor       = -1;
    cursor.border_top    = 0;
    cursor.border_right  = 639;
    cursor.border_bottom = 479;
    cursor.border_left   = 0;
    cursor.max_chars     = 0;

    desktop_color = color;
}

// На рабочий стол было нажатие
void desktop_mousedown() {

    /*
    colorat(0,0,0xffffff,0);
    print_int(cursor.mouse_x);
    print(", ");
    print_int(cursor.mouse_y);
    */
}

// Панель снизу
void panel_repaint() {

    int t = 454, id, num = 0;

    color(0, -1);

    block(0, t,   639, t,   0);
    block(0, t+1, 639, t+1, 15);
    block(0, t+2, 639, 479, 7);

    // Кнопка пуск
    button(3, 458, 72, 19, 0);

    // Лого
    block(6, 461, 11, 466, 4); block(13, 461, 18, 466, 2);
    block(6, 468, 11, 473, 1); block(13, 468, 18, 473, 6);
    print_at(3 + 20, 459 + 1, "Запуск");

    // Вертикальная полоса-разделитель
    block(78, 458, 78, 477, 8);
    block(79, 458, 79, 477, 15);

    // Параметры вывода
    color(0, -1);
    cursor.max_chars = 13;

    // Отрисовать текущие окна
    for (id = 1; id < WINDOW_MAX; id++) {

        // Окно есть и можно рисовать его в панели
        if (allwin[id].in_use && allwin[id].panel) {

            int x = 83 + 127*num;
            int y = 460;

            // Нарисовать кнопку
            button(x, 458, 125, 19, allwin[id].active);

            // Написать текст (макс 13 символов)
            int n = print_at(x + 4, y, allwin[id].title);

            // Если превышение, то дорисовать ..
            if (n == 0) print_at(x + 4 + 13*8, y, "..");

            num++;
        }
    }

    cursor.max_chars = 0;
}

// Перерисовать область заднего фона
void desktop_repaint_bg(int x1, int y1, int w, int h) {

    block(x1, y1, x1 + w, y1 + h, 3);

    // Если область захватила панель
    if (y1 + h >= 450 || y1 >= 450)
        panel_repaint();
}

// Нарисовать линии перемещения
void draw_mover() {

    int i;
    struct window* w = & allwin[ mover_active ];

    // Обновить новую позицию
    mover_x1     = w->x1;
    mover_y1     = w->y1;
    mover_width  = w->x2 - w->x1;
    mover_height = w->y2 - w->y1;

    for (i = 0; i <= mover_width; i++) {

        bgmover[0][i] = get_point(w->x1 + i, w->y1);
        bgmover[1][i] = get_point(w->x1 + i, w->y2);
    }

    for (i = 0; i <= mover_height; i++) {

        bgmover[2][i] = get_point(w->x1, w->y1 + i);
        bgmover[3][i] = get_point(w->x2, w->y1 + i);
    }

    for (i = 0; i <= mover_width; i += 2) {
        pset(w->x1 + i, w->y1, 15);
        pset(w->x1 + i, w->y2, 15);
    }
    for (i = 0; i <= mover_height; i += 2) {
        pset(w->x1, w->y1 + i, 15);
        pset(w->x2, w->y1 + i, 15);
    }
}

// Восстановить область
void restore_mover() {

    int i;

    for (i = 0; i <= mover_width; i++) {
        pset(mover_x1 + i, mover_y1, bgmover[0][i]);
        pset(mover_x1 + i, mover_y1 + mover_height, bgmover[1][i]);
    }

    for (i = 0; i <= mover_height; i++) {
        pset(mover_x1, mover_y1 + i, bgmover[2][i]);
        pset(mover_x1 + mover_width, mover_y1 + i, bgmover[3][i]);
    }
}

// Создать базовое окно
void make_desktop() {

    desktop = window_create(0, 0, 640, 480, "Desktop");

    allwin[ desktop ].panel = 0;
    allwin[ desktop ].state = 0;

    // Назначение событий на основной рабочий стол
    window_event(desktop, EVENT_MOUSEDOWN, & desktop_mousedown);
}
