// gcc main.c -o main && ./main example.app

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "memory.c" // Работа с памятью

int main(int argc, char* argv[])
{
    // Буфер строки
    char b[4096], o[4096];
    int  ident = 0, ident_id = 0, ident_last = 0, i, nl, fchar = 0, row = 0, j, quote, def_id = 0;
    int  l;
   
    char** rowheap;           // Список указателей на слова
    char* wordheap;           // Список слов

    // Первичные параметры
    int  rowheap_size = 4096;
    int  wordheap_size = 16384;

    // Выделяем память для массива указателей на слова
    rowheap = (char**)malloc(rowheap_size * sizeof(char *));

    // Для массива слов
    wordheap = (char*)malloc(wordheap_size);

    // Читать файл
    FILE* fp = fopen(argv[1], "r");

    while (1)
    {
        if (fgets(b, 4096, fp) == NULL)
            break;

        // Чтение строки
        // -------------------------------------------------------
        // 1 Определение ее положения в структуре отступов
        // 2 Удаление пробельных символов в начале
        // -------------------------------------------------------

        i = j = quote = ident = 0;
        nl = 1;
         
        while (i < strlen(b))        
        {            
            if (b[i] <= 0x20 && nl) { // Подсчет отступа
                ident++; 
            }
            else 
            {                
                if (b[i] == '#' && quote == 0) break;      // Пропуск комментария
                if (b[i] == '"') { quote = 1 - quote; }    // Открыть или закрыть кавычки. Необходимо для определения строк                
                o[j++] = b[i]; nl = 0;                     // Запись исходящей строки
            }            

            i++;
        }

        // Завершить строку
        o[j] = 0; 

        // Подготовка строки
        // ---------------------------------------        

        // Исполнение операции o.RTRIM()
        for (i = strlen(o) - 1; i > 0; i--) if (o[i] <= 0x20) o[i] = 0; else break;

        // Парсинг строки
        // ---------------------------------------        
        
        // ==> то же, что и strlen(o) == 0, только проще и быстрее
        if (o[0])  
        {
            int iter = 0;

            l = strlen(o); 
            i = 0;

            // Текущий отступ
            ident_id   = ident > ident_last ? ident_id + 1 : (ident < ident_last ? ident_id - 1 : ident_id);
            ident_last = ident;

            quote = 0;
            i = j = 0;

            printf("# %d | %s\n", ident_id, o);
           
            while (1)
            {
                // Запись ID аргумента                
                j = i;

                // Читать до первого пробела, либо до конца  
                while (i < l)
                {
                    if (o[i] == '"') quote = 1 - quote;
                    if (o[i] <= 0x20 && quote == 0) break;
                    i++; 
                }

                o[i] = 0;                
                
                // @TODO Скопировать слово o[j] память и присвоить ID
                printf("%s | %d\n", o + j, j);
                
                if (i == l) break;                
                
                // Пропустить пробелы. Или выход из процедуры
                while (i < l && o[i] <= 0x20) i++; if (i == l) break;
                                                               
                iter++;
            }

            row++;
        }
    }

    fclose(fp);
    return 0;
}