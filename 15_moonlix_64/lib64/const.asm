; Дескрипторы
NULL_SELECTOR = 0
DATA_SELECTOR = 1 shl 3                 ; flat data selector (ring 0)
CODE_SELECTOR = 2 shl 3                 ; 32-bit code selector (ring 0)
LONG_SELECTOR = 3 shl 3                 ; 64-bit code selector (ring 0)
LDAT_SELECTOR = 4 shl 3                 ; 64-bit data selector (ring 0)

; Страничная адресация (2k + 4k + 8mb)
PAGE_PLM4 EQU 0x9A000                 ; PDP
PAGE_PDP  EQU 0x9B000
PAGE_PD   EQU 0x9C000                 ; 2 каталога страниц для описания 4 Гб
PAGE_PT   EQU 0x100000                ; все 4 Гб памяти (8 мб)

HEAP_INDEX EQU 0x900000               ; Индексатор Heap
HEAP_ADDR  EQU 0xA00000               ; Начало Heap

; VESA
VESA_PAGING EQU 0x78000 ; 4 Мб (8 кб страница) для LFB

; VESA
VESASignature      EQU 0x00  ; dword
VESAVersion        EQU 0x04  ; word
VESAOEMStringPtr   EQU 0x06  ; dword Указатель на строку идентификации видеоплаты
VESACapabilities   EQU 0x0A  ; dword x 4 возможности среды Super VGA
VESAVideoModePtr   EQU 0x0E  ; Указатель на поддерживаемые режимы Super VGA
VESATotalMemory    EQU 0x012 ; Число 64kb блоков на плате 
