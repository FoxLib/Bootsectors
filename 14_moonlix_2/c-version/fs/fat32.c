#include <stdint.h>

#define BRK asm("xchg bx, bx")
#include "../headers/memory.h"
#include "../driver/h/ata.h"

// Для INT 0xC0


// Перечислитель ФС
// -----------------------------------------------------------------------------------------
// Как параметр -- EDI, указатель на данные FS:EDI, куда будет записана таблица FS
// Функция определяет все доступные для чтения файловые системы и записывает в GS:EDI 
// (в действительности, в FS:EDI, т.е. GS = FS)
// Возврат:
// dword COUNT
//
//   dword identify | disk_drive<<16
//   dword lba start

void syscall_get_fat_enumeration() 
{
    int i, j, fp, ft, item_id = 0, ptr, edi = get_edi();

    // Количество файловых систем    
    write_gs(edi, 0);

    // Перечислитель дисков в системе
    for (i = 0; i < 8; i++) 
    {
        // Если это ATA
        if (get_disk_info(i, 0) == ATADEV_PATA)
        {
            // Разбор инфомации о разделах
            for (j = 0; j < 4; j++) 
            {
                fp = PARTITIONS_DATA + j*16 + i*64;
                ft = read(fp + 8);

                // fat16/32?
                if (ft == 6 || ft == 0xb)  
                {
                    ptr = (edi + 4) + item_id*8;

                    write_gs(ptr,     ft + (i << 16));  // FAT16 Identificator | Disk Drive
                    write_gs(ptr + 4, read(fp));        // LBA абсолютный сектор

                    item_id++;
                    write_gs(edi, item_id);
                }                
            }
        }
    }
}

// Открытие дескриптора файловой системы
// ESI - идентификатор ФС
// -----------------------------------------------------------------------------------------
void syscall_open_descriptor()
{

}