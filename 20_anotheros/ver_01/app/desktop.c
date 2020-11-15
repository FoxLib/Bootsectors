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
    desktop_button_start = 0;
    win_start = 0;
}

// Закрыть окно "старт"
void desktop_close_start() {

    desktop_button_start = 0;

    if (win_start) {
        window_close(win_start);
        win_start = 0;
    }
}

// На рабочий стол было нажатие
void desktop_mousedown() {

    int x = cursor.mouse_x,
        y = cursor.mouse_y;

    // Нажато на кнопку пуск?
    if (x >= 3 && x <= 75 && y >= 458 && y <= 477) {

        if (desktop_button_start) {
            desktop_close_start();

        } else {

            desktop_button_start = 1;

            win_start = window_create(0, 302, 200, 130, "Выбор программ");

            allwin[ win_start ].panel    = 0;
            allwin[ win_start ].no_close = 1; // Нет кнопки закрыть
            allwin[ win_start ].no_mover = 1; // Не перемещаемое

            window_repaint(win_start);
        }

        panel_button_start();
    }
    // Нажато куда-то на рабочий стол, закрыть окно
    else if (desktop_button_start) {

        desktop_close_start();
    }
}

// Кнопка "Пуск"
void panel_button_start() {

    // Кнопка пуск
    button(3, 458, 72, 19, desktop_button_start);

    // Лого
    block(6, 461, 11, 466, 4); block(13, 461, 18, 466, 2);
    block(6, 468, 11, 473, 1); block(13, 468, 18, 473, 6);
    print_at(3 + 20, 459 + 1, "Запуск");
}

// Перерисовать панель задач
void panel_task_repaint() {

    int id, num = 0;

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

// Панель снизу
void panel_repaint() {

    int t = 454;

    color(0, -1);

    block(0, t,   639, t,   0);
    block(0, t+1, 639, t+1, 15);
    block(0, t+2, 639, 479, 7);

    panel_button_start();

    // Вертикальная полоса-разделитель
    block(78, 458, 78, 477, 8);
    block(79, 458, 79, 477, 15);

    panel_task_repaint();
}

// Перерисовать область заднего фона
void desktop_repaint_bg(int hwnd, int x1, int y1, int w, int h) {

    int i;

    int x2 = x1 + w,
        y2 = y1 + h;

    block(x1, y1, x2, y2, 3);

    // Проверить захваченные края окон
    for (i = 1; i < WINDOW_MAX; i++) {

        struct window* win = & allwin[i];

        // Пропуск своего окна
        if (i == hwnd)
            continue;

        // Окно открыто, проверить его границы
        if (win->in_use && win->state == WINDOW_STATE_DEFAULT) {

            // Один из краев области пересекся с x1 или x2
            if ( ((x1 < win->x1 && win->x1 < x2) || (x1 < win->x2 && win->x2 < x2) || (x1 > win->x1 && x2 < win->x2)) &&
                 ((y1 < win->y1 && win->y1 < y2) || (y1 < win->y2 && win->y2 < y2) || (y1 > win->y1 && y2 < win->y2)) ) {
                window_repaint(i);
            }
        }
    }

    // Если область захватила панель
    if (y1 + h >= 450 || y1 >= 450) {
        panel_repaint();
    }
}

// Скопировать область за линиями перемещений
void copy_mover() {

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
}

// Нарисовать линии перемещения
void draw_mover() {

    int i;
    struct window* w = & allwin[ mover_active ];

    copy_mover();

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

// Отослать события нажатия мыши
// key = 1 | 2 | 4
// dir = 1 (down) 0 (up)

void push_event_click(int key, int dir) {

    int i, hwnd = 0, hit = 0, hit_title = 0, active_last = 0;
    int x = cursor.mouse_x;
    int y = cursor.mouse_y;

    struct window* w;

    // Обнаружить, где именно нажата мышь
    for (i = 1; i < WINDOW_MAX; i++) {

        w = & allwin[i];

        if (w->active) {
            active_last = i;
        }

        // Проверять все
        if (w->in_use) {

            // Проверка попадания в окно
            if (w->x1 <= x && x <= w->x2 && w->y1 <= y && y <= w->y2) {
                hwnd = i;
                hit = 1;
            }
        }
    }

    // Отослать событие
    if (hit) {

        w = & allwin[ hwnd ];

        if (key == PS2_BUTTON_LEFT) {

            if (w->active == 0 && dir) {

                // Активация нового окна при левом кнопке мыши
                window_activate(hwnd);

                // Перерисовка предыдущего активного окна
                if (active_last != hwnd) {
                    if (allwin[ active_last ].active == 0) {
                        window_repaint(active_last);
                    }
                }

                window_repaint(hwnd);   // Перерисовать окно
                panel_repaint();        // И панель задач
            }

            // Нажат заголовок окна (LKM) -- если оно есть
            if (y >= w->y1 && y <= w->y1 + 22 && w->state == WINDOW_STATE_DEFAULT && w->no_mover == 0) {
                hit_title = 1;
            }
        }

        // Вызвать callback, если есть
        if (dir) {
            if (w->event_mousedown)
                w->event_mousedown();
        }
        else {
            if (w->event_mouseup)
                w->event_mouseup();
        }

        // Захват и перерисовка moverbox
        if (hit_title && dir) {

            mover_active = hwnd;
            mover_touch  = 0;

            mover_init_x1 = w->x1;
            mover_init_y1 = w->y1;

            copy_mover();
        }
    }

    // Если мышь отпущена, то при активированном "перетаскивателе", восстановить фон
    if (key == PS2_BUTTON_LEFT && dir == 0 && mover_active) {

        restore_mover();

        // Перерисовать старую область
        if (mover_touch) {

            desktop_repaint_bg(mover_active, mover_init_x1, mover_init_y1, mover_width, mover_height);

            window_repaint(mover_active);
            panel_repaint();
        }

        mover_active = 0;
    }
}
