/*
 * gcc fas.c -o fas
 * ---
 * Трансляция ассемблерных кодов в fasm
 */

 #include <stdio.h>
 #include <string.h>
 #include <stdlib.h>

 #define LOOKUP_MAX 6

// Поиск важных директив
char* lookup[LOOKUP_MAX] = {
    /* 01 */ "string",
    /* 02 */ "long",
    /* 03 */ "comm", // Структуры
    /* 04 */ "byte", // 1 байт
    /* 05 */ "zero", // нули
    /* 06 */ "value" // word ptr
};

int search(char* needle)
{
    int i;
    for (i = 0; i < LOOKUP_MAX; i++) {
        
        // http://www.cplusplus.com/reference/cstring/strcmp/
        // 0 = the contents of both strings are equal
        if (!strcmp(lookup[i], needle)) { 
            return 1 + i;
        }
        
    }
    return 0;
}

int cmpstring(char* input, char* needle) 
{
    int i, l = strlen(needle);
    for (i = 0; i < l; i++) if (input[i] != needle[i]) return 0;

    return 1;
}

int is_num(char a)
{
    return (a >= '0') && (a <= '9') ? 1 : 0;
}

int main(int argc, char* argv[])
{
    if (argc > 1)
    {
        // Входная строка : Выходная строка
        char bufl[16384], bufo[16384];

        // tmp-string
        char str[256], out[256];

        // Имя файла для локальных меток
        char local[256];

        int lines = 0, i, j, k, x, ppc;
        int l = strlen(argv[1]);

        int repeat; // Повтор сканирования строки

        // Допуск только .s файлов
        if (strcmp(argv[1] + l - 2, ".s") == 0) 
        {
            // Создать строку
            strcpy(out, argv[1]);
            strcpy(out + l - 2, ".asm");

            // Локальное имя
            if (argv[1][0] == '.' && argv[1][1] == '.') {
                strcpy(local, argv[1] + 3);
                l -= 3;
            } 
            else {
                strcpy(local, argv[1]);
            }            

            for (i = 0; i < l-2; i++) {

                // Замена [^a-zA-Z0-9] на "_"
                if (!(local[i] >= 'A' && local[i] <= 'Z') && !(local[i] >= 'a' && local[i] <= 'z') && !(local[i] >= '0' && local[i] <= '9')) {
                    local[i] = '_';
                }
            }
            local[l-2] = 0;

            printf("Local \"%s\"\n", local);         
            printf("Translate \"%s\"\n", argv[1]);         

            FILE* rd = fopen(argv[1], "r");
            FILE* wr = fopen(out, "w");

            while (!feof(rd)) 
            {
                fgets(bufl, 65536, rd);
              
                do
                {
                    repeat = 0;

                    // Пропуск комментариев
                    if (bufl[0] == '#') continue;

                    // Это - директивы препроцессора
                    if (bufl[0] == '\t' && bufl[1] == '.') 
                    {
                        // Имя препроцессорного макроса
                        sscanf(bufl + 2, "%s ", str); 

                        // Особые методы обработки мета-данных
                        ppc = search(str);

                        // Особые методы обработки мета-данных
                        // ----
                        if (ppc) {
                            
                            // Создать Zero-Terminated String (в любом случае)
                            if (ppc == 1)
                            {   
                                bufl[ strlen(bufl) - 1 ] = 0; // Слегка укоротить                                
                                strcpy(bufo, bufl + 8); // Временная строка

                                k = 0;
                                while (k < strlen(bufo)) 
                                {
                                    // Конструкция \[0-9]{3}
                                    if ((bufo[k] == '\\') && is_num(bufo[k+1]) && is_num(bufo[k+2]) && is_num(bufo[k+3]))
                                    {
                                        // Число находится в "\XXX"
                                        if (bufo[k-1] == '"' && bufo[k+4] == '"') 
                                        {
                                            bufo[k - 1] = bufo[k+1] == '0' ? ' ' : bufo[k+1];
                                            bufo[k] = bufo[k+2];
                                            bufo[k+1] = bufo[k+3];
                                            bufo[k+2] = 'o';
                                            bufo[k+3] = ' ';
                                            bufo[k+4] = ' ';
                                            k += 4;
                                        }
                                        // В начале
                                        else if (bufo[k-1] == '"') 
                                        {
                                            for (x = strlen(bufo) + 1; x > k + 3; x--) bufo[x] = bufo[x - 1];

                                            bufo[k - 1] =  bufo[k+1] == '0' ? ' ' : bufo[k+1];
                                            bufo[k]     = (bufo[k+2] == '0') && (bufo[k-1] == ' ') ? ' ' : bufo[k+2];
                                            bufo[k+1]   = bufo[k+3];
                                            bufo[k+2]   = 'o';
                                            bufo[k+3]   = ',';
                                            bufo[k+4]   = '"';

                                            k += 5; 
                                        }
                                        // В конце
                                        else if (bufo[k+4] == '"') {

                                            for (x = strlen(bufo) + 1; x > k; x--) bufo[x] = bufo[x - 1];

                                            bufo[k] = '"';
                                            bufo[k+1] = ',';
                                            bufo[k+5] = 'o';

                                            bufo[k+3] = (bufo[k+3] == '0') && (bufo[k+2] == '0') ? ' ' : bufo[k+3];
                                            bufo[k+2] = bufo[k+2] == '0' ? ' ' : bufo[k+2];

                                            k += 6;
                                        }                                        
                                        // Посередине
                                        else 
                                        {
                                            for (x = strlen(bufo) + 1; x > k; x--) bufo[x] = bufo[x - 1];

                                            bufo[k] = '"';
                                            bufo[k+1] = ',';

                                            bufo[k+3] = (bufo[k+3] == '0') && (bufo[k+2] == '0') ? ' ' : bufo[k+3];
                                            bufo[k+2] = bufo[k+2] == '0' ? ' ' : bufo[k+2];

                                            for (x = strlen(bufo) + 3; x > k + 4; x--) bufo[x] = bufo[x - 3];

                                            bufo[k+5] = 'o';
                                            bufo[k+6] = ',';
                                            bufo[k+7] = '"';

                                            k += 8;
                                        }                                        
                                    }
                                    else {
                                        k++;
                                    }
                                }        
                                
                                // printf("%s\n", bufo);
                                
                                sprintf(out, "\tdb %s,0\n", bufo);                                
                                fwrite (out, strlen(out), 1, wr);
                            }
                            // Dword ptr: требуется повтор для проверки на .LC, к примеру
                            else if (ppc == 2) 
                            {
                                repeat = 1;
                                bufl[strlen(bufl)-1] = 0;
                                sprintf(bufl, "\tdd %s\n", bufl + 6);
                            }
                            // Word ptr: требуется повтор для проверки на .LC, к примеру
                            else if (ppc == 6) 
                            {
                                repeat = 1;
                                bufl[strlen(bufl)-1] = 0;
                                sprintf(bufl, "\tdw %s\n", bufl + 7);
                            }                            
                            // Структуры
                            else if (ppc == 3) {

                                int  ssize, salign;
                                char lc[256];

                                // Сканирование строки по шаблону
                                sscanf(bufl + strlen(str) + 3, "%[^,],%d,%d", lc, &ssize, &salign);

                                sprintf(out, "%s: times %d db 0\n", lc, ssize);
                                fwrite(out, strlen(out), 1, wr);
                            }
                            // Байт
                            else if (ppc == 4) 
                            {
                                repeat = 1;             
                                bufl[strlen(bufl)-1] = 0;                   
                                sprintf(bufl, "\tdb %s\n", bufl + 6);
                            }   
                            // Нули
                            else if (ppc == 5) 
                            {
                                int bsize;

                                repeat = 1;             
                                bufl[strlen(bufl)-1] = 0;   
                                sscanf(bufl + strlen(str) + 3, "%d", &bsize);                
                                sprintf(bufl, "\ttimes %d db 0\n", bsize);
                            }                           
                        }                
                    }
                    // Обычные ассемблерные инструкции
                    else 
                    {
                        i = j = 0;
                        while (i < strlen(bufl))
                        {                        
                            // Указатель на ПАМЯТЬ
                            // ---------------------------
                            if (cmpstring(bufl + i, " PTR [")) 
                            {
                                i += 4; 
                                continue; 
                            }
                            // Указатель на переменную
                            // ---------------------------
                            else if (cmpstring(bufl + i, " PTR ")) {

                                // Делаем вместо " PTR " -> " ["
                                strcpy(out + j, " [");

                                // Начинаем сканировать после PTR
                                k  = i + 5;

                                // Сместим вправо на " [" (2 символа)
                                j += 2;

                                // Перемещаем строку пока не будет либо "\n", либо ","
                                while (k < strlen(bufl))
                                {
                                    if (bufl[k] == '\n' || bufl[k] == ',') {
                                        break;
                                    }

                                    // Копируется байт (имя)
                                    out[j++] = bufl[k++];
                                }

                                // Фиксируем точку останова (например ",")
                                i = k;
                              
                                // Завершаем указатель в память
                                out[j++] = ']'; 
                            }
                            // Локальные метки
                            else if (cmpstring(bufl + i, ".LC")) 
                            { 
                                strcpy(out + j, local);
                                strcpy(out + j + strlen(local), ".LC"); 

                                // [!] Потребуется второй проход для строки
                                j += 3 + strlen(local); 
                                i += 3; 

                                continue; 
                            }
                            else if (cmpstring(bufl + i, "OFFSET FLAT:")) { i += 12; continue; }                            

                            // Иначе просто копируем символ
                            // ---------------------------
                            out[j] = bufl[i];

                            i++; j++;
                        }

                        // Итоговая строка
                        out[j] = 0;

                        // printf("%s", bufl);
                        fwrite(out, strlen(out), 1, wr);

                        lines++;
                    } 
                }
                while (repeat);
            }         

            fclose(wr);
            fclose(rd);

            printf("Complete [%d] lines\n", lines);

            return 0;
        }
        else {
            printf("Only .s files allowed\n");
            return 1;
        }        
    }
    else 
    {         
        printf("Usage: file.s\n");
        return 2;
    }
}