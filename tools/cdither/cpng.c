#include "cpng.h"

int PNG::read_png_file(const char* file_name) {

    // 8 is the maximum size that can be checked
    char header[8];

    planes = 3;

    /* open file and test for it being a png */
    FILE *fp = fopen(file_name, "rb");
    if (!fp)
        printf("[read_png_file] File %s could not be opened for reading", file_name);

    fread(header, 1, 8, fp);
    if (png_sig_cmp((png_const_bytep)header, 0, 8))
        printf("[read_png_file] File %s is not recognized as a PNG file", file_name);

    /* initialize stuff */
    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png_ptr) {
        printf("[read_png_file] png_create_read_struct failed"); return 0; }

    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr) {
        printf("[read_png_file] png_create_info_struct failed"); return 0; }

    if (setjmp(png_jmpbuf(png_ptr))) {
        printf("[read_png_file] Error during init_io"); return 0; }

    png_init_io(png_ptr, fp);
    png_set_sig_bytes(png_ptr, 8);
    png_read_info(png_ptr, info_ptr);

    width       = png_get_image_width(png_ptr, info_ptr);
    height      = png_get_image_height(png_ptr, info_ptr);
    color_type  = png_get_color_type(png_ptr, info_ptr);
    bit_depth   = png_get_bit_depth(png_ptr, info_ptr);

    // Распознавание только валидных
    if (color_type == PNG_COLOR_TYPE_RGB && bit_depth == 8) {
        planes = 3;
    } else if (color_type == PNG_COLOR_TYPE_RGB_ALPHA && bit_depth == 8) {
        planes = 4;
    } else {
        printf("[read_png_file] colortype (%d) is not allowed with bit depth (%d)", color_type, bit_depth); return 0;
    }

    number_of_passes = png_set_interlace_handling(png_ptr);
    png_read_update_info(png_ptr, info_ptr);

    /* read file */
    if (setjmp(png_jmpbuf(png_ptr))) {printf("[read_png_file] Error during read_image"); return 0; }

    row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
    for (y=0; y < height; y++)
        row_pointers[y] = (png_byte*) malloc(png_get_rowbytes(png_ptr, info_ptr));

    png_read_image(png_ptr, row_pointers);
    fclose(fp);

    return 1;
}

int PNG::write_png_file(const char* file_name) {

    /* create file */
    FILE *fp = fopen(file_name, "wb");
    if (!fp) {
        printf("[write_png_file] File %s could not be opened for writing", file_name); return 0; }

    /* initialize stuff */
    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

    if (!png_ptr) {
        printf("[write_png_file] png_create_write_struct failed"); return 0; }

    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr) {
        printf("[write_png_file] png_create_info_struct failed"); return 0; }

    if (setjmp(png_jmpbuf(png_ptr))) {
        printf("[write_png_file] Error during init_io"); return 0; }

    png_init_io(png_ptr, fp);

    /* write header */
    if (setjmp(png_jmpbuf(png_ptr))) {
        printf("[write_png_file] Error during writing header"); return 0; }

    png_set_IHDR(png_ptr, info_ptr, width, height,
                 bit_depth, color_type, PNG_INTERLACE_NONE,
                 PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

    png_write_info(png_ptr, info_ptr);

    /* write bytes */
    if (setjmp(png_jmpbuf(png_ptr))) {
        printf("[write_png_file] Error during writing bytes"); return 0; }

    png_write_image(png_ptr, row_pointers);

    /* end write */
    if (setjmp(png_jmpbuf(png_ptr))) {
        printf("[write_png_file] Error during end of write"); return 0; }

    png_write_end(png_ptr, NULL);

    /* cleanup heap allocation */
    for (y=0; y<height; y++)
        free(row_pointers[y]);

    free(row_pointers);
    fclose(fp);

    return 0;
}

// Прочесть пиксель
unsigned int PNG::point(int x, int y) {

    if (x < 0 || y < 0 || x >= width || y >= height)
        return 0;

    int r = row_pointers[y][planes*x + 0];
    int g = row_pointers[y][planes*x + 1];
    int b = row_pointers[y][planes*x + 2];
    int a = row_pointers[y][planes*x + 3];

    return (r<<16) + (g<<8) + b;
}

// Записать пиксель
void PNG::pset(int x, int y, unsigned int c) {

    if (x < 0 || y < 0 || x >= width || y >= height)
        return;

    row_pointers[y][planes*x + 0] = (c >> 16) & 0xff;
    row_pointers[y][planes*x + 1] = (c >> 8) & 0xff;
    row_pointers[y][planes*x + 2] = c & 0xff;
}
