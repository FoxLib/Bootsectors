// gcc boot.c -o boot

#include <stdlib.h>
#include <stdio.h>

void main(int argc, char* argv[])
{
    char message[256];
    char sector[512];
    char pt[16], vt[66];
    char i;
    int  start, size, type, j, k;

    FILE* f;
    FILE* g;

    if (argc > 2)
    {
        // LINUX
        sprintf(message, "%s dd if=%s of=/tmp/sector.img count=1", argc > 3 ? argv[3] : "", argv[1]);     
        system(message);          

        f = fopen("/tmp/sector.img", "r");

        // Скопировать 66 байт
        fseek(f, 0x1BE, SEEK_SET);
        fread(vt, 1, 66, f);

        for (i = 0; i < 4; i++)
        {
            fseek(f, 0x1BE + 16*i, SEEK_SET);
            fread(pt, 1, 16, f);

            // Информаци о разделе
            type  = pt[4];
            start = pt[8]  + pt[9]*256  + pt[10]*65536 + pt[11] * 16777216;
            size  = pt[12] + pt[13]*256 + pt[14]*65536 + pt[15] * 16777216;

            // FAT32. Маленькие разделы не учитывать
            // -------------------------------------
            if (type == 0xb && size > 0x100)
            {
                // Прочитать сектор для записи
                g = fopen(argv[2], "r"); fread(sector, 1, 512, g); fclose(g);

                // Записать таблицу разделов (восстановить)
                for (j = 0x1be; j < 0x200; j++) sector[j] = vt[j - 0x1be];

                // Записать указатель на реальный адрес (необходимо для update.c)
                k = 0x7DBE + 16*i;
                sector[0x1bc] = (char)(k & 0xff);
                sector[0x1bd] = (char)((k >> 8) & 0xff);

                // Записать на диск сектор
                g = fopen("/tmp/sector_write.img", "w"); fwrite(sector, 1, 512, g); fclose(g);
                sprintf(message, "%s dd conv=notrunc if=/tmp/sector_write.img of=%s count=1", argc > 3 ? argv[3] : "", argv[1]);     
                system(message);          
            } 
        }
       
        fclose(f);
    }
    else {
        printf("boot </dev/sdX or disk.img> <boot(512 bytes)>\n");
    }
}