
// Максимальное количество открытых программ
#define PROCESS_MAX         32

// Типы процессов. RAW - это тупо любой проект, FASM 32bit / GCC32
// Своего рода COM-файл
#define PROCESS_TYPE_RAW    1

// Запуск приложения с EntryTSS позиции (копирование регистров и флагов)
void app_exec(uint32_t, uint32_t);

struct PROCESS {
    
    uint8_t     busy;
    uint8_t     type;               // Тип процесса
    uint32_t    cr3_map;            // Страница разметки процесса
    uint8_t     tss[104];           // Здесь все регистры и флаги процесса
    
};

// Текущий исполняемый ID процесса
uint32_t app_id_current;

// Процессы
struct PROCESS apps[ PROCESS_MAX ];
