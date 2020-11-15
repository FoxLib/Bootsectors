#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <png.h>

class PNG {

protected:

    int x, y;
    png_byte color_type;
    png_byte bit_depth;

    png_structp png_ptr;
    png_infop info_ptr;
    int number_of_passes;
    int planes;
    png_bytep* row_pointers;

public:

    int width, height;
    int read_png_file(const char* file_name);
    int write_png_file(const char* file_name);

    unsigned int point(int x, int y);
    void pset(int x, int y, unsigned int c);
};
