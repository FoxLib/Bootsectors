struct GUI_window {

    int  x, y, w, h;
    char name[128];
};

int gui_count_windows;
struct GUI_window gui_windows;

void gui_init();
void gui_draw_window(char* name, int x, int y, int w, int h);
