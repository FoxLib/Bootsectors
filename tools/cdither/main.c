#include "cpng.h"

int main(int a, char** b) {

    PNG* png = new PNG();
    
    png->read_png_file("vb.png");

    for (int y = 0; y < png->height; y++)
    for (int x = 0; x < png->width; x++) {
        png->pset(x, y, png->point(x,y) & ~0xff0000);
    }
    
    png->write_png_file("vb2.png");

    return 0;
}
