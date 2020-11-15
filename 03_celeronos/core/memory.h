/*
 * Разметка участков памяти
 */

#define MAIN_TSS        	0x00000800 // TSS находится сразу за IDT
#define GDT_REFTMP      	0x00000868 // Временный указатель на GDT
#define PDBR            	0x00001000 // Page Directory Index (4 kb)
#define CATALOG_4MB     	0x00002000 // 4 MB Catalog (1024 описателя по 4 кб каждый)
#define GDT_LOCATION    	0x00010000 // Расположение GDT

/*
 * Конфигурационные данные
 */

#define MEMORY_CAPACITY      1         // Количество предварительно размеченных 4 мб блоков

