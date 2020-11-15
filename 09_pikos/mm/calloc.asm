;
; Найти свободную страницу и создать её (очистить нулями)
; Физический адрес страницы в EAX
;

; Изначально поиск начинать с 8-го мегайбайта        
; Сбрасывается при любом удалении блока ниже чем значение calloc_last до
; этого блока, чтобы быстрее найти следующую свободную страницу

mm.calloc_last      dd PGT + 2000h      

; ----------------------------------------------------------------------

mm.Calloc:

        mov     esi, [mm.calloc_last]
        lea     edi, [esi - PGT]
        shl     edi, 10              ; mem_ptr = (cp - PTG) * 4096
        
@@:     lodsd
        test    ax, 0800h            ; если =0, значит, страница свободна        
        jz      .page_available
        add     edi, 1000h
        cmp     edi, [mm.memory_top]
        jb      @b
        
        ; Достигнут предел физической памяти
        ; Пока что виртуальная не поддерживается
        xor     eax, eax
        ret
        
.page_available:  

        ; Следующая страница
        mov     [mm.calloc_last], esi   

        ; Отметить как занятую
        lea     esi, [esi - 4]
        or      [esi], word 0800h
        
        ; Трансляция в физический адрес    
        lea     eax, [esi - PGT]
        shl     eax, 10
        
        ; очистка
        push    eax
        mov     edi, eax
        mov     ecx, 1024
        xor     eax, eax
        rep     stosd
        pop     eax
        ret
