
#include "gui.h"

void init_windows() {

    uint32_t i, j;

    // Инициализация окон
    window_count = 0;

    // Очень хитрый способ очистить все данные
    for (i = 0; i < WINDOW_MAX; i++) {

        for (j = 0; j < sizeof(struct window); j++) {

            char* p = (char*)(& allwin[i]);
            p[j] = 0;
        }
    }

    // Установить позицию мыши
    mouse_xy(320, 240);
    mouse_show(0);
}

// Инициализировать окно id=[1..n]
void window_init(int id, int x, int y, int w, int h, char* title) {

    struct window* win = & allwin[ id ];

    h += 20; // Учет заголовка

    win->x1 = x;
    win->y1 = y;
    win->x2 = x + w;
    win->y2 = y + h;

    win->w = w;
    win->h = h;

    win->title = title;
    win->bgcolor = 7;

    win->panel = 1;
    win->state = WINDOW_STATE_DEFAULT;
}

// Активировать новое окно
void window_activate(int id) {

    int i;

    for (i = 1; i < WINDOW_MAX; i++) {
        allwin[i].active = 0;
    }

    allwin[id].active = 1;
}

// Создать окно в системе
int window_create(int x, int y, int w, int h, char* title) {

    int id;

    // Найти свободное место в структурах
    for (id = 1; id < WINDOW_MAX; id++) {

        if (allwin[id].in_use == 0) {

            bzero(& allwin[ id ], sizeof(struct window));

            allwin[id].in_use = 1;
            allwin[id].active = 0;

            window_init(id, x-2, y-2, w+4, h+4, title);
            window_activate(id);

            return id;
        }
    }

    return 0;
}

// Закрыть окно
void window_close(int hwnd) {
    
    struct window* win = & allwin[ hwnd ];
    
    int x1 = win->x1, 
        y1 = win->y1, 
        w = win->w, 
        h = win->h;

    // Очистить информацию об окне
    bzero(win, sizeof(struct window));
    
    // Очистить экран за окном
    desktop_repaint_bg(hwnd, x1, y1, w, h);
}

// Нарисовать кнопку
void button(int x1, int y1, int w, int h, int pressed) {

    int i, j;
    int x2 = x1 + w,
        y2 = y1 + h;

    block(x1,   y1,   x2, y2, 7);
    block(x1,   y1,   x2, y1, pressed ? 0  : 15);
    block(x1+w, y1,   x2, y2, pressed ? 15 : 0);
    block(x1,   y1,   x1, y2, pressed ? 0  : 15);
    block(x1,   y1+h, x2, y2, pressed ? 15 : 0);

    if (pressed) {

        // Полусерая область
        block(x1+1, y1+1, x2-1, y2-1, 15);

        for (i = y1+2; i < y2-1; i++)
        for (j = x1+2+i%2; j < x2-1; j += 2)
            pset(j, i, 7);

        block(x1+1, y1+1, x2-1, y1+1, 8);
        block(x1+1, y1+1, x1+1, y2-1, 8);
        block(x1+1, y2-1, x2-1, y2-1, 7);
        block(x2-1, y1+1, x2-1, y2-1, 7);

    } else {

        block(x1+1, y2-1, x2-1, y2-1, 8);
        block(x2-1, y1+1, x2-1, y2-1, 8);
    }
}

// Полное обновление окна
void window_repaint(int id) {

    struct window* win = & allwin[ id ];

    if (win->state != WINDOW_STATE_DEFAULT)
        return;

    // Подложка
    block(win->x1+1, win->y1+1, win->x2-1, win->y2-1, 7);

    // Черный ободок
    block(win->x1,   win->y1,   win->x2,   win->y1, 0);
    block(win->x1,   win->y1,   win->x1,   win->y2, 0);
    block(win->x1,   win->y2,   win->x2,   win->y2, 0);
    block(win->x2,   win->y1,   win->x2,   win->y2, 0);

    // Белый ободок
    block(win->x1+1, win->y1+1, win->x2-1, win->y1+1, 15);
    block(win->x1+1, win->y1+1, win->x1+1, win->y2-1, 15);

    // Заголовок
    block(win->x1+2, win->y1+2, win->x2-2, win->y1+21, win->active ? 1 : 8);

    // Печать самого заголовка
    color(11, -1); print_at(win->x1+6,    win->y1+5, "\x04");
    color(15, -1); print_at(win->x1+6+12, win->y1+5, win->title);
    
    color(0, -1); 

    // Кнопка "закрыть"
    if (win->no_close == 0) {
        button(win->x2 - 19, win->y1 + 5, 15, 14, 0);
        print_at(win->x2 - 15, win->y1 + 3, "x");
    }

    // Отправка repaint
    if (win->event_repaint)
        win->event_repaint();
}

// Назначить событие
void window_event(int hwnd, int event_type, void (*event)()) {

    struct window* win = & allwin[ hwnd ];

    switch (event_type) {

        case EVENT_KEYPRESS:    win->event_keypress = event;  break;
        case EVENT_KEYUP:       win->event_keyup    = event;  break;

        case EVENT_MOUSEDOWN:   win->event_mousedown = event; break;
        case EVENT_MOUSEUP:     win->event_mouseup  = event;  break;
        case EVENT_MOUSEMOVE:   win->event_mousemove = event; break;
        case EVENT_MOUSEOUT:    win->event_mouseout = event;  break;
        case EVENT_MOUSEIN:     win->event_mousein  = event;  break;

        case EVENT_CLOSE:       win->event_close    = event;  break;
        case EVENT_REPAINT:     win->event_repaint  = event;  break;
        case EVENT_TIMER:       win->event_timer    = event;  break;
    }
}
