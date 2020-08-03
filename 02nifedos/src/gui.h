struct GUI_window {

    int  x, y, w, h;
    char name[128];
};

static const uint32_t GUITopGradient[26] = {
    0x3e96ff, 0x2c8aff, 0x0370ff, 0x0465f1,
    0x015ce9, 0x005ae7, 0x0055e3, 0x0055e3,
    0x0055e3, 0x0055e6, 0x0055e6, 0x0056e8,
    0x0054ec, 0x0055f1, 0x005af2, 0x015df4,
    0x005df9, 0x0162fa, 0x0269fe, 0x036cfe,
    0x036cfe, 0x0269fe, 0x0266fb, 0x0162fa,
    0x014de1, 0x0043cf
};


int gui_count_windows;
struct GUI_window gui_windows;

void gui_init();
void gui_draw_window(char* name, int x, int y, int w, int h);
