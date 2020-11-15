#define WINDOW_MAX  64      // Максимум окон

// Режимы window.state
#define WINDOW_STATE_NONE       0       // Нет окна
#define WINDOW_STATE_COLLAPSE   1       // Есть, но скрыто
#define WINDOW_STATE_DEFAULT    2       // Окно показано

// Идентификаторы событий в окне
#define EVENT_KEYPRESS      1
#define EVENT_KEYUP         2
#define EVENT_MOUSEDOWN     3
#define EVENT_MOUSEUP       4
#define EVENT_MOUSEMOVE     5
#define EVENT_MOUSEOUT      6
#define EVENT_MOUSEIN       7
#define EVENT_CLOSE         8
#define EVENT_REPAINT       9
#define EVENT_TIMER         10

struct window {

    uint8_t in_use;         // Это окно загружено в систему?
    uint8_t active;         // Окно активно (=1)
    uint8_t panel;          // Показано в панели
    uint8_t state;          // =0 Не показано =1 Свернуто =2 Обычный режим

    // Размеры окна и внешний вид
    int     x1, y1;
    int     x2, y2;
    int     w, h;
    char*   title;
    uint8_t bgcolor;

    // События, которые может обрабатывать окно
    void    (*event_keypress)();
    void    (*event_keyup)();
    void    (*event_mousedown)();
    void    (*event_mouseup)();
    void    (*event_mousemove)();
    void    (*event_mouseout)();
    void    (*event_mousein)();
    void    (*event_close)();
    void    (*event_repaint)();
    void    (*event_timer)();
};

// Зарегистрированные в системе окна
struct window allwin[ WINDOW_MAX ];

int  window_count; // Количество окон
