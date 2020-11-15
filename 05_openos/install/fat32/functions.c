// Прочитать сектор в память
void read_sector(unsigned int n) 
{
    fseek(disk, n * 512, SEEK_SET);
    fread(sector, 1, 512, disk);
}

// Сохранение сектора
void write_sector(unsigned int n)
{
    fseek(disk, n * 512, SEEK_SET);
    fwrite(sector, 1, 512, disk);
}

// Чтение нужного кластера в память
void read_cluster(unsigned int n)
{
    fseek(disk, 512 * (data_cluster  + (n-2) * fat32_cluster_size), SEEK_SET);
    fread(cluster, 1, 512 * fat32_cluster_size, disk);
}

// Запись кластера на диск
void write_cluster(unsigned int n)
{
    fseek(disk, 512 * (data_cluster  + (n-2) * fat32_cluster_size), SEEK_SET);
    fwrite(cluster, 1, 512 * fat32_cluster_size, disk);
}

unsigned int get_word(n) 
{
    return cluster[n] + (cluster[n+1] << 8);
}

unsigned int get_dword(n) 
{
    return cluster[n] + (cluster[n+1] << 8) + (cluster[n+2] << 16) + (cluster[n+3] << 24);
}

// Чтение и разбор "partitions"
void read_partitions()
{
    int i, j;

    read_sector(0);

    for (i = 0; i < 4; i++) {

        j = 16*i + 0x1be;         

        // Тип ФС
        switch (sector[j + 4]) {

            case 0x0B: 
                
                diskpart[i].is_fat32 = 1;
                diskpart[i].lba = sector[j + 8] + (sector[j + 9] << 8) + (sector[j + 10] << 16) + (sector[j + 11] << 24);
                diskpart[i].ln  = sector[j + 12] + (sector[j + 9] << 13) + (sector[j + 14] << 16) + (sector[j + 15] << 24);
                break;

            default: diskpart[i].is_fat32 = 0;
        }     
    }
}

// Печать состояния по диску
void disk_print_partitions()
{
    printf("FAT32 is in:\n");

    int i;
    for (i = 0; i < 4; i++) {

       if (diskpart[i].is_fat32) {
           printf("0x%x (start) %d mb.\n", 512 * diskpart[i].lba, diskpart[i].ln * 2 / 1024);
       }
    }

}

// Поиск начальной позиции FAT32 и записать значение в [pstart]
void get32_fat_bpb()
{
    int i;
    for (i = 0; i < 4; i++) {

        // Обнаружение только для FAT32
        if (diskpart[i].is_fat32) { 

            pstart = diskpart[i].lba;

            // Прочитать 1-сектор 
            read_sector(pstart);

            // Основные данные по FAT32 диску
            fat32_cluster_size = sector[0x0D];
            fat32_reserved     = sector[0x0E] + (sector[0x0F]<<8);
            fat32_count        = sector[0x10];
            fat32_size         = sector[0x24] + (sector[0x25]<<8) + (sector[0x26]<<16) + (sector[0x27]<<24);
            fat32_root         = sector[0x2C] + (sector[0x2D]<<8) + (sector[0x2E]<<16) + (sector[0x2F]<<24);

            // Расчет смещений
            data_fat           = pstart + fat32_reserved;
            data_cluster       = data_fat + (fat32_count * fat32_size);

            break;
        }
    }
}

// Получить следующий кластер - если он есть
unsigned int get_next_cluster(unsigned int n)
{    
    // 128 кластеров на 1 сектор
    unsigned int fent = n / 128;

    // Чтение нужного сектора
    read_sector(data_fat + fent);

    // Указатель на нужную запись 
    fent = 4 * (n % 128);

    // Номер кластера
    return sector[fent] + (sector[fent+1] << 8) + (sector[fent+2] << 16) + (sector[fent+3] << 24);
}

// Сохранить указатель на следующий кластер
void set_fat_cluster(unsigned int n, unsigned int m)
{
    // 128 кластеров на 1 сектор
    unsigned int fent = n / 128, fitem;    

    // Чтение нужного сектора
    read_sector(data_fat + fent);

    // Указатель на нужную запись 
    fitem = 4 * (n % 128);

    sector[fitem]   = m & 0xff;
    sector[fitem+1] = (m >> 8) & 0xff;
    sector[fitem+2] = (m >> 16) & 0xff;
    sector[fitem+3] = (m >> 24) & 0xff;

    // Сохранить новый указатель
    write_sector(data_fat + fent);
}

// Поиск номера свободного кластера
unsigned int find_free_cluster()
{
    unsigned int i, j, cl;

    // перебор секторов fat
    for (i = 0; i < fat32_size; i++) {

        read_sector(data_fat + i); 

        // перебор кластеров
        for (j = 0; j < 512; j += 4) {

            cl = sector[j] + (sector[j+1] << 8) + (sector[j+2] << 16) + (sector[j+3] << 24);
            if (cl == 0) {

                // Номер кластера найден
                return (j/4 + i*128);
            }
        }
    }

    // Кластеров больше нет
    return 0;
}

// Печать директории из кластера
void get_directory(unsigned int n) 
{
    int i, j, c = 0;

    directory_last   = n; // Записать номер категории
    items_in_catalog = 0;

    while (1)
    {
        read_cluster(n);

        for (i = 0; i < fat32_cluster_size * 16; i++) // 512/32 = 16
        {
            // Дошли до конца?
            if (cluster[32*i] == 0) break;

            // Скопировать имя
            for (j = 0; j < 11; j++) fileitems[i].name[j] = cluster[32*i + j]; fileitems[i].name[11] = 0;

            // Скопировать параметры и данные
            fileitems[i].cluster  = get_word(i*32 + 0x1A) + (get_word(i*32 + 0x14)) * 256;
            fileitems[i].filesize = get_dword(i*32 + 0x1C);
            fileitems[i].attr     = cluster[32*i + 0x0B];

            items_in_catalog++;
        }

        // Запрос следующего кластера
        n = get_next_cluster(n);

        // Прервать скачивание при достижении конца
        if (n > 0xffffff0 || n == 0) break;       
    }  
}

// Печать содержимого директории
void print_directory(unsigned int n)
{
    unsigned char f, attr;
    int i;

    // Получить содержимое
    get_directory(n);

    printf("\n");
    printf("rhsvcad  Filename    | Cluster / Length \n");
    printf("---------------------+-------------------\n");

    for (i = 0; i < items_in_catalog; i++)
    {
        f    = fileitems[i].name[0];
        attr = fileitems[i].attr;

        // Пропуск (1) начинающихся с пробела, (2) удаленных (3) пустых (4) LFN-записей
        if (f == 0x20 || f == 0xE5 || f == 0 || attr == 0x0F) 
            continue;

        printf("%c", attr & 0x01 ? 'r' : ' '); // ReadOnly
        printf("%c", attr & 0x02 ? 'h' : ' '); // Hidden
        printf("%c", attr & 0x04 ? 's' : ' '); // System
        printf("%c", attr & 0x08 ? 'V' : ' '); // Volume
        printf("%c", attr & 0x10 ? 'C' : ' '); // Catalog
        printf("%c", attr & 0x20 ? 'a' : ' '); // Archive
        printf("%c", attr & 0x40 ? 'D' : ' '); // Device
        
        // Печать директории и файлов
        printf("  %s | %d cl. %d bytes (%d)\n", fileitems[i].name, fileitems[i].cluster, fileitems[i].filesize, i);
    }

    printf("\nroot at: %d\n", fat32_root);
}

// Печать корневой директории
void print_directory_root()
{
    print_directory(fat32_root);
}

// Процедура поиска конкретного файла
// Возвращается номер кластера
unsigned int search_file(char* filename)
{
    // Паттерн
    char file[12]; file[11] = 0; 
    char i = 0, j = 0, k, m;
    int match, found;

    // Первая директория - корневая
    unsigned int dir = fat32_root;

    // Найти последовательно файлы один за другим
    while (1)
    {
        j = 0;

        // Отыскать следующий файл/каталог
        while (1)
        {
            // Отправка при натыкании на "/" или 0
            if (filename[i] == '/' || filename[i] == 0) break;

            // Дополнить до 8-байтного значения
            if (filename[i] == '.') {

                m = 8 - j; for (k = 0; k < m; k++) file[j++] = ' ';
                i++; continue;
            }

            // Заполнение имени файла
            file[j] = filename[i];

            // применение UCASE
            if (file[j] >= 'a' && file[j] <= 'z') 
                file[j] += ('A' - 'a');

            i++; j++;
        }

        // Дополнить пробелами конец файла
        m = 11 - j; for (k = 0; k < m; k++) file[j++] = ' ';

        // -----------
        // Получить содержимое просматриваемого каталога
        // -----------

        get_directory(dir);

        // Найден ли файл?
        found = 0;

        // Поиск данных в каталоге
        for (m = 0; m < items_in_catalog; m++) {

            match = 1;
            for (j = 0; j < 11; j++) {
                if (fileitems[m].name[j] != file[j]) {
                    match = 0;
                    break;
                }
            }     

            // Полностью совпадает
            if (match) { found = 1; break; }
        }

        // Файл не найден
        if (!found) {
            return 0;
        }

        // Переход к следующей директории
        dir = fileitems[m].cluster;

        // -----------------
        if (filename[i] == 0) break; i++;        
    }

    return dir;
}

// Поиск ID по номеру кластера из fileitems[]
unsigned int find_dir_item(unsigned int cluster)
{
    int i;
    for (i = 0; i < items_in_catalog; i++) {
        if (fileitems[i].cluster == cluster) return i;
    }
    return 0;
}

// Удаление цепочки FAT по выбранному кластеру
void delete_file_chain(unsigned int n)
{
    unsigned int m;

    do {

        m = get_next_cluster(n);

        // В случае, если цепочка и так была уже удалена
        if (m == 0) break;

        // очистить цепь
        set_fat_cluster(n, 0); 

        n = m;
    }
    while (n < 0xFFFFFF0);
}

// Обновление файла
void update_file(unsigned int n, char* download_file)
{
    unsigned int transfer, clsize = (512 * fat32_cluster_size), chaincl = 0, fs = 0;

    FILE* fl = fopen(download_file, "r");    
    if (!fl) return;

    // Установить в начало
    fseek(fl, 0, SEEK_SET);

    // Найти элемент, чтобы потом обновить количество байт
    int item_id = find_dir_item(n), cl;   

    // Удалить прежнюю файловую цепочку
    delete_file_chain(n);

    // Кластер, который будет первым, уже указан
    cl = n;

    while (1)
    {
        // Установка EOC в любом случае
        set_fat_cluster(cl, 0x0FFFFFF8); 

        // Cкачать кластер данных из файла
        transfer = fread(cluster, 1, clsize, fl);

        // Учитывать размер файла
        fs += transfer;

        // ---- (DEBUG) ----
        // printf("-- %d | %d\n", cl, fs);
        // ----

        if (transfer) {

            // Сохранить кластер на диске
            write_cluster(cl);

            // теперь на предыдущий кластер поставить ссылку на этот кластер
            if (chaincl) set_fat_cluster(chaincl, cl); 

        } else {

            // Если же =0, значит отменить резервацию FAT
            set_fat_cluster(cl, 0); 
        }

        // Полностью скачано ..
        if (transfer < clsize) break;

        // Сохранение цепочки
        chaincl = cl;

        // Поиск следующего свободного кластера
        cl = find_free_cluster();
    }

    // Прочитать кластер последней директории
    read_cluster(directory_last);

    // Установить новый размер
    cluster[item_id*32 + 0x1C] = fs & 0xff;
    cluster[item_id*32 + 0x1D] = (fs >> 8) & 0xff;
    cluster[item_id*32 + 0x1E] = (fs >> 16) & 0xff;
    cluster[item_id*32 + 0x1F] = (fs >> 24) & 0xff;

    write_cluster(directory_last);

    fclose(fl);
}

// Чтение файла по кластерам
void read_file(unsigned int n, char* upload_file)
{
    FILE* fl = fopen(upload_file, "w+");    
    if (!fl) return;

    // Поиск элемента
    int item_id = find_dir_item(n), cl = 512 * fat32_cluster_size;
    unsigned int fs = cluster[item_id*32 + 0x1C] + (cluster[item_id*32 + 0x1D] << 8) + (cluster[item_id*32 + 0x1E] << 16)+ (cluster[item_id*32 + 0x1F] << 24);

    fseek(fl, 0, SEEK_SET);

    do {

        read_cluster(n);
        n = get_next_cluster(n);

        // В случае, если цепочка и так была уже удалена
        if (n == 0) break;

        // Печать кластера в файл
        if (fs >= cl) {
            fwrite(cluster, 1, cl, fl);
            fs -= cl;
        } else {
            fwrite(cluster, 1, fs, fl);
        }
    }
    while (n < 0xFFFFFF0); 

    printf("FILE EXPORTED\n");
}