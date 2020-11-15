
VESASignature      EQU 0x00 ; dword
VESAVersion        EQU 0x04 ; word
VESAOEMStringPtr   EQU 0x06 ; dword Указатель на строку идентификации видеоплаты
VESACapabilities   EQU 0x0A ; dword x 4 возможности среды Super VGA
VESAVideoModePtr   EQU 0x0E ; Указатель на поддерживаемые режимы Super VGA
VESATotalMemory    EQU 0x012 ; Число 64kb блоков на плате 

; ---------------------------------------------------------------------
; Установка VESA видеорежима. Работает только из реального режима
; VESA при загрузке нужна для базового функционирования ОС
; ---------------------------------------------------------------------

    use16

vesa_set:

    mov ax, cs
    mov ds, ax

    mov ax, 0x5000 
    mov es, ax
    xor di, di

    ; Вернуть SVGA информацию http://www.codenet.ru/progr/video/vesa124.php#A6.1
    ; Также, литература http://pdos.csail.mit.edu/6.828/2004/readings/hardware/vgadoc/VESA.TXT
    
    mov ax, 0x4F00
    int 0x10

    cmp dword [es:di + VESASignature], 'VESA'
    je @vesa_ok

    mov si, VESA_Errorcode
    call @vesa_error
    jmp $+0

@vesa_ok:

    ; Получаем версию VESA
    mov ax, [es:di + VESAVersion]

    ; Получаем ссылку на список видеорежимов
    les si, [es:di + VESAVideoModePtr]
    xor cx, cx

    ; Интересует поддержка режимов 118h (1024x768), 115h (800x600), 112h (640x480)    

@vesa_loop_test:

    ; Чтение номера видеорежима (ax)
    mov ax, [es:si]

    ; Сохраняем ES еще до выхода
    push es

    cmp ax, 0xFFFF
    je  @vesa_fetch_done

    push ax
    mov  cx, ax

    ; Принудительно ставится ES (т.к. список видеорежимов может быть в ROM)
    mov ax, 0x5000
    mov es, ax
    
    or   cx, 0x4000 ; Включить поддержку LFB
    mov  ax, 0x4F01
    mov  di, 0x100  ; Ссылка на блок атрибутов
    int  0x10
    pop  ax

    ; bit 
    ; 0: mode supported if set
    ; 1: optional information available if set
    ; 2: BIOS output supported if set
    ; 3: set if color, clear if monochrome
    ; 4: set if graphics mode, clear if text mode
    ; 5: (VBE2) non-VGA mode
    ; 6: (VBE2) No bank swiotching supported
    ; 7: (VBE2) Linear framebuffer mode supported

    ; Сбрасываем - если этот видеорежим не будет найден, то он будет 0
    xor  cx, cx

    ; Показать только поддерживаемые режимы
    test [es:di], byte 0x80
    je @vesa_mode_inv

    ; 02h   BYTE     window A attributes
    ;            bit 0: exists if set
    ;                1: readable if set
    ;                2: writable if set
    ;                   bits 3-7 reserved
    ;
    ; 03h   BYTE     window B attributes (as for window A)
    ; 04h   WORD     window granularity in K
    ; 06h   WORD     window size in K
    ; 08h   WORD     start segment of window A
    ; 0Ah   WORD     start segment of window B
    ; 0Ch   DWORD -> FAR window positioning function (equivalent to AX=4F05h)
    ; 10h   WORD     bytes per scan line
    ; ---remainder is optional for VESA modes, needed for OEM modes---
    ; 12h   WORD     width in pixels
    ; 14h   WORD     height in pixels
    ; 16h   BYTE     width of character cell in pixels
    ; 17h   BYTE     height of character cell in pixels
    ; 18h   BYTE     number of memory planes
    ; 19h   BYTE     number of bits per pixel
    ; 1Ah   BYTE     number of banks
    ; 1Bh   BYTE     memory model type

    ;                   0 Text
    ;                   1 CGA graphics
    ;                   2 Hercules Graphics
    ;                   3 EGA 16 color
    ;                   4 Packed pixels
    ;                   5 Non chain 4 256 color modes
    ;                   6 Direct 15/16/24 bit
    ;                   7 YUV (luminance-chrominance, alos called YIQ)

    ;               8-0Fh Reserved for VESA
    ;            10h-0FFh Reserved for OEM
    ; 1Ch   BYTE     size of bank in K
    ; 1Dh   BYTE     number of image pages
    ; 1Eh   BYTE     reserved(1)
    ;  ------VBE v1.2+ --------------------------
    ; 1Fh   BYTE     Red mask size
    ; 20h   BYTE     Red mask position
    ; 21h   BYTE     Green mask size
    ; 22h   BYTE     Green mask position
    ; 23h   BYTE     Blue mask size
    ; 24h   BYTE     Blue mask position
    ; 25h   BYTE     Reserved mask size
    ; 26h   BYTE     Reserved mask position
    ; 27h   BYTE     Direct Screen mode info
    ;       Bit      0  If set the color ramp is programmable, if clear fixed
    ;                1  If set the reserved field (as defined by Bytes 25-26h)
    ;                   can be used by the application, if clear the field is
    ;                   truly reserved.
    ;  --- VBE v2.0 ---
    ; 28h   DWORD    Physical address of linear video buffer
    ; 2Ch   DWORD    Pointer to start of offscreen memory
    ; 30h   WORD     Offscreen memory in Kbytes

    ; Количество битов должно быть 32
    cmp [es:di + 0x19], byte 32
    jne @vesa_mode_inv

    ; Выбор максимального разрешения
    mov [cs:END_OF_CODE + VESA_VIDEOMODE], ax

    ; bochs debug
    if Debug = 1

        cmp [es:di + 0x12], word 1024
        je @vesa_fetch_done

    end if

@vesa_mode_inv:

    ; Восстанавливаем ES
    pop es

    inc si
    inc si
    jmp @vesa_loop_test

@vesa_fetch_done:

    pop es

    ; Нужный видеорежим не найден
    mov cx, [cs:END_OF_CODE + VESA_VIDEOMODE]
    and cx, cx
    je  @vesa_mode_not_found

    ; Получаем информацию об LFB
    mov  ax, 0x5000
    mov  es, ax

    mov  di, 0x0100 ; 256-байтный блок
    mov  ax, 0x4F01
    or   cx, 0x4000 ; Включить поддержку LFB
    push cx
    int  0x10
    pop  cx

    ; Проверка атрибута LFB
    mov ax, [es:0x100] 
    and al, 0x80
    je  @vesa_lfb_not_found

    push cs
    pop  ds

    ; Запись данных о видеорежиме (для доступа в PM)    
    ; Запись количества пикселей по ширине и высоте
    ; ---
    movzx eax, word [es:di + 0x12] ; X
    mov [cs:END_OF_CODE + SCREEN_WIDTH],  eax

    movzx ebx, word [es:di + 0x14] ; Y
    mov [cs:END_OF_CODE + SCREEN_HEIGHT], ebx

    ; Размер фреймбуфера в байтах
    mul ebx
    mov ebx, eax
    shl ebx, 2 ; x*y*4

    ; Записать адрес начала LFB
    mov eax,  [es:di + 0x28]    
    mov dword [END_OF_CODE + VESA_LFB_SIZE], ebx 
    mov dword [END_OF_CODE + VESA_LFB],      eax 

    ; Запись данных о лимитах в дескриптор LFB
    mov dword [descriptor_lfb + 0], eax ; Адрес
    mov dword [descriptor_lfb + 4], ebx ; Запись лимита

    ; ---
    mov ax, 0x4F02
    mov bx, cx
    int 0x10

    cmp ax, 0x004F
    jne @vesa_vmode_not_set

    ret

; --------------------------------------
VESA_Errorcode    db 'VESA not supported', 0
VESA_ModeNotFound db 'VESA required video mode not supported', 0
VESA_LFBNotFound  db 'VESA LFB not supported', 0
VESA_VideoModeErr db 'VESA Videomode not set', 0

@vesa_vmode_not_set:

    mov ax, cs
    mov ds, ax
    mov si, VESA_VideoModeErr
    jmp @vesa_error

@vesa_lfb_not_found:

    mov ax, cs
    mov ds, ax
    mov si, VESA_LFBNotFound
    jmp @vesa_error

@vesa_mode_not_found:

    mov ax, cs
    mov ds, ax
    mov si, VESA_ModeNotFound

@vesa_error:

    lodsb
    and al, al
    jne $+4
    jmp $+0

    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10

    jmp @vesa_error
