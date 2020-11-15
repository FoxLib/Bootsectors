void panel_repaint();
void push_event_click(int, int);
void draw_mover();
void restore_mover();
void panel_task_repaint();
void panel_button_start();
void desktop_repaint_bg(int, int, int, int, int);

int desktop;        // HWND окна
int win_start;      // HWND кнопки "пуск"

int desktop_color;
int desktop_button_start;
