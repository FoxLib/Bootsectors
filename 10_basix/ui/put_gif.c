#include "put_gif.h"

/*
 * Рисование GIF
 */
 
void ui_put_gif(uint32_t addr, int x, int y) {
    
    uint16_t left, top, width, height, attrb, lzw_min_bit;
    uint16_t sym;

    // Открыть буферы, если не были ранее открыты
    if (gif_chunks == 0) {
        gif_chunks = kalloc(512 * 1024);
    }
    
    if (gif_surface == 0) {
        gif_surface = kalloc(512 * 1024);
    }
    
    // Картинка является 8-битной, верно
    if ((mm_readb(addr + IMAGE_GIF_BITS) & 0x87) == 0x87) {
        
        // Пропуск заголовка и информации о цвете (пока что)
        addr += IMAGE_GIF_LEN + 256*3;
        
        // Чтение APP секции
        for (;;) {
            
            uint8_t b = mm_readb(addr);
            
            // Картинка найдена
            if (b == ',') {
                
                addr++;
                break;
            }
            // Найден раздел с секциями - пропускать их
            // Пропустить также байт после !
            else if (b == '!') {
                                
                addr += 2;
                for (;;) {
                    
                    uint8_t c = mm_readb(addr);
                    addr++;
                    
                    if (c) {
                        addr = addr + c;
                    } else {
                        break;
                    }
                }
            }
            else {
                return;
            }            
        }
     
        // Информация об изображении
        left        = mm_readw(addr + 0);
        top         = mm_readw(addr + 2);
        width       = mm_readw(addr + 4);
        height      = mm_readw(addr + 6);
        attrb       = mm_readb(addr + 8);
        lzw_min_bit = mm_readb(addr + 9) + 1;
        addr += 10;

        // Должна быть минимальная длина кода 8 (т.е. 8 + 1 = 9 бит)
        if (lzw_min_bit != 9) {
            return;
        }

        int i;
        uint16_t lzw_current = 0;
        uint16_t lzw_dict = 0;
        uint16_t lzw_bits;
    
        // Исходящий поток данных
        uint32_t output = gif_chunks;
        uint32_t chuck_size;

        // Распаковать чанки в монолитный блок
        for (;;) {
            
            chuck_size = mm_readb(addr++); 
            if (chuck_size == 0) {
                break;
            }
            
            for (i = 0; i < chuck_size; i++) {                
                uint8_t t = mm_readb(addr++);
                mm_writeb(output++, t);            
            }
            
        }
  
        uint32_t addr = gif_chunks;
        uint32_t stream = gif_surface;
        
        // Начать распаковку чанков
        for (;;) {                    
            
            uint32_t input = mm_readd( addr );
            
            // Выбор количества бит в зависимости от словаря
            if (lzw_dict <= 0x100 - 2) {
                lzw_bits = 9;
            } else if (lzw_dict <= 0x300 - 2) {
                lzw_bits = 10;
            } else if (lzw_dict <= 0x700 - 2) {
                lzw_bits = 11;
            } else {
                lzw_bits = 12;
            }

            // Сместить и срезать нужное количество битов
            sym  = input >> lzw_current;
            sym &= ((1 << lzw_bits) - 1);
            
            // + Количество бит
            lzw_current += lzw_bits;

            // Переместить к следующей позиции
            while (lzw_current > 7) {
                
                addr++;
                lzw_current -= 8;
            }
            
            if (sym < 0x100) {
                
                // Обычный символ                    
                mm_writeb(stream, sym);
                
                gif_dict[ lzw_dict ].addr = stream;
                gif_dict[ lzw_dict ].size = 2;                    
                
                stream++;
                lzw_dict++;
                
            } 
            // Очистка словаря
            else if (sym == 0x100) {      
                    
                lzw_dict = 0;
                
            }
            // Конец потока
            else if (sym == 0x101) {                    
                break;
                
            }            
            else {
                
                // Откуда копировать (и сколько)
                uint32_t copy_from = gif_dict[ lzw_dict ].addr;
                uint32_t copy_size = gif_dict[ lzw_dict ].size;
                
                // Указатель на текущий поток
                gif_dict[ lzw_dict ].addr = stream;
                
                // Количество символов увеличено +1 от предыдущего
                gif_dict[ lzw_dict ].size = gif_dict[ sym - 0x102 ].size + 1;                
                lzw_dict++;       
                
                // Скопировать "уже виденную" строку
                for (i = 0; i < copy_size; i++) {
                    
                    uint8_t t = mm_readb(copy_from + i);
                    mm_writeb(stream + i, t);
                }    

                stream += copy_size;
            }
        }
        
    }
}
