// Ссылка на диск
FILE* disk;

// Определить структуру partition
typedef struct {
   
    char is_fat32;    // Это FAT32 | Тип (0Bh - FAT32)
    unsigned int lba; // Начало
    unsigned int ln;  // Длина

} TPartition;

typedef struct 
{
    unsigned char name[11];
    unsigned int  cluster;  // Начальный кластер
    unsigned int  filesize; // Размер
    unsigned char attr;

} TFileItem;

// Откуда начинается выбранный раздел
unsigned int pstart;

unsigned int items_in_catalog; // Количество записей в каталоге
unsigned int directory_last;   // последний сектор, который указывает на каталог

// Информация о FAT32
// ----------------------------
int fat32_cluster_size; // Секторов в кластере
int fat32_reserved;     // Зарезервированных секторов
int fat32_count;        // Количество FAT
int fat32_size;         // Размер FAT в логических секторах
int fat32_root;         // Root-директория

unsigned int data_fat;     // Сектор с FAT
unsigned int data_cluster; // Номер сектора, откуда начинаются данные по кластерам

// Сектор на 512 байт
unsigned char sector[512];

// Максимальный размер кластера
unsigned char cluster[65536];

// Определение частей диска
TPartition diskpart[4];
TFileItem  fileitems[65536];