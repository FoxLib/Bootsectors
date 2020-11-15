UICOM_references: ; Смотри decl/types.asm

    dd 0             ; UI_NIL
    dd ui_rectangle  ; UI_BLOCK
    dd ui_gradient   ; UI_VGRADIENT
    dd ui_icon_4bit  ; UI_ICON_4
    dd ui_text       ; UI_TEXT

; ----------------------------------------------------------------

; Компонент "Фон рабочего стола". Тип блок. Цвет
UICOM_desktop:

    COM_BASIC UI_BLOCK, 0, 0, 0, 0 ; w, h рассчитываются динамически
    dd 0x00002E6C

UICOM_taskbar:

    COM_BASIC UI_VGRADIENT, 0, 0, 0, 30 ; y рассчитывается динамически
    dw 30
    dd gradient_hi_bar
    

UICOM_home_icon:

    COM_BASIC UI_ICON_4, 7, 0, 16, 16
    dd icon_home


UICOM_text_under:    

    COM_BASIC UI_TEXT, 17, 15, 0, 0
    dd 0x002f6092
    dd hello_world    

UICOM_text:    

    COM_BASIC UI_TEXT, 16, 14, 0, 0
    dd 0x00ffffff
    dd hello_world

UICOM_topwindow:

    COM_BASIC UI_VGRADIENT, 8, 8, 640, 22
    dw 22
    dd gradient_active_window
    
UICOM_nawindow:

    COM_BASIC UI_VGRADIENT, 8, 8, 640, 22
    dw 22
    dd gradient_disabled_window

UICOM_winblock:

    COM_BASIC UI_BLOCK, 8, 30, 640, 480
    dd 0x00ffffff

