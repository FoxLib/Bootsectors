#define IMAGE_GIF_WIDTH         0x06      
#define IMAGE_GIF_HEIGHT        0x08
#define IMAGE_GIF_BITS          0x0A
#define IMAGE_GIF_BACKGROUND    0x0B
#define IMAGE_GIF_LEN           0x0D        // Длина заголовка

uint32_t gif_chunks;        // Временные данные (распакованные чанки) 512кб
uint32_t gif_surface;       // Здесь хранится до 512кб буфера распаковки GIF

struct GIF_DICT {
    
    uint32_t addr;
    uint32_t size;
    
};

// Словарь для GIF
struct GIF_DICT gif_dict[4096];
