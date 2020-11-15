; 0.5с время клика
EXPIRE_DBLCLICK     equ 9

; 
; Обработка запуска нового приложения (однозадачный режим)
;

desktop.ProgramStart:

        ; Ориентируясь на таймер, уменьшить loc_click_delay
        ; ---------------------------------------
        mov     ax, word [timer]
        cmp     [.loc_prevt], ax
        je      @f
        mov     [.loc_prevt], ax
        cmp     [.loc_click_delay], 0
        je      @f
        dec     [.loc_click_delay]
        ; ---------------------------------------

        ; ЛКМ нажата?
@@:     test    [PS2Mouse.irq.cmd], 1
        je      .noclk
        
        ; Ранее кнопка не была нажата?
        cmp     [.loc_click_press], 0
        je      @f    
        
        ; -- Событие Click (узнать правда ли?)
        ; @todo Проверка на открытые регионы окон для передачи туда DblClick

@@:        
        ; Определить, что был двойной клик на программе
        cmp     [.loc_click_delay], 0
        je      .expired
        
        ; -----------------------------
        ; Тест на запуск программы
        ; -----------------------------

        ; Какая программа выбрана
        movzx   eax, [desktop.current_icon]
        cmp     ax, -1
        je      .expired
        
        ; -- Событие DblClick
        ; @todo Проверка на открытые регионы окон для передачи туда DblClick        
        sub     [FreeBlock], 128
        
        ; Прочитать путь к программе 16*item_id + icons_list
        mov     esi, [desktop.images.icons_list]
        shl     eax, 4
        lea     esi, [eax + esi + 4]
        call    XMS.Read32
        xchg    eax, esi
        
        ; Скопировать имя программы, и запустить
        mov     ecx, 128
        movzx   edi, word [FreeBlock]
        add     edi, BASEADDR
        call    XMS.Copy

        ; Запретить мышь
        mov     [param.os_status], 1

        ; -- 
        mov     ah, 4Bh
        mov     dx, [FreeBlock]
        int     21h
        ; --
   
        add     [FreeBlock], 128
        
        ; Разрешить мышь
        mov     [param.os_status], 1

        call    [SetDefaultVideoMode]
        call    [Desktop.Repaint]
        call    PS2Mouse.Show

        mov     [param.os_status], 0        
        mov     [.loc_click_delay], 0  
        ; -----------------------------
        
.expired:
        
        ; Кнопка была нажата
        mov     [.loc_click_press], 1    
        mov     [.loc_click_delay], 0  
        jmp     .next

        ; Кнопка отпущена
.noclk: cmp     [.loc_click_press], 0
        je      .next
        
        ; -- Событие MouseUp
        ; @todo Проверка на открытые регионы окон для передачи туда MouseUp
        
        ; Когда кнопка отпущена, но предыдущий клик был - сделать отсчет
        mov     [.loc_click_press], 0
        mov     [.loc_click_delay], EXPIRE_DBLCLICK

.next:     
        


        ret

.loc_click_delay db 0
.loc_click_press db 0
.loc_prevt  dw 0
