int create_gdt(uint32_t, uint32_t, uint8_t);

// Драйвер видеокарты
struct DriverVG {

    // Размер по ширине и высоте
    int w, h;

    // Видеохолст (задний буфер)
    uint16_t* canvas;

    // Установка точки (x, y, color)
    void (*pset)(int, int, uint);

    // LINE (x1,y1)-(x2,y2),color,bf
    void (*block)(int, int, int, int, uint);
};

// Обработчик графикии
struct DriverVG vg;
