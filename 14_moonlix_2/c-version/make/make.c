#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

/*
 * @required fas, bootmake (должны быть собраны)
 * gcc make.c -o make
 * 
 * Полная и бесповоротная сборка всех используемых файлов
 * с последующей мощной компиляцей и выгрузкой на FDD
 */

void hl(char* cl, char* s) {    
    printf("\x1b[%sm%s\x1b[0m", cl, s);
}

int main(int argc, char* argv)
{
    char str[2048]; // Вход
    char sup[2048]; // Строка на выход 
    char file[2048], sfile[2048]; // Имя файла (путь до компиляции)
    char basename[2048]; // Имя файла (базовое)

    char dir[2048];
    char cmd[4096];

    unsigned ts_tmp, up, i, j, k;
    struct   stat attrib;    
    char     cwd[1024];
    int      s1, s2, fail = 0;

    getcwd(cwd, sizeof(cwd));

    printf("\n");

    FILE* fp = fopen("makefiles", "r");
    FILE* fw = fopen("makefiles.tmp", "w");

    while (!feof(fp)) {

        // Считать строку из файла, если она есть
        if (fgets(str, 2048, fp) == NULL) {
            break;
        }

        if (str[0] == '#') { continue; }
        if (strlen(str) <= 1) { continue; }

        sscanf(str, "%d %s", &ts_tmp, file);

        // Обновлять или нет строку
        up = 0;

        // получение последнего изменния файла
        stat(file, &attrib);

        // Директорию, в которую нужно зайти компилятору
        strcpy(dir,   file);
        strcpy(sfile, file);

        for (i = strlen(dir) - 1; i > 0; i--) 
        {
            if (dir[i] == '/') 
            {   
                // Скопировать имя файла (базовое)
                k = 0; for (j = i + 1; j <= strlen(dir); j++) { basename[k++] = dir[j]; }               

                dir[i] = 0;
                break;
            }
        }

        // Собрать файлы - преваращение в ASM
        if (ts_tmp < (int)attrib.st_mtime) 
        {            
            // 1 Этап: компиляция файла
            // -------------------------------------------------
            sprintf(cmd, "cd %s && gcc -c -masm=intel -m32 -fno-stack-protector -fno-asynchronous-unwind-tables %s -S ", dir, basename);
            s1 = system(cmd); printf("%d | %s\n", s1, cmd);

            // 2 Этап: преобразование
            // -------------------------------------------------
            sfile[strlen(sfile)-1] = 's'; // c->s
            sprintf(cmd, "./fas %s ", sfile);
            s2 = system(cmd); printf("%d | %s\n", s2, cmd);

            chdir (cwd);

            if (s1 == 0 && s1 == 0) {
                up = 1;
            }
            else {
                fail = 1;
                printf("# ERROR with compiler\n");
                up = 0;
            }
        }
       
        // Записать новые значения для собранных файлов
        // --------------------------------------------
        if (up) {

            printf(">>> COMPLETE BUILD [%s]\n\n", file);
            sprintf(sup, "%d %s\n", (int)attrib.st_mtime, file);
        } 
        else {
            sprintf(sup, "%s", str);
        }

        fputs(sup, fw);
    }

    // Выполнение операции компиляции через fasm и запись на FDD
    int sbm = system("./bootmake copyk");
    system("mv makefiles.tmp makefiles");

    // Ошибок при сборке нет
    if (fail == 0 && sbm == 0) {
        printf("\x1b[%sm%s\x1b[0m", "1;32", "OK, BUILD SUCCESSFUL\n");
    } else {
        printf("\x1b[%sm%s\x1b[0m", "1;7", "FAIL\n");
    }

    printf("\n");

    fclose(fp);
    fclose(fw);
    return 0;
}