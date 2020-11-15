/*
 * Компрессия файлов по модицикации LZ77-алгоритма
 * 
 * gcc lz77.c -o lz77
 * 
 * Использование:
 * 
 * ./lz77 < lz77 > /test.lz77
 */
 
#include <stdlib.h>
#include <stdio.h>
 
unsigned int  bit_position   = 0; // Текущий номер бита [0..7]
unsigned char byte_processed = 0; // Текущий обрабатываемый байт

// Расчет количества бит, занимаемого числом
int ceil_log2(unsigned long x) {
    
    static const unsigned long t[5] = {
        0x00000000FFFF0000ull,
        0x000000000000FF00ull,
        0x00000000000000F0ull,
        0x000000000000000Cull,
        0x0000000000000002ull
    };
  
    int k = 16, m = 0, i;

    // Здесь 2^5 итерации = 32 бит
    for (i = 0; i < 5; i++) {
      
        // Обнаружены биты в старшей части
        if (t[i] & x) {

            m  += k; // Известно, что теперь биты начинаются с k-й позиции
            x >>= k; // Сдвинуть вправо на k позиции, для следующей итерации
        }

        k >>= 1; // Уменьшение количества сдвигов вдвое
    }

    return m + 1;
}

// Вставка битов в поток
void bits_insert(FILE* fo, int v, int bits) {
    
    int i;
    for (i = 0; i < bits; i++) {
        
        // Установить следующий бит в байте
        byte_processed |= ((1 << bit_position) * (v & 1));
        
        // Переход на следующий байт?
        if (bit_position == 7) {
            
            fprintf(fo, "%c", (unsigned char)byte_processed);

            bit_position   = 0;
            byte_processed = 0;
            
        } else {
            
            bit_position++;
        }
        
        // К следующему биту
        v >>= 1;
    }    
}

/** Компрессированные данные уходят на stdout
 */
void compress(unsigned char* m, size_t size, FILE* fo) {
    
    int i, j, k;
    
    // Перебор всех символов входящих данных
    for (i = 0; i < size; i++) {

        // Допустимая длина (2..255)
        int length_allowed   = size - i < 255 ? size - i : 255;

        // Допустимая дистанция (1..32767) 
        int distance_allowed = i < 32767 ? i : 32767;

        // Инициализация значения длин и расстояний
        int max_length   = 0;
        int min_distance = 32768;

        // Просмотр "в глубину", для проверки
        for (j = 1; j < distance_allowed; j++) {

            // Тест на длину максимальных совпадений
            int length = 0;

            // Есть первое совпадение
            if (m[i - j] == m[i]) {

                // Подсчет количества следующих совпадений
                for (k = 1; k < length_allowed; k++) {

                    if (m[i - j + k] != m[i + k]) {
                        break;
                    }

                    // Отметить новую допустимую длину
                    length = 1 + k;
                }
            }

            // Есть строка от 2 символов
            // ---------------------
            if (length) {

                // Допуск, если закодированное сообщение занимает меньше бит, чем исходные символы
                // 9 bit (управляющий байт) + N-bit (length) + M-bit (dist) 
                // ---
                if (ceil_log2(length) + ceil_log2(j) + 9 < (length * 8)) {

                    // Длина должна быть максимальной
                    if (max_length <= length) {

                        // А дистанция - минимальной
                        min_distance = min_distance > j ? j : min_distance;
                        max_length   = length;
                    }
                }
            }    
        }
        
        // Если есть последовательность символов, выполнить вставку
        // Иначе выполнить вставку литерала
        if (max_length) {

            
            int cl = ceil_log2(max_length);
            int cd = ceil_log2(min_distance);

            // (А) Вставка управляющего кода
            // cl = 1..8  -> 0..7
            // cd = 1..15 
            bits_insert(fo, 0x100 + ((cl - 1)<<4) + cd, 9);
            
            // (B) Вставка самих управляющих кодов
            bits_insert(fo, min_distance, cd);
            bits_insert(fo, max_length,   cl);

            // Перескочить через "упакованную" длину
            i += max_length - 1;
            
        } else {
            
            // Вставка литерала 9 бит
            bits_insert(fo, m[i], 9);            
        }
    }
    
    // Код завершения
    bits_insert(fo, 0x100, 9);

    // Выгрузка оставшихся
    if (bit_position) {
        fprintf(fo, "%c", (unsigned char)byte_processed);
    }    
}

// *********************************************************************
// Запуск из main()
// *********************************************************************
 
int main(int argc, char* argv[]) {

    // ----------------------------------------
    // Загрузить файл в память
    // ----------------------------------------
    
    FILE* f   = stdin;  // fopen(argv[1], "rb");      argv[1]
    FILE* out = stdout; // argv[2]

    // Размер файла
    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    
    // Выделить память
    unsigned char* m = (unsigned char*)malloc(size);
    unsigned char* t = m;
    
    // Прочитать в память
    fseek(f, 0, SEEK_SET);    
    while (!feof(f)) {            
        
        fread(t, 1, 4096, f);
        t += 4096;    
    }        

    fclose(f);
    
    // ----------------------------------------
    // Компрессия и выдача в stdout/file
    // ----------------------------------------
    
    compress(m, size, out);
    free(m);

    return 0;
}
    
