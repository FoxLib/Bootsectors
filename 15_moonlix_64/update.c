// gcc update.c -o update
// ./update moon.bin flash.img

// ... проблема записи > 8kb (2 страницы)

#define READ_BYTE(x)  (cluster[x])
#define READ_WORD(x)  (cluster[x] + 256 * cluster[x+1])
#define READ_DWORD(x) (cluster[x] + 256 * cluster[x+1] + 65536 * cluster[x+2] + 16777216 * cluster[x+3])

#include <stdlib.h>
#include <stdio.h>

unsigned int fat_cluster, data_cluster, per_cluster, fat_size;

// Номер следующего кластера
int get_next_cluster(FILE* f, int cluster_id)
{
    int c4 = cluster_id * 4;
    int fat_sector = c4 / 512,
        fat_index  = c4 % 512;

    unsigned char cluster[512];

    // Позиционирование в FAT
    fseek(f, 512 * (fat_cluster + fat_sector), SEEK_SET);
    fread(cluster, 1, 512, f);

    return READ_DWORD(fat_index);
}

// Удаление кластера или замена 
void update_cluster(FILE* f, int cluster_id, int value) {

    int c4 = cluster_id * 4;
    int fat_sector = c4 / 512,
        fat_index  = c4 % 512;
    int ptr = 512 * (fat_cluster + fat_sector);

    unsigned char cluster[512];

    // Позиционирование в FAT
    fseek(f, ptr, SEEK_SET);
    fread(cluster, 1, 512, f);

    // Обновление данных кластера
    cluster[fat_index  ] =  value & 0xff;
    cluster[fat_index+1] = (value >> 8) & 0xff;
    cluster[fat_index+2] = (value >> 16) & 0xff;
    cluster[fat_index+3] = (value >> 24) & 0xff;

    // Запись обновленных данных
    fseek(f, ptr, SEEK_SET);
    fwrite(cluster, 1, 512, f);
}

int main(int argc, char* argv[])
{
    unsigned char cluster[131072]; // Максимальный размер кластера
    unsigned int 
        start, i, j, k, 
        root_cluster, next_cluster, cluster_id, eol,
        cluster_bytes,
        found_at = 0, base_at = 0, base_root = 0;  

    int previous_cluster = 0, filesize = 0; // Размер входного файла

    if (argc > 2)
    {
        FILE* f = fopen(argv[1], "r");  // Входной файл для записи
        FILE* w = fopen(argv[2], "r+"); // Образ диска

        // Скачать первый сектор
        fseek(w, 0, SEEK_SET);
        fread(cluster, 1, 512, w);

        fseek(f, 0, SEEK_END); 
        filesize = ftell(f);
        fseek(f, 0, SEEK_SET); 

        // Указатель на первый сектор
        start = READ_WORD(0x1bc) - 0x7c00 + 8;
        start = READ_DWORD(start);

        // Загрузка первого сектора
        fseek(w, 512 * start, SEEK_SET);
        fread(cluster, 1, 512, w);

        //             раздел  резервированные
        fat_cluster  = start + READ_WORD(0xe);
        fat_size     = READ_DWORD(0x24);

        //             смещение FAT  на FAT     кол-во FAT
        data_cluster = fat_cluster + fat_size * READ_BYTE(0x10); 

        per_cluster  = READ_BYTE(0xD);
        root_cluster = READ_DWORD(0x2C);

        cluster_bytes = per_cluster * 512;

        do
        {
            // Считываем кластер с данными
            fseek(w, 512 * (data_cluster + per_cluster*(root_cluster - 2)), SEEK_SET);
            fread(cluster, 1, 512 * per_cluster, w);
            
            // Перебираем элементы в кластере
            for (i = 0; i < per_cluster * 32; i++)
            {
                k = i * 32;

                // Найден файл
                if (cluster[k] == 'M' && cluster[k+1] == 'O' && cluster[k+2] == 'O' && cluster[k+3] == 'N' &&
                    cluster[k+7] == ' ' && cluster[k+8] == 'B' && cluster[k+9] == 'I' && cluster[k+10] == 'N') {

                    base_at   = k;
                    found_at  = READ_WORD(k + 0x14) * 65536 + READ_WORD(k + 0x1A);
                    break;                   
                }
            }

            // Строка найдена успешно
            if (found_at) {
                break;
            }

            // Считываем номер следующего кластера (если это реально понадобится)
            root_cluster = get_next_cluster(w, root_cluster);           
        }
        while (0);

        // Отладочная информация
        printf("found_at = %x, fs = %d / offset = %x\n", found_at, filesize, 512 * (data_cluster + (found_at - 2) * per_cluster));   

        // Для удаления цепочки
        base_root = found_at;

        // Теперь последовательно стираем данные из FAT
        // -------------------------------------------------------------------------------
        do
        {
            next_cluster = get_next_cluster(w, base_root);           
            update_cluster(w, base_root, 0);
            base_root = next_cluster;

        }
        // Удалять кластеры до тех пор, пока не будет конец или 0 - кластер свободен
        while (base_root > 0 && base_root < 0x0ffffff0);

        // Записывается обновление файла
        // -------------------------------------------------------------------------------

        // Получим код EOL
        eol = get_next_cluster(w, 1);      

        // Записываем первый кластер с данными (как конечный)
        update_cluster(w, found_at, eol);  

        // Запомним позицию данного кластера
        previous_cluster = found_at;

        // Очистка кластера перед записью
        for (i = 0; i < cluster_bytes; i++) cluster[i] = 0;       
        fread(cluster, 1, cluster_bytes, f); // Читать данные
        fseek(w, 512 * (data_cluster + (found_at - 2) * per_cluster), SEEK_SET); // Область памяти
        fwrite(cluster, 1, cluster_bytes, w); // Запись

        // Представим, что мы записали кластер (хотя может быть меньше кластера)
        filesize -= cluster_bytes;

        // Все еще осталось, что записать в других кластерах
        if (filesize > 0)
        {
            // Поиск свободных кластеров (максимальное кол-во элементов в FAT = sectors_by_fat * 512 / 4)
            for (i = 2; i < fat_size * 512 / 4; i++)         
            {
                // Проверить на свободный кластер
                cluster_id = get_next_cluster(w, i);   

                // Найден свободный блок
                if (cluster_id == 0)
                {
                    // debug
                    // printf("%x | %x\n", i, cluster_id);        

                    // Записать в предыдущий кластер номер текущего (формирование цепи)
                    update_cluster(w, previous_cluster, i);
                    
                    // Сохранить номер текущего кластера для формирования цепи
                    previous_cluster = i;

                    // Запись нового кластера             
                    for (j = 0; j < cluster_bytes; j++) cluster[j] = 0;       
                    fread(cluster, 1, cluster_bytes, f); // Читать данные
                    fseek(w, 512 * (data_cluster + (i - 2) * per_cluster), SEEK_SET); // Область
                    fwrite(cluster, 1, cluster_bytes, w); // Запись

                    // Записано [per_cluster * 512] байт
                    filesize -= cluster_bytes;

                    // Файл закончен - записать EOL и выйти
                    if (filesize <= 0)
                    {
                        update_cluster(w, i, eol);
                        break;
                    }
                }            
            }
        }        

        fclose(f);
        fclose(w);
    }
    else {
        printf("./update moon.bin flash.img\n");
    }
    return 0;
}