; Макросы
; -------------------

    include '../lib64/const.asm'      ; Константы
    include '../lib64/macros.asm'     ; Макросы

; Начало кода и подготовка
; --------------------------------------

    org 0xC000

    ; Принудительное включение видеорежима 320x200
    ; потому что тут будет демосцена

    mov ax, 0x0013
    int 0x10
    
    ; Проставляем пространство данных
    cli   
    lgdt [cs:GDTR]        
 
    ; Переключаемся в 32-х бит защищенный режим
    mov   eax, cr0        
    or    al, 1
    mov   cr0, eax
    jmp   CODE_SELECTOR : pm_start

    include '../lib64/gdt.asm'

; 32 битный режим    
; --------------------------------------

    USE32

pm_start:
   
    mov eax, DATA_SELECTOR ; загрузим 4 GB дескриптор данных [lib64/const.asm]
    mov ds, ax             ; на все сегментные регистры
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov eax, 1
    cpuid
    and edx, 1 shl 26
    je .sse_not_support

    ; https://en.wikipedia.org/wiki/Control_register
    mov eax, cr4
    or  ax,  1 shl 9
    mov cr4, eax
    jmp .sse_supported

; Такой процессор не включать просто
.sse_not_support:
    jmp $    

.sse_supported:

    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor ebp, ebp
    xor esi, esi
    mov edi, 0xA0000
    mov esp, 0xA0000      ; ESP под видеообластью
