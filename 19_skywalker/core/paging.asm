GENERAL_PDBR       equ 1000h
GENERAL_CATALOG    equ 2000h

; ----------------------------------------------------------------------
; Создание страничной адресации
; ----------------------------------------------------------------------

paging_make:

        ; Полный сброс каталогов (главного и первого)
        mov     edi, GENERAL_PDBR
        mov     ecx, 2 * 1024
        xor     eax, eax
        rep     stosd

        ; Установка ссылки на первый каталог 4 Мб
        mov     [GENERAL_PDBR], dword (GENERAL_CATALOG + 3)
        
        ; Заполнить только 1 Мб 
        mov     edi, GENERAL_CATALOG
        mov     eax, 3
@@:     stosd
        add     eax, 1000h
        cmp     eax, 100000h
        jc      @b        
        
        ; Установка страничного механизма
        mov     eax, GENERAL_PDBR
        mov     cr3, eax
        mov     eax, cr0
        or      eax, 80000000h
        mov     cr0, eax
        jmp     $+2        
        ret
