
// Видеоподсистема
struct DriverVG {

    uint w, h;              // Размер по ширине и высоте (графика)
    uint cx, cy, fr, bg;    // Позиция курсора и цвет символов

    word* canvas;           // Видеохолст (задний буфер)
    byte mode;              // Текстовый или графический режим

    // Функции для работы с текстом
    void (*cursor)(int, int);                   // Установить курсор
    void (*print)(int, int, byte, int, int);    // Печать символа `chr` в (x,y) цвет F, фон B
    void (*scroll)();                           // Скроллинг экрана на 1 вниз

    // С графикой
    void (*pset)(int, int, uint);               // Установка точки (x, y, color)
    void (*block)(int, int, int, int, uint);    // LINE (x1,y1)-(x2,y2),color,bf
};

// Программируемые прерывания
struct DriverPIC {

    void (*keyboard)();     // Обработчик клавиатуры
    void (*fdc)();          // Floppy Disk Controller
    void (*ps2mouse)();     // Обработчик мыши
};

// Дисковый ввод-вывод
struct DriverDISK {
    
    int  (*get_type)(byte);                     // Определить тип устройства на шине
    void (*read)(byte, int, int, void*);        // Чтение сектора (bus|lba|num|dst)
    void (*write)(byte, int, int, void*);       // Запись сектора (bus|lba|num|dst)
    int  (*identify)(byte, void*);              // Получение конфигурации диска (bus|dst)
};

// Обработчик графикии
struct DriverVG   vg;
struct DriverPIC  pic;
struct DriverDISK disk;
