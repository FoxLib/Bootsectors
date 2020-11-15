; Элементы UI

ui_reg_top             dd 0               ; Количество зарегистрированных элементов
ui_reg_free            dd 0               ; Первый свободный блок
ui_events_stack        dw SGN_ESTACK      ; Текущий сегмент для стека событий

; Положение курсора мыши
ui_mouse_x             dd 0
ui_mouse_y             dd 0
ui_mouse_keys          db 0  ; Состояние клавиш мыши

; Старое положение до перемещения 
ui_mouse_xold          dd 0
ui_mouse_yold          dd 0
ui_mouse_keys_old      db 0  ; Предыдущее состояния клавиш

ui_mouse_multiplier    dd 1  ; Умножитель движения
ui_icon_mouse          dd icon_mouse_default ; Ссылка на иконку мыши

; Отображаемые размеры указателя мыши
ui_mouse_width         db 0
ui_mouse_height        db 0
