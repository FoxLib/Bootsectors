; Параметры настройки VESA

vesa_ptr    dq 0 ; Возможно эта область будет "скрыта" (back-буфер)
vesa_real   dq 0 ; FRONT-буфер, область реального рисования
vesa_bit    db 0 ; 24/32 бита 
vesa_w      dq 0 ; Ширина
vesa_h      dq 0 ; Высота

; --------------------------------------
VESA_Errorcode    db 'VESA not supported', 0
VESA_ModeNotFound db 'VESA required video mode not supported', 0
VESA_LFBNotFound  db 'VESA LFB not supported', 0
VESA_VideoModeErr db 'VESA Videomode not set', 0

; ---------------------------------------------------------------------
; Установка VESA видеорежима. Работает только из реального режима
; VESA при загрузке нужна для базового функционирования ОС
; ---------------------------------------------------------------------

vesa_set_1024x768:

    ; По адресу di=0x7000 будет находится блок получения информации о VESA
    mov di, 0x7000

    ; Вернуть SVGA информацию http://www.codenet.ru/progr/video/vesa124.php#A6.1
    ; Также, литература http://pdos.csail.mit.edu/6.828/2004/readings/hardware/vgadoc/VESA.TXT
    
    mov ax, 0x4F00
    int 0x10

    cmp dword [di + VESASignature], 'VESA'
    je .OK

    mov  si, VESA_Errorcode
    jmp .vesa_error
    
.OK: ; Поддержка VESA найдена

    ; Получаем версию VESA
    mov ax, [di + VESAVersion]

    ; Получаем ссылку на список видеорежимов
    lfs si, [di + VESAVideoModePtr]
    xor cx, cx
    
    ; ----

.vesa_loop_test:

    ; Чтение номера видеорежима (ax)
    mov ax, [fs:si]

    ; Нужна поддержка режима 118h (1024x768)
    cmp ax, 0x118 
    jb .next_loop

    ; Достигнут конец перечисления режимов
    cmp ax, 0xFFFF
    je  .vesa_mode_not_found

    ; Записать информацию о видеорежиме в 0x7100    
    mov  cx, ax
    or   cx, 0x4000 ; Включить поддержку LFB
    mov  ax, 0x4F01
    mov  di, 0x7100  ; Ссылка на блок атрибутов
    int  0x10

    ; bit  (Байт в es:di = 0x7100)
    ; -----
    ; 0: mode supported if set
    ; 1: optional information available if set
    ; 2: BIOS output supported if set
    ; 3: set if color, clear if monochrome
    ; 4: set if graphics mode, clear if text mode
    ; 5: (VBE2) non-VGA mode
    ; 6: (VBE2) No bank swiotching supported
    ; 7: (VBE2) Linear framebuffer mode supported

    ; Если 0x80 -- Linear framebuffer mode supported -- такой режим поддерживаем
    mov ax, [0x7100]
    test ax, 0x80   
    je .next_loop

    ; Количество битов должно быть 24 или 32
    mov ax, [0x7119]
    cmp ax, 24
    jb .next_loop

    ; 02h   BYTE     window A attributes
    ;                bit 0: exists if set
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

    ; 118h (1024x768) разрешение 1024x768
    mov ax, [fs:si]    
    cmp ax, word 0x118
    je .resolution_found

.next_loop:

    inc si
    inc si
    jmp .vesa_loop_test

; --------------------------------------------------

; Найден нужный видеорежим
.resolution_found:

    ; Получаем информацию об LFB
    ; Записать адрес начала LFB

    ; 28h   DWORD    Physical address of linear video buffer
    ; ---    

    ; записать LFB 
    mov edi,  [0x7128] 
    mov dword [vesa_ptr],  edi ; указатель на vesa_ptr может поменяться
    mov dword [vesa_real], edi

    mov al, [0x7119]  ; записать разрядность
    mov [vesa_bit], al

    ; Ширина
    mov ax, [0x7112]
    mov word [vesa_w], ax

    ; Высота
    mov ax, [0x7114]
    mov word [vesa_h], ax

    ; 12h   WORD     width in pixels
    ; 14h   WORD     height in pixels

    ; ---
    mov ax, 0x4F02
    mov cx, [fs:si]
    or  cx, 0x4000
    mov bx, cx
    int 0x10

    cmp ax, 0x004F
    jne .vesa_vmode_not_set

    ret

; --- Errors ---
.vesa_vmode_not_set:

    mov ax, cs
    mov ds, ax
    mov si, VESA_VideoModeErr
    jmp .vesa_error

.vesa_lfb_not_found:

    mov ax, cs
    mov ds, ax
    mov si, VESA_LFBNotFound
    jmp .vesa_error

.vesa_mode_not_found:

    mov ax, cs
    mov ds, ax
    mov si, VESA_ModeNotFound

.vesa_error:

    lodsb
    and al, al
    jne $+4
    jmp $+0

    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10

    jmp .vesa_error