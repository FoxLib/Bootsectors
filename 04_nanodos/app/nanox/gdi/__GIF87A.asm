; https://www.w3.org/Graphics/GIF/spec-gif87.txt

virtual at buffer
  GIFHEADER:
    .ID 	    dd ?
    .ver	    dw ?
    .width	    dw ?
    .height	    dw ?
    .bits	    db ?
    .background db ?
    .reserved	db ?
    .length	=  $ - GIFHEADER
end virtual

load_picture:

	invoke	CreateFileA,esi,GENERIC_READ,0,0,OPEN_EXISTING,0,0
	mov	    edi,eax
	invoke	ReadFile,edi,GIFHEADER,40000h,bytes_count,0
	invoke	CloseHandle,edi

; -----------

	cmp	    [GIFHEADER.ID],'GIF8'
	jne	    picture_error
    
	cmp	    [GIFHEADER.ver], '7a'       ; GIF87a
	jne	    picture_error

	mov	    al, [GIFHEADER.bits]        ; Должен быть 256-цветным
	and	    al, 10000111b
	cmp	    al, 10000111b
	jne	    picture_error

; -----------

    ; bytes_count указывает на КОНЕЦ файла
	add	    [bytes_count], buffer
    
    ; Установка указателя на данные
	mov	    esi, buffer + GIFHEADER.length + 256*3
	mov	    edi, esi
	xor	    eax, eax

find_image:

	cmp	    esi, [bytes_count]
	jae	    picture_error
    
	lodsb
	cmp	    al, ','
	je	    image_found
    
	cmp	    al,'!'
	jne	    picture_error
    
    ; Пропустить байт после '!'    
	inc	    esi
    
skip_application_data:

	lodsb
	add	    esi, eax
	or	    al, al
	jnz	    skip_application_data
	jmp	    find_image

image_found:

	add	    esi, 4
	xor	    eax, eax
	lodsw                   ; dwWidth
	mov	    ebx, eax            
	lodsw                   ; dwHeight
	inc	    esi
	cmp	    byte [esi], 8   ; LWZ минимальная длина кода = 8 + 1 (9 бит)
	jne	    picture_error
	inc	    esi

; Распаковка чанков по 256 байт в тот же поток
; ------------------------

	mov	    edi, esi
	mov	    edx, esi

    ; Установка указателя на конец буфера
	mov	    ebx, buffer
	add	    ebx, [bytes_count]
    
link_streams:

	cmp	    esi, [bytes_count]
	jae	    picture_error

	lodsb
	movzx	ecx, al
	rep	    movsb
	or	    al, al
	jnz	    link_streams

; ---------------------------------------------------------------------- LZW 
; EBX - текущий поток данных
; EDI - выходной поток

	mov	    edi, [ddsd.lpSurface]
	mov	    ebx, edx
	mov	    [LZW_bits], 0
    
    ; Очистка словаря
    
LZW_clear:

	xor	    edx, edx
    
LZW_decompress_loop:

    ; В зависимости от размера словаря, будет использованы CH бит
	mov	    ch, 9
	cmp	    edx, (100h - 2)*8
	jbe	    LZW_read_bits
    
	mov	    ch, 10
	cmp	    edx, (300h - 2)*8
	jbe	    LZW_read_bits
    
	mov	    ch, 11
	cmp	    edx, (700h - 2)*8
	jbe	    LZW_read_bits
    
	mov	    ch, 12
    
LZW_read_bits:

    ; Сдвинуть на CL бит 
	mov	    cl, [LZW_bits]
	mov	    eax, [ebx]
	shr	    eax, cl
    
    ; Срезать CH битов
	xchg	cl, ch
	mov	    esi, 1
	shl	    esi, cl
	dec	    esi
	and	    eax, esi
    
    ; Указатель на следующие биты
	add	    cl, ch
    
LZW_read_bits_count:

	cmp	    cl, 8
	jbe	    LZW_read_bits_ok
    
    ; Обнаружено превышение байта, передвинуть указатель потока +8 бит
    ; до тех пор, пока CL не будет <= 8
	sub	    cl, 8
	inc	    ebx
	jmp	    LZW_read_bits_count
    
    ; в ax имеем прочитанные биты (кол-во CH)

LZW_read_bits_ok:

	mov	    [LZW_bits], cl
	cmp	    eax, 100h
	jb	    LZW_single_byte         ; ax < 100h -- простой байт
	je	    LZW_clear               ; ax = 100h -- команда очистки словаря
	sub	    eax, 102h               ; ax = 101h -- завершение потока
	jc	    LZW_end

	shl	    eax, 3
	cmp	    eax, edx
	ja	    picture_error           ; eax - указатель на словарь если edx < eax, словарь превышен
    
    ; СЛОВАРЬ (8 байт на 1 эл-т)
    
    ; 4 | +0 | Количество символов
    ; 4 | +4 | Указатель на строку для повторения
    
	mov	    ecx, [LZW_table + eax]
	mov	    esi, [LZW_table + eax + 4]
    
    ; Записать в следующий элемент текущий указатель EDI (построение словаря)
	mov	    [LZW_table + edx + 4], edi  
	rep	    movsb
    
    ; Скопировать кол-во символов из предыдущего элемента и +1 к длине
	mov	    eax, [LZW_table + eax]
	inc	    eax
	mov	    [LZW_table + edx], eax
	jmp	    LZW_decompress_next
    
    ; Строительство нового словаря
    
LZW_single_byte:

	mov	    [LZW_table + edx], 2	    ; Добавить словарь: длина = 2, указатель
    mov	    [LZW_table + edx + 4], edi  ; текущий указатель на выходной поток
	stosb                               ; Скопировать один байт из входящего потока
    
    ; Добавляем +1 эл-т к словарю и переходим далее
    
LZW_decompress_next:

	add	    edx, 8
	jmp	    LZW_decompress_loop
    
; ----------------------------------------------------------------------    
LZW_end:


	cominvk DDSPicture,Unlock,0

	mov	    eax, [DDSPicture]
	clc
	ret

picture_error:

	stc
	ret

; ----------------------------------------------------------------------
load_palette:

	invoke	CreateFileA,esi,GENERIC_READ,0,0,OPEN_EXISTING,0,0
	mov	    edi,eax
	invoke	ReadFile,edi,buffer,GIFHEADER.length+256*3,bytes_count,0
	cmp	    [bytes_count],GIFHEADER.length+256*3
	jne	    picture_error
	invoke	CloseHandle, edi

	cmp	    [GIFHEADER.ID],'GIF8'
	jne	    picture_error
    
	cmp	    [GIFHEADER.ver],'7a'
	jne	    picture_error
    
	mov	    al,[GIFHEADER.bits]
	and	    al,111b
	cmp	    al,111b
	jne	    picture_error

	mov	    esi, buffer + GIFHEADER.length
	mov	    edi, buffer + 400h
	mov	    ecx,256
    
convert_palette:

	movsw
	movsb
	xor	    al,al
	stosb
	loop	convert_palette

	cominvk DDraw,CreatePalette,\
		DDPCAPS_8BIT+DDPCAPS_ALLOW256,buffer+400h,DDPalette,0
	or	eax,eax
	jnz	picture_error

	clc
	ret
