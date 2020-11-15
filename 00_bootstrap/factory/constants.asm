; **********************************************************************
; Здесь находятся системные константы, а также их описание, для чего они
; требуются. 
; **********************************************************************

; См. таблицу IRQ [documentation/irq.txt] для понимания битов
IRQ_MASKING             equ 000000001111111111111100b

; Machine State Word (MSR) для получения адреса Local APIC
MSR_APIC_BASE           equ 0x1B

; Системные дескрипторы
DESCRIPTOR_NULL         equ 0x00
DESCRIPTOR_CODE_RING0   equ 0x08
DESCRIPTOR_DATA_RING0   equ 0x10
DESCRIPTOR_MAIN_TSS     equ 0x18

; Здесь хранятся указатели (32-bit) на обработчики файловых систем (256)
FILESYS_TYPES_TABLE     equ 0x101000

; ----------------------------------------------------------------------
; Где находится PageDirectoryBaseRegister
MM_PDBR_LOCATION        equ 0x102000

; Page Directory Entry (т.е. PDBR)
PDE_PRESENT             equ 0x001 ; Present=1
PDE_READWRITE           equ 0x002 ; Read=0, Write=1
PDE_USER                equ 0x004 ; User=1, Supervisor=1 Доступ 
PDE_WRITE_THROUGH       equ 0x008 ; Контроль кеширования
PDE_DIS_CACHE           equ 0x010 ; 1=Выключить кеширование TLB
PDE_ACCESS              equ 0x020 ; 1=Был доступ к странице
PDE_SIZE                equ 0x040 ; 0=4kb, 1=4mb (трубется PSE=1)

; PDE_WRITE_THROUGH:
; (1) Write-through caching - это когда запись производится непосредственно 
;     в основную память и дублируется в кэш. 
; (0) Write-back caching - это когда запись данных производится в кэш. 
;     Запись же в основную память производится позже (при вытеснении)

; Page Table Entry (т.е. страницы по 4кб)
PTE_PRESENT             equ 0x001 ; Present=1
PTE_READWRITE           equ 0x002 ; Read=0, Write=1
PTE_USER                equ 0x004 ; User=1, Supervisor=1 Доступ 
PDE_WRITE_THROUGH       equ 0x008 ; 1=Запись была в страницу
PTE_DIS_CACHE           equ 0x010 ; 1=Выключить кеширование TLB
PTE_ACCESS              equ 0x020 ; 1=Был доступ к странице
PTE_DIRTY               equ 0x040 ; 1=В страницу обнаружена запись
PTE_GLOBAL              equ 0x100 ; 1=Глобальная страница

; Глобальная страница не перезагружается после обновления CR3. См. бит в
; CR4 для включения этой возможности.

; ----------------------------------------------------------------------
