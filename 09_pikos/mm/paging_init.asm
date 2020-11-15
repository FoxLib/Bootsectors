
;
; Инициалиализация страничной адресации
;
; * Вся область физической памяти до E0000000h
; * Область VESA
;
; Page Table Entry (PTE):
;
; 01  1 Present 
; 02 1 Write enabled
; 04 0 0=Supervisor 1=User
; 08 0 0=Сквозная запись (кеш) отключена
; 10 0 0=Кеш включен 1=Отключен
; 20 0 1=Доступ был (ставит процессор)
; 40 0 0=4kb размер, 1=4mb при PSE
; ...

mm.PagingInit:

        ; Для начала, очистить PDBR
        mov     edi, PDBR
        mov     ecx, 1024        
        xor     eax, eax
        rep     stosd

        ; Заполнение 4 Мб страниц, которые будут потом описывать 4 Гб           
        xor     ebx, ebx
        mov     edi, PDBR
        mov     eax, PGT + 3
@@:     stosd
        add     eax, 00001000h 
        add     ebx, 00400000h
        cmp     ebx, [mm.memory_top]
        jb      @b

        ; Теперь заполняем сами страницы
        mov     edi, PGT
        xor     ebx, ebx
        mov     eax, 3
@@:     stosd
        add     eax, 00001000h
        cmp     eax, [mm.memory_top]
        jb      @b
        
        ; Заполнить область VESA >>>

        ; Записать указатель PDBR на каталог страниц VESA
        mov     edi, [vesa.linear]
        shr     edi, 20
        add     edi, PDBR        
        mov     eax, [vesa.linear]
        shr     eax, 10
        add     eax, PGT
        or      eax, 3
        stosd
  
        ; Разметка 4kb табдицы
        and     eax, 0FFFFF000h
        mov     edi, eax
        
        ; Расчет размера дисплея (сколько нужно страниц)
        ; 12 - 1 = width * height * 2 / 4096            
            
        mov     eax, [vesa.linear]
        movzx   ebx, word [vesa.width]
        movzx   ecx, word [vesa.height]
        imul    ecx, ebx    
        shr     ecx, 11                 
        or      eax, 3
@@:     stosd
        add     eax, 00001000h
        loop    @b

        ; Установка главного PDBR -> CR3
        ; Включение режима страничной адресации
        
        mov     eax, PDBR
        mov     cr3, eax
        mov     eax, cr0
        or      eax, 80000000h
        mov     cr0, eax
        jmp     $+2     
        ret

