#define KB_WAIT     4096

enum PS2Buttons {

    PS2_BUTTON_LEFT         = 1,
    PS2_BUTTON_RIGHT        = 2,
    PS2_BUTTON_MIDDLE       = 4
};

struct PS2Handler {

    int     pressed;                // Нажатые кнопки
    int     time_at;                // Время последнего клика
    int     mouse_state;            // Статус нажатых кнопок мыши
    int     x, y, cmd;
};

struct PS2Handler ps2;

/** PROTOTYPES */
void kb_delay();
void kb_wait(int rw);
void kb_wait_not();
void kb_cmd(int comm);
void kb_write(int data);
int  kb_read();
void ps2_mouse_handler();
void ps2_init_mouse();
