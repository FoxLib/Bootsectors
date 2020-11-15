// cc diskfat32.c -o diskfat32 && ./diskfat32 ../../c.img

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "disk.h"
#include "functions.c"

/*
 * Основная работа с файлами на образе диска
 */

int main(int argc, char* argv[])
{
    if (argc <= 2) {

        printf("p чтение информации о partitions\n");
        printf("v просмотр корневого каталога\n");
        printf("u <путь-к-файлу-в-img> <реальный-файл> -- залить файл на img\n");
        printf("g <путь-к-файлу-в-img> <реальный-файл> -- скачать файл в realfile\n");

    } else {

        // Открыть диск для чтения и записи
        if (disk = fopen(argv[1], "r+")) {

             // поиск требуемого файла (если найден, то обновить)
            int dir;

            // Чтение данных о PARTITIONS
            read_partitions();
            get32_fat_bpb();

            switch (argv[2][0])
            {
                // Чтение информации о partitions
                case 'p':
                    
                    disk_print_partitions();
                    break;

                // Просмотреть содержимое корневого каталога
                case 'v': 

                    if (argc == 3)     
                         print_directory_root(); 
                    else print_directory(atoi(argv[3]));          
                    break;      

                // обновление файла
                case 'u':

                    // Если файл был найден, то обновить его
                    if (dir = search_file(argv[3])) {
                        update_file(dir, argv[4]);
                    } else { printf("file [%s] not found\n", argv[3]); }
                    
                    break;

                // прочитать файл
                case 'g':

                    // Если файл был найден, то обновить его
                    if (dir = search_file(argv[3])) {
                        read_file(dir, argv[4]);
                    } else { printf("file [%s] not found\n", argv[3]); }

                    break;

                default:

                    printf("Не выбрана правильная опция\n");
            }            

            fclose(disk);

        } else {
            printf("Первый параметр должен указывать на диск: файл не был открыт\n");
        }  
    }

    return 0;
}