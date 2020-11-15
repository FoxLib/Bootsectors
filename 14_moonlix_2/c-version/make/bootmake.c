// Компиляция
// gcc bootmake.c -o bootmake

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/*
 * Пути пока что захардкожены
 */

int main(int argc, char* argv[])
{
    int status = 0;
    
    if (argc > 1) 
    {
        FILE* fo = fopen("../fdd.img", "r+");    

        // Отладочный BOOT-сектор
        // -------------------------------------------------
        if (strcmp(argv[1], "dboot") == 0) 
        {
            // Собрать бут-сектор
            int S = system("cd ../boot && fasm boot_bochs.asm && cd ../make");

            // Записать
            if (S == 0)
            {
                FILE* fi = fopen("../boot/boot_bochs.bin", "r");
                
                char boot[512];
                fread(boot, 1, 512, fi);
                fseek(fo, 0, SEEK_SET);
                fwrite(boot, 1, 512, fo);    
                fclose(fi);
                
                printf("Done\n");
                status = 0;
            }
            else 
            {
                printf("[!] ERROR: Boot not written correctly\n");   
                status = 1;
            }
        }   
        // Ассемблировать и скопировать ядро
        // -------------------------------------------------
        else if (strcmp(argv[1], "copyk") == 0)
        {
            int S = system("cd .. && fasm kernel.asm && cd make");

            if (S == 0)
            {
                FILE* fi = fopen("../kernel.bin", "r");
                
                char boot[32768];
                fread(boot, 1, 32768, fi);
                fseek(fo, 512, SEEK_SET); // Сразу за boot
                fwrite(boot, 1, 32768, fo);    
                fclose(fi);

                printf("Kernel copied\n");
                status = 0;
            }
            else 
            {
                printf("[!] ERROR: Kernel not compiled\n");      
                status = 1;
            }            
        }

        fclose(fo);
    }
    else {
        printf("Usage: <dboot, copyk>\n");        
    }

    return status;
}