IoWait:
	push	ebp
	mov	ebp, esp
	jcxz $+2
	jcxz $+2
	pop	ebp
	ret
sys_irq_redirect:
	push	ebp
	mov	ebp, esp
	push edx
mov ecx, 0x1B
rdmsr
and eax, 0xfffff7ff
wrmsr
pop edx
	mov	al, 17
	out 32, al
	call	IoWait
	mov	al, 17
	out 160, al
	call	IoWait
	mov	al, 32
	out 33, al
	call	IoWait
	mov	al, 40
	out 161, al
	call	IoWait
	mov	al, 4
	out 33, al
	call	IoWait
	mov	al, 2
	out 161, al
	call	IoWait
	mov	al, 1
	out 33, al
	call	IoWait
	mov	al, 1
	out 161, al
	call	IoWait
	mov	al, -1
	out 33, al
	call	IoWait
	mov	al, -1
	out 161, al
	call	IoWait
	in al, 33
	and	eax, DWORD [ebp+8]
	out 33, al
	in al, 161
	mov	edx, DWORD [ebp+8]
	sar	edx, 8
	and	eax, edx
	out 161, al
	pop	ebp
	ret
sys_irq_create:
	push	ebp
	mov	ebp, esp
	mov	eax, DWORD [ebp+8]
	mov	edx, DWORD [ebp+12]
	push	ebx
	sal	eax, 3
	movzx	ecx, ax
	mov	ebx, edx
	mov	BYTE [ecx], dl
	lea	ecx, [eax+1]
	movzx	ecx, cx
	shr	ebx, 8
	mov	BYTE [ecx], bl
	lea	ecx, [eax+2]
	mov	ebx, edx
	movzx	ecx, cx
	mov	BYTE [ecx], 8
	lea	ecx, [eax+3]
	movzx	ecx, cx
	mov	BYTE [ecx], 0
	lea	ecx, [eax+4]
	movzx	ecx, cx
	mov	BYTE [ecx], 0
	lea	ecx, [eax+5]
	movzx	ecx, cx
	mov	BYTE [ecx], -114
	lea	ecx, [eax+6]
	add	eax, 7
	shr	ebx, 16
	movzx	ecx, cx
	movzx	eax, ax
	shr	edx, 24
	mov	BYTE [ecx], bl
	mov	BYTE [eax], dl
	pop	ebx
	pop	ebp
	ret
sys_irq_make:
	push	ebp
	mov	ebp, esp
	push	ebx
	xor	ebx, ebx
.L9:
	push	_irq_isr_null
	push	ebx
	inc	ebx
	call	sys_irq_create
	cmp	ebx, 256
	pop	eax
	pop	edx
	jne	.L9
	mov	ebx, DWORD [ebp-4]
	leave
	ret
malloc:
	push	ebp
	mov	eax, DWORD [mem_top]
	mov	ebp, esp
	mov	edx, DWORD [ebp+8]
	pop	ebp
	add	edx, eax
	mov	DWORD [mem_top], edx
	ret
mem_paging_init:
	mov	eax, DWORD [mem_top]
	lea	edx, [eax+4096]
	mov	DWORD [data_pdbr], eax
	xor	eax, eax
	mov	DWORD [mem_top], edx
.L16:
	mov	edx, DWORD [data_pdbr]
	mov	BYTE [edx+eax], 0
	inc	eax
	cmp	eax, 4096
	jne	.L16
	mov	ecx, DWORD [data_pdbr]
	mov	edx, 4194304
	xor	ax, ax
	push	ebp
	mov	ebp, esp
	push	ebx
.L20:
	mov	ebx, eax
	sal	ebx, 22
	cmp	ebx, DWORD [mem_size]
	jb	.L17
	mov	DWORD [ecx+eax*4], 0
	jmp	.L18
.L17:
	mov	ebx, edx
	or	ebx, 3
	mov	DWORD [ecx+eax*4], ebx
.L18:
	inc	eax
	add	edx, 4096
	cmp	eax, 1024
	jne	.L20
	xor	ax, ax
.L23:
	mov	edx, eax
	sal	edx, 12
	cmp	edx, DWORD [mem_size]
	jbe	.L21
.L22:
	mov eax, 0x00100000
mov cr3, eax
	mov eax, cr0
or  eax, 0x80000000
mov cr0, eax
	jmp @f
@@:
	pop	ebx
	pop	ebp
	ret
.L21:
	or	edx, 3
	mov	DWORD [4194304+eax*4], edx
	inc	eax
	cmp	eax, 1048576
	jne	.L23
	jmp	.L22
mem_init:
	push	ebp
	mov	ebp, esp
	call	mem_paging_init
	mov	eax, DWORD [mem_top]
	pop	ebp
	lea	edx, [eax+65536]
	mov	DWORD [mem_keyb_pressed], edx
	lea	edx, [eax+65792]
	mov	DWORD [mem_sys], eax
	mov	DWORD [mem_keyb_buffer], edx
	lea	edx, [eax+70400]
	add	eax, 66304
	mov	DWORD [mem_top], edx
	mov	DWORD [data_sys_task], eax
	ret
dev_keyb_isr:
	push	ebp
	mov	ebp, esp
	in al, 96
	test	al, al
	mov	edx, DWORD [mem_keyb_pressed]
	jns	.L32
	mov	ecx, eax
	and	ecx, 127
	mov	BYTE [edx+ecx], 0
	jmp	.L33
.L32:
	movzx	ecx, al
	mov	BYTE [edx+ecx], -1
.L33:
	cmp	al, 42
	je	.L31
	cmp	al, 54
	je	.L31
	cmp	al, 56
	je	.L31
	cmp	al, 29
	je	.L31
	cmp	al, -32
	je	.L31
	mov	edx, DWORD [keyb_buffer_ptr]
	lea	ecx, [edx+1]
	mov	DWORD [keyb_buffer_ptr], ecx
	mov	ecx, DWORD [mem_keyb_buffer]
	mov	BYTE [ecx+edx], al
.L31:
	pop	ebp
	ret
dev_keyb_get:
	xor	eax, eax
	cmp	DWORD [keyb_buffer_ptr], 0
	je	.L46
	push	ebp
	mov	ebp, esp
	push	esi
	push	ebx
	cli
	mov	eax, DWORD [mem_keyb_buffer]
	xor	ecx, ecx
	mov	al, BYTE [eax]
.L41:
	mov	ebx, DWORD [keyb_buffer_ptr]
	movzx	edx, cx
	cmp	edx, ebx
	jnb	.L47
	mov	esi, DWORD [mem_keyb_buffer]
	inc	ecx
	mov	bl, BYTE [esi+1+edx]
	mov	BYTE [esi+edx], bl
	jmp	.L41
.L47:
	dec	ebx
	mov	DWORD [keyb_buffer_ptr], ebx
	sti
	pop	ebx
	pop	esi
	pop	ebp
.L46:
	ret
dev_key_test:
	push	ebp
	mov	edx, DWORD [mem_keyb_pressed]
	mov	ebp, esp
	movzx	eax, BYTE [ebp+8]
	pop	ebp
	mov	al, BYTE [edx+eax]
	ret
dev_key_ascii:
	push	ebp
	mov	edx, DWORD [mem_keyb_pressed]
	mov	ebp, esp
	mov	al, BYTE [ebp+8]
	and	eax, 127
	cmp	BYTE [edx+42], 0
	movzx	eax, al
	jne	.L51
	cmp	BYTE [edx+54], 0
	je	.L52
.L51:
	mov	al, BYTE [dev_keyb_scan2ascii_HI+eax]
	jmp	.L53
.L52:
	mov	al, BYTE [dev_keyb_scan2ascii+eax]
.L53:
	pop	ebp
	ret
vga_videomode:
	push	ebp
	mov	edx, 962
	mov	ebp, esp
	mov	ecx, DWORD [ebp+8]
	push	edi
	push	esi
	push	ebx
	mov	al, BYTE [ecx]
	out dx, al
	xor	ebx, ebx
	mov	edi, 964
	mov	esi, 965
.L57:
	mov	edx, edi
	mov	al, bl
	out dx, al
	mov	al, BYTE [ecx+1+ebx]
	mov	edx, esi
	out dx, al
	inc	ebx
	cmp	ebx, 5
	jne	.L57
	mov	esi, 980
	mov	al, 3
	mov	edx, esi
	out dx, al
	mov	ebx, 981
	mov	edx, ebx
	in al, dx
	or	eax, -128
	out dx, al
	mov	al, 17
	mov	edx, esi
	out dx, al
	mov	edx, ebx
	in al, dx
	and	eax, 127
	out dx, al
	or	BYTE [ecx+9], -128
	xor	ebx, ebx
	and	BYTE [ecx+23], 127
	mov	edi, 980
	mov	esi, 981
.L59:
	mov	edx, edi
	mov	al, bl
	out dx, al
	mov	al, BYTE [ecx+6+ebx]
	mov	edx, esi
	out dx, al
	inc	ebx
	cmp	ebx, 25
	jne	.L59
	xor	bl, bl
	mov	edi, 974
	mov	esi, 975
.L61:
	mov	edx, edi
	mov	al, bl
	out dx, al
	mov	al, BYTE [ecx+31+ebx]
	mov	edx, esi
	out dx, al
	inc	ebx
	cmp	ebx, 9
	jne	.L61
	xor	bl, bl
	mov	edx, 960
.L63:
	mov	al, bl
	out dx, al
	mov	al, BYTE [ecx+40+ebx]
	out dx, al
	inc	ebx
	cmp	ebx, 21
	jne	.L63
	mov	edx, 986
	in al, dx
	mov	al, 32
	mov	dl, -64
	out dx, al
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	ret
vga_bitclr:
	push	ebp
	mov	eax, 517
	mov	ebp, esp
	mov	edx, 974
	out dx, ax
	mov	eax, -248
	out dx, ax
	pop	ebp
	ret
vga_cls:
	push	ebp
	xor	eax, eax
	mov	ebp, esp
.L69:
	mov	edx, DWORD [VGAMEM]
	mov	BYTE [edx+eax], 0
	inc	eax
	cmp	eax, 38400
	jne	.L69
	pop	ebp
	ret
vga_dac_set:
	push	ebp
	mov	edx, 968
	mov	ebp, esp
	mov	ecx, DWORD [ebp+12]
	mov	eax, DWORD [ebp+8]
	out dx, al
	mov	eax, ecx
	mov	dl, -55
	shr	eax, 2
	and	eax, 63
	out dx, al
	mov	eax, ecx
	shr	eax, 10
	and	eax, 63
	out dx, al
	mov	eax, ecx
	shr	eax, 18
	and	eax, 63
	out dx, al
	pop	ebp
	ret
vga_set_hicolor:
	push	ebp
	mov	ebp, esp
	push	vgamode_640x480
	call	vga_videomode
	call	vga_bitclr
	push	16777215
	push	15
	call	vga_dac_set
	add	esp, 12
	leave
	ret
vga_wr:
	push	ebp
	mov	ebp, esp
	sub	esp, 16
	mov	eax, DWORD [VGAMEM]
	add	eax, DWORD [ebp+8]
	mov	dl, BYTE [eax]
	mov	BYTE [ebp-1], dl
	mov	edx, DWORD [ebp+12]
	mov	BYTE [eax], dl
	leave
	ret
vga_fillrect:
	push	ebp
	mov	edx, 974
	mov	ebp, esp
	push	edi
	push	esi
	push	ebx
	sub	esp, 16
	mov	eax, DWORD [ebp+20]
	mov	edi, DWORD [ebp+12]
	mov	esi, DWORD [ebp+8]
	mov	WORD [ebp-14], ax
	mov	al, BYTE [ebp+24]
	mov	ebx, edi
	mov	BYTE [ebp-15], al
	mov	eax, 517
	out dx, ax
	mov	eax, esi
	mov	ecx, 8
	and	eax, 7
	mov	edx, 32640
	sub	ecx, eax
	mov	eax, 1
	sal	eax, cl
	mov	ecx, DWORD [ebp+16]
	shr	si, 3
	dec	eax
	and	ecx, 7
	sar	edx, cl
	mov	ecx, DWORD [ebp+16]
	movzx	edx, dl
	mov	WORD [ebp-18], dx
	shr	cx, 3
	cmp	cx, si
	mov	WORD [ebp-20], cx
	jbe	.L78
	sal	eax, 8
	mov	edx, 974
	or	eax, 8
	out dx, ax
	movzx	edx, BYTE [ebp-15]
	movzx	eax, si
	mov	DWORD [ebp-24], eax
.L79:
	cmp	di, WORD [ebp-14]
	ja	.L91
	movzx	ecx, di
	inc	edi
	imul	ecx, ecx, 80
	add	ecx, DWORD [ebp-24]
	push	edx
	push	ecx
	mov	DWORD [ebp-28], edx
	call	vga_wr
	mov	edx, DWORD [ebp-28]
	pop	ecx
	pop	eax
	jmp	.L79
.L91:
	mov	eax, -248
	mov	edx, 974
	out dx, ax
	movzx	edx, BYTE [ebp-15]
	inc	esi
.L81:
	cmp	si, WORD [ebp-20]
	je	.L83
	movzx	eax, si
	mov	edi, ebx
	mov	DWORD [ebp-24], eax
.L84:
	cmp	di, WORD [ebp-14]
	ja	.L92
	movzx	ecx, di
	inc	edi
	imul	ecx, ecx, 80
	add	ecx, DWORD [ebp-24]
	push	edx
	push	ecx
	mov	DWORD [ebp-28], edx
	call	vga_wr
	pop	eax
	pop	edx
	mov	edx, DWORD [ebp-28]
	jmp	.L84
.L92:
	inc	esi
	jmp	.L81
.L83:
	mov	ax, WORD [ebp-18]
	mov	edx, 974
	sal	eax, 8
	or	eax, 8
	out dx, ax
	movzx	edi, BYTE [ebp-15]
	movzx	esi, si
.L85:
	cmp	bx, WORD [ebp-14]
	ja	.L77
	movzx	eax, bx
	inc	ebx
	imul	eax, eax, 80
	push	edi
	add	eax, esi
	push	eax
	call	vga_wr
	pop	ecx
	pop	eax
	jmp	.L85
.L78:
	and	ax, WORD [ebp-18]
	mov	edx, 974
	sal	eax, 8
	or	eax, 8
	out dx, ax
	movzx	edi, BYTE [ebp-15]
	movzx	esi, si
.L87:
	cmp	bx, WORD [ebp-14]
	ja	.L77
	movzx	eax, bx
	inc	ebx
	imul	eax, eax, 80
	push	edi
	add	eax, esi
	push	eax
	call	vga_wr
	pop	eax
	pop	edx
	jmp	.L87
.L77:
	lea	esp, [ebp-12]
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	ret
vga_pixel:
	push	ebp
	mov	eax, 32768
	mov	ebp, esp
	mov	edx, 974
	mov	ecx, DWORD [ebp+8]
	push	ebx
	mov	ebx, DWORD [ebp+12]
	and	ecx, 7
	sar	eax, cl
	or	eax, 8
	out dx, ax
	movzx	eax, BYTE [ebp+16]
	movzx	ebx, bx
	imul	ebx, ebx, 80
	mov	DWORD [ebp+12], eax
	mov	eax, DWORD [ebp+8]
	shr	ax, 3
	movzx	eax, ax
	add	ebx, eax
	mov	DWORD [ebp+8], ebx
	pop	ebx
	pop	ebp
	jmp	vga_wr
vga_line:
	push	ebp
	mov	ebp, esp
	push	edi
	push	esi
	push	ebx
	sub	esp, 24
	mov	eax, DWORD [ebp+16]
	mov	edx, DWORD [ebp+12]
	mov	esi, DWORD [ebp+8]
	mov	ecx, DWORD [ebp+20]
	movzx	edi, WORD [ebp+12]
	mov	WORD [ebp-24], dx
	movzx	edx, ax
	mov	ebx, edx
	mov	WORD [ebp-32], cx
	movzx	ecx, si
	sub	ebx, ecx
	sub	ecx, edx
	cmp	ax, si
	cmova	ecx, ebx
	mov	DWORD [ebp-16], ecx
	movzx	ecx, WORD [ebp+20]
	mov	WORD [ebp-30], ax
	mov	WORD [ebp-22], si
	mov	ebx, ecx
	sub	ebx, edi
	sub	edi, ecx
	mov	DWORD [ebp-20], edi
	mov	edi, DWORD [ebp+12]
	cmp	WORD [ebp+20], di
	cmovbe	ebx, DWORD [ebp-20]
	cmp	si, ax
	sbb	eax, eax
	mov	DWORD [ebp-20], eax
	mov	eax, DWORD [ebp+20]
	and	DWORD [ebp-20], 2
	dec	DWORD [ebp-20]
	cmp	di, ax
	movzx	eax, BYTE [ebp+24]
	mov	edi, DWORD [ebp-16]
	sbb	esi, esi
	and	esi, 2
	dec	esi
	push	eax
	push	ecx
	sub	edi, ebx
	push	edx
	mov	DWORD [ebp-28], eax
	call	vga_pixel
	mov	eax, ebx
	add	esp, 12
	neg	eax
	mov	DWORD [ebp-36], eax
.L102:
	mov	eax, DWORD [ebp-32]
	cmp	WORD [ebp-24], ax
	je	.L109
.L105:
	push	DWORD [ebp-28]
	movzx	edx, WORD [ebp-24]
	push	edx
	movzx	edx, WORD [ebp-22]
	push	edx
	call	vga_pixel
	lea	edx, [edi+edi]
	add	esp, 12
	cmp	edx, DWORD [ebp-36]
	jle	.L103
	mov	eax, DWORD [ebp-20]
	sub	edi, ebx
	add	WORD [ebp-22], ax
.L103:
	cmp	edx, DWORD [ebp-16]
	jge	.L102
	add	edi, DWORD [ebp-16]
	add	WORD [ebp-24], si
	jmp	.L102
.L109:
	mov	ax, WORD [ebp-30]
	cmp	WORD [ebp-22], ax
	jne	.L105
	lea	esp, [ebp-12]
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	ret
vga_rect:
	push	ebp
	mov	ebp, esp
	push	edi
	push	esi
	push	ebx
	sub	esp, 8
	movzx	ebx, BYTE [ebp+24]
	movzx	eax, WORD [ebp+12]
	movzx	edx, WORD [ebp+16]
	movzx	esi, WORD [ebp+8]
	push	ebx
	mov	edi, DWORD [ebp+20]
	push	eax
	push	edx
	push	eax
	push	esi
	movzx	edi, di
	mov	DWORD [ebp-20], edx
	mov	DWORD [ebp-16], eax
	call	vga_line
	mov	edx, DWORD [ebp-20]
	mov	eax, DWORD [ebp-16]
	push	ebx
	push	edi
	push	edx
	push	eax
	push	edx
	mov	DWORD [ebp-20], eax
	mov	DWORD [ebp-16], edx
	call	vga_line
	add	esp, 40
	mov	edx, DWORD [ebp-16]
	push	ebx
	push	edi
	push	esi
	push	edi
	push	edx
	call	vga_line
	mov	eax, DWORD [ebp-20]
	add	esp, 20
	mov	DWORD [ebp+24], ebx
	mov	DWORD [ebp+16], esi
	mov	DWORD [ebp+12], edi
	mov	DWORD [ebp+8], esi
	mov	DWORD [ebp+20], eax
	lea	esp, [ebp-12]
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	jmp	vga_line
vga_put_char:
	push	ebp
	mov	ebp, esp
	push	edi
	push	esi
	push	ebx
	xor	ebx, ebx
	sub	esp, 16
	mov	eax, DWORD [ebp+8]
	movzx	edi, BYTE [ebp+16]
	mov	WORD [ebp-16], ax
	mov	eax, DWORD [ebp+12]
	sal	edi, 4
	mov	WORD [ebp-18], ax
	movzx	eax, BYTE [ebp+20]
.L117:
	mov	dl, BYTE [bios_font+edi+ebx]
	xor	esi, esi
	mov	cx, WORD [ebp-18]
	mov	BYTE [ebp-13], dl
	lea	edx, [ecx+ebx]
	movzx	edx, dx
.L115:
	movzx	ecx, BYTE [ebp-13]
	bt	ecx, esi
	jnc	.L113
	push	eax
	push	edx
	mov	DWORD [ebp-28], eax
	mov	eax, DWORD [ebp-16]
	mov	DWORD [ebp-24], edx
	lea	ecx, [eax+esi]
	movzx	ecx, cx
	push	ecx
	call	vga_pixel
	mov	eax, DWORD [ebp-28]
	add	esp, 12
	mov	edx, DWORD [ebp-24]
.L113:
	inc	esi
	cmp	esi, 8
	jne	.L115
	inc	ebx
	cmp	ebx, 16
	jne	.L117
	lea	esp, [ebp-12]
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	ret
vga_put_zstring:
	push	ebp
	mov	ebp, esp
	push	edi
	movzx	edi, BYTE [ebp+20]
	push	esi
	mov	esi, DWORD [ebp+8]
	push	ebx
	movzx	ebx, WORD [ebp+12]
.L123:
	mov	eax, DWORD [ebp+16]
	movzx	eax, BYTE [eax]
	test	al, al
	je	.L126
	push	edi
	push	eax
	movzx	eax, si
	push	ebx
	add	esi, 8
	push	eax
	call	vga_put_char
	add	esp, 16
	inc	DWORD [ebp+16]
	jmp	.L123
.L126:
	lea	esp, [ebp-12]
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	ret
ui_window:
	push	ebp
	mov	ebp, esp
	push	edi
	push	esi
	push	ebx
	sub	esp, 24
	mov	eax, DWORD [ebp+16]
	mov	ebx, DWORD [ebp+12]
	mov	esi, DWORD [ebp+8]
	push	0
	mov	edx, DWORD [ebp+24]
	mov	edi, eax
	mov	eax, DWORD [ebp+20]
	mov	DWORD [ebp-24], edx
	mov	DWORD [ebp-16], eax
	movzx	eax, WORD [ebp-16]
	push	eax
	movzx	eax, di
	push	eax
	movzx	eax, bx
	push	eax
	movzx	eax, si
	push	eax
	call	vga_rect
	mov	eax, DWORD [ebp-16]
	mov	ecx, edi
	push	8
	dec	ecx
	movzx	ecx, cx
	mov	DWORD [ebp-20], edi
	lea	edi, [esi+1]
	lea	edx, [eax-1]
	movzx	edi, di
	movzx	edx, dx
	push	edx
	push	ecx
	push	edx
	push	edi
	mov	DWORD [ebp-32], ecx
	mov	DWORD [ebp-28], edx
	call	vga_line
	mov	edx, DWORD [ebp-28]
	add	esp, 40
	mov	ecx, DWORD [ebp-32]
	lea	eax, [ebx+1]
	push	8
	movzx	eax, ax
	push	edx
	push	ecx
	push	eax
	push	ecx
	mov	DWORD [ebp-36], edx
	mov	DWORD [ebp-32], eax
	mov	DWORD [ebp-28], ecx
	call	vga_line
	mov	eax, DWORD [ebp-32]
	mov	ecx, DWORD [ebp-28]
	push	15
	push	eax
	push	ecx
	push	eax
	push	edi
	mov	DWORD [ebp-28], eax
	call	vga_line
	mov	edx, DWORD [ebp-36]
	add	esp, 40
	mov	eax, DWORD [ebp-28]
	push	15
	push	edx
	push	edi
	push	eax
	push	edi
	call	vga_line
	mov	ecx, DWORD [ebp-16]
	mov	edi, DWORD [ebp-20]
	push	7
	lea	eax, [ecx-2]
	movzx	eax, ax
	push	eax
	mov	eax, edi
	sub	eax, 2
	movzx	eax, ax
	push	eax
	lea	eax, [ebx+2]
	movzx	eax, ax
	push	eax
	lea	eax, [esi+2]
	movzx	eax, ax
	push	eax
	call	vga_fillrect
	add	esp, 40
	lea	eax, [ebx+26]
	push	1
	movzx	eax, ax
	push	eax
	mov	eax, edi
	sub	eax, 4
	movzx	eax, ax
	push	eax
	lea	eax, [ebx+4]
	add	ebx, 8
	movzx	eax, ax
	movzx	ebx, bx
	push	eax
	lea	eax, [esi+4]
	add	esi, 10
	movzx	eax, ax
	movzx	esi, si
	push	eax
	call	vga_fillrect
	mov	edx, DWORD [ebp-24]
	add	esp, 20
	mov	DWORD [ebp+12], ebx
	mov	DWORD [ebp+8], esi
	mov	DWORD [ebp+20], 15
	mov	DWORD [ebp+16], edx
	lea	esp, [ebp-12]
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	jmp	vga_put_zstring
ui_button:
	push	ebp
	mov	ebp, esp
	push	edi
	push	esi
	push	ebx
	sub	esp, 28
	mov	ecx, DWORD [ebp+12]
	mov	eax, DWORD [ebp+8]
	push	7
	mov	edi, ecx
	mov	DWORD [ebp-20], ecx
	mov	ecx, DWORD [ebp+16]
	movzx	edi, di
	movzx	edx, ax
	mov	DWORD [ebp-36], edx
	mov	DWORD [ebp-16], eax
	mov	esi, ecx
	mov	DWORD [ebp-28], ecx
	mov	ecx, DWORD [ebp+20]
	movzx	esi, si
	mov	ebx, ecx
	mov	DWORD [ebp-32], ecx
	mov	ecx, DWORD [ebp+24]
	movzx	ebx, bx
	push	ebx
	push	esi
	push	edi
	push	edx
	mov	DWORD [ebp-24], ecx
	mov	ecx, DWORD [ebp+28]
	mov	DWORD [ebp-40], ecx
	call	vga_fillrect
	mov	ecx, DWORD [ebp-40]
	add	esp, 20
	mov	edx, DWORD [ebp-36]
	test	cl, cl
	je	.L130
	push	8
	push	edi
	push	esi
	push	edi
	push	edx
	call	vga_line
	mov	edx, DWORD [ebp-36]
	push	8
	push	ebx
	push	edx
	push	edi
	push	edx
	call	vga_line
	add	esp, 40
	mov	edx, DWORD [ebp-36]
	push	15
	push	ebx
	push	esi
	push	ebx
	push	edx
	call	vga_line
	push	15
	push	ebx
	push	esi
	push	edi
	push	esi
	call	vga_line
	mov	eax, DWORD [ebp-20]
	add	esp, 40
	push	0
	push	DWORD [ebp-24]
	add	eax, 3
	movzx	eax, ax
	push	eax
	mov	eax, DWORD [ebp-16]
	add	eax, 5
	jmp	.L133
.L130:
	push	15
	push	edi
	push	esi
	push	edi
	push	edx
	mov	DWORD [ebp-36], edx
	call	vga_line
	mov	edx, DWORD [ebp-36]
	push	15
	push	ebx
	push	edx
	push	edi
	push	edx
	call	vga_line
	add	esp, 40
	mov	edx, DWORD [ebp-36]
	push	8
	push	ebx
	push	esi
	push	ebx
	push	edx
	call	vga_line
	push	8
	push	ebx
	push	esi
	push	edi
	push	esi
	call	vga_line
	mov	eax, DWORD [ebp-20]
	add	esp, 40
	push	0
	push	DWORD [ebp-24]
	add	eax, 2
	movzx	eax, ax
	push	eax
	mov	eax, DWORD [ebp-16]
	add	eax, 4
.L133:
	movzx	eax, ax
	push	eax
	call	vga_put_zstring
	mov	eax, DWORD [ebp-32]
	add	esp, 16
	mov	DWORD [ebp+24], 8
	dec	eax
	movzx	eax, ax
	mov	DWORD [ebp+20], eax
	mov	eax, DWORD [ebp-28]
	dec	eax
	movzx	eax, ax
	mov	DWORD [ebp+16], eax
	mov	eax, DWORD [ebp-20]
	inc	eax
	movzx	eax, ax
	mov	DWORD [ebp+12], eax
	mov	eax, DWORD [ebp-16]
	inc	eax
	movzx	eax, ax
	mov	DWORD [ebp+8], eax
	lea	esp, [ebp-12]
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	jmp	vga_rect
LC0:
	db "File Manager", 0
LC1:
	db "Console", 0
LC2:
	db "Text Editor", 0
ui_start_menu:
	mov	al, BYTE [ui_start_curr]
	test	al, al
	jns	.L135
	mov	BYTE [ui_start_curr], 0
	ret
.L135:
	cmp	al, 2
	jle	.L137
	mov	BYTE [ui_start_curr], 2
	ret
.L137:
	push	ebp
	mov	ebp, esp
	push	esi
	push	ebx
	mov	ebx, 15
	push	7
	push	450
	push	196
	push	270
	push	4
	call	vga_fillrect
	movsx	ax, BYTE [ui_start_curr]
	push	0
	lea	eax, [eax+eax*4]
	sal	eax, 2
	lea	edx, [eax+296]
	add	ax, 276
	movzx	edx, dx
	movzx	eax, ax
	push	edx
	push	196
	push	eax
	push	4
	call	vga_fillrect
	add	esp, 40
	cmp	BYTE [ui_start_curr], 1
	sbb	eax, eax
	xor	esi, esi
	and	eax, 15
	push	eax
	push	LC0
	push	280
	push	10
	call	vga_put_zstring
	add	esp, 16
	mov	eax, ebx
	cmp	BYTE [ui_start_curr], 1
	cmovne	eax, esi
	push	eax
	push	LC1
	push	300
	push	10
	call	vga_put_zstring
	add	esp, 16
	cmp	BYTE [ui_start_curr], 2
	cmovne	ebx, esi
	push	ebx
	push	LC2
	push	320
	push	10
	call	vga_put_zstring
	add	esp, 16
	lea	esp, [ebp-8]
	pop	ebx
	pop	esi
	pop	ebp
	ret
LC3:
	db "START", 0
LC4:
	db "Manage Applications", 0
LC5:
	db "***", 0
ui_start_bar:
	push	ebp
	mov	ebp, esp
	push	ebx
	push	7
	push	479
	push	639
	push	456
	push	0
	call	vga_fillrect
	push	8
	push	455
	push	639
	push	455
	push	0
	call	vga_fillrect
	add	esp, 40
	push	15
	push	456
	push	639
	push	456
	push	0
	call	vga_fillrect
	movzx	eax, BYTE [ui_start_expand]
	push	eax
	push	LC3
	push	476
	push	50
	push	458
	push	2
	call	ui_button
	add	esp, 44
	cmp	BYTE [ui_start_expand], 0
	je	.L147
	push	LC4
	push	454
	push	200
	push	240
	push	0
	call	ui_window
	call	ui_start_menu
	add	esp, 20
.L147:
	xor	ebx, ebx
.L148:
	movzx	edx, WORD [sys_task_last]
	imul	eax, ebx, 104
	cmp	ebx, edx
	lea	ecx, [eax+62]
	jge	.L151
	mov	edx, DWORD [data_sys_task]
	add	ax, 162
	movzx	ecx, cx
	movzx	eax, ax
	mov	dl, BYTE [edx+1+ebx*8]
	inc	ebx
	and	edx, 1
	push	edx
	push	LC5
	push	476
	push	eax
	push	458
	push	ecx
	call	ui_button
	add	esp, 24
	jmp	.L148
.L151:
	mov	ebx, DWORD [ebp-4]
	leave
	ret
addstr:
	push	ebp
	mov	ebp, esp
	push	edi
	push	esi
	push	ebx
	mov	ebx, DWORD [console]
.L153:
	mov	eax, DWORD [ebp+8]
	movsx	ax, BYTE [eax]
	test	al, al
	je	.L157
	mov	dl, BYTE [cursor_y]
	mov	cl, BYTE [cursor_x]
	movzx	edi, dl
	imul	edi, edi, 80
	movzx	esi, cl
	inc	ecx
	add	esi, edi
	cmp	cl, 79
	mov	WORD [ebx+esi*2], ax
	mov	BYTE [cursor_x], cl
	jbe	.L154
	inc	edx
	mov	BYTE [cursor_y], dl
.L154:
	inc	DWORD [ebp+8]
	jmp	.L153
.L157:
	pop	ebx
	pop	esi
	pop	edi
	pop	ebp
	ret
app_console:
	mov	edx, DWORD [mem_top]
	lea	eax, [edx+2400]
	mov	DWORD [mem_top], eax
	xor	eax, eax
	mov	DWORD [console], edx
.L160:
	mov	WORD [edx+eax*2], 0
	inc	eax
	cmp	eax, 2400
	jne	.L160
	push	ebp
	mov	ebp, esp
	push	1
	push	479
	push	639
	push	0
	push	0
	call	vga_fillrect
	add	esp, 20
.L161:
	jmp	.L161
app_desktop_redraw:
	push	ebp
	mov	ebp, esp
	push	1
	push	454
	push	639
	push	0
	push	0
	call	vga_fillrect
	add	esp, 20
	leave
	ret
app_ui_shadow:
	push	ebp
	mov	ebp, esp
	push	esi
	push	ebx
	xor	ebx, ebx
.L169:
	mov	esi, ebx
	and	esi, 1
.L167:
	push	0
	push	ebx
	push	esi
	add	esi, 2
	call	vga_pixel
	add	esp, 12
	cmp	esi, 639
	jle	.L167
	inc	ebx
	cmp	ebx, 455
	jne	.L169
	lea	esp, [ebp-8]
	pop	ebx
	pop	esi
	pop	ebp
	ret
app_add_task:
	push	ebp
	movzx	edx, WORD [sys_task_last]
	xor	eax, eax
	mov	ebp, esp
	mov	ecx, DWORD [data_sys_task]
	push	esi
	mov	esi, DWORD [ebp+8]
	push	ebx
.L172:
	movzx	ebx, al
	cmp	bx, dx
	jnb	.L175
	movzx	ebx, al
	inc	eax
	and	BYTE [ecx+1+ebx*8], -2
	jmp	.L172
.L175:
	lea	eax, [edx+1]
	mov	ecx, esi
	mov	WORD [sys_task_last], ax
	mov	eax, DWORD [data_sys_task]
	lea	eax, [eax+edx*8]
	mov	BYTE [eax], cl
	mov	BYTE [eax+1], 1
	mov	DWORD [eax+4], 0
	pop	ebx
	pop	esi
	pop	ebp
	ret
app_start:
	push	ebp
	mov	ebp, esp
	push	eax
	call	dev_keyb_get
	test	al, al
	js	.L176
	cmp	BYTE [ui_start_expand], 0
	je	.L179
	test	al, al
	je	.L176
	cmp	al, 80
	jne	.L181
	mov	DWORD [ebp-4], eax
	inc	BYTE [ui_start_curr]
	jmp	.L194
.L181:
	cmp	al, 72
	jne	.L183
	dec	BYTE [ui_start_curr]
	mov	DWORD [ebp-4], eax
.L194:
	call	ui_start_menu
	jmp	.L193
.L183:
	cmp	al, 28
	jne	.L185
	mov	edx, DWORD [mem_keyb_pressed]
	cmp	BYTE [edx+29], 0
	jne	.L185
	mov	DWORD [ebp-4], eax
	mov	BYTE [ui_start_expand], 0
	call	app_desktop_redraw
	push	1
	call	app_add_task
	call	ui_start_bar
	pop	ecx
.L193:
	mov	eax, DWORD [ebp-4]
	jmp	.L185
.L179:
	test	al, al
	je	.L176
.L185:
	movzx	eax, al
	push	eax
	call	dev_key_ascii
	pop	edx
	cmp	al, 10
	jne	.L176
	mov	eax, DWORD [mem_keyb_pressed]
	cmp	BYTE [eax+29], 0
	je	.L176
	xor	BYTE [ui_start_expand], 1
	jne	.L184
	call	app_desktop_redraw
.L184:
	leave
	jmp	ui_start_bar
.L176:
	leave
	ret
entry_main:
	push	ebp
	mov	ebp, esp
	push	65529
	call	sys_irq_redirect
	call	sys_irq_make
	push	_keyb_isr
	push	33
	call	sys_irq_create
	push	_irq_cascade
	push	34
	call	sys_irq_create
	call	mem_init
	call	vga_set_hicolor
	call	app_console
console:
	db 0,0,0,0
cursor_y:
	db 0
cursor_x:
	db 0
ui_start_curr:
	db 0
ui_start_expand:
	db 0
bios_font:
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	126
	db	-127
	db	-91
	db	-127
	db	-127
	db	-67
	db	-103
	db	-127
	db	-127
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	126
	db	-1
	db	-37
	db	-1
	db	-1
	db	-61
	db	-25
	db	-1
	db	-1
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	54
	db	127
	db	127
	db	127
	db	127
	db	62
	db	28
	db	8
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	8
	db	28
	db	62
	db	127
	db	62
	db	28
	db	8
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	60
	db	60
	db	-25
	db	-25
	db	-25
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	60
	db	126
	db	-1
	db	-1
	db	126
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	60
	db	60
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-25
	db	-61
	db	-61
	db	-25
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	102
	db	66
	db	66
	db	102
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-61
	db	-103
	db	-67
	db	-67
	db	-103
	db	-61
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	0
	db	0
	db	120
	db	112
	db	88
	db	76
	db	30
	db	51
	db	51
	db	51
	db	51
	db	30
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	102
	db	102
	db	102
	db	102
	db	60
	db	24
	db	126
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-4
	db	-52
	db	-4
	db	12
	db	12
	db	12
	db	12
	db	14
	db	15
	db	7
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-2
	db	-58
	db	-2
	db	-58
	db	-58
	db	-58
	db	-58
	db	-26
	db	-25
	db	103
	db	3
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	-37
	db	60
	db	-25
	db	60
	db	-37
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	1
	db	3
	db	7
	db	15
	db	31
	db	127
	db	31
	db	15
	db	7
	db	3
	db	1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	64
	db	96
	db	112
	db	120
	db	124
	db	127
	db	124
	db	120
	db	112
	db	96
	db	64
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	60
	db	126
	db	24
	db	24
	db	24
	db	126
	db	60
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	0
	db	102
	db	102
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-2
	db	-37
	db	-37
	db	-37
	db	-34
	db	-40
	db	-40
	db	-40
	db	-40
	db	-40
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	6
	db	28
	db	54
	db	99
	db	99
	db	54
	db	28
	db	48
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	127
	db	127
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	60
	db	126
	db	24
	db	24
	db	24
	db	126
	db	60
	db	24
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	60
	db	126
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	126
	db	60
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	48
	db	127
	db	48
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	12
	db	6
	db	127
	db	6
	db	12
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	3
	db	3
	db	3
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	20
	db	54
	db	127
	db	54
	db	20
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	8
	db	28
	db	28
	db	62
	db	62
	db	127
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	127
	db	62
	db	62
	db	28
	db	28
	db	8
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	60
	db	60
	db	60
	db	24
	db	24
	db	24
	db	0
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	102
	db	102
	db	102
	db	36
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	54
	db	54
	db	127
	db	54
	db	54
	db	54
	db	127
	db	54
	db	54
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	62
	db	99
	db	67
	db	3
	db	62
	db	96
	db	96
	db	97
	db	99
	db	62
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	67
	db	99
	db	48
	db	24
	db	12
	db	6
	db	99
	db	97
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	28
	db	54
	db	54
	db	28
	db	110
	db	59
	db	51
	db	51
	db	51
	db	110
	db	0
	db	0
	db	0
	db	0
	db	0
	db	12
	db	12
	db	12
	db	6
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	48
	db	24
	db	12
	db	12
	db	12
	db	12
	db	12
	db	12
	db	24
	db	48
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	12
	db	24
	db	48
	db	48
	db	48
	db	48
	db	48
	db	48
	db	24
	db	12
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	102
	db	60
	db	-1
	db	60
	db	102
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	126
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	24
	db	12
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	64
	db	96
	db	48
	db	24
	db	12
	db	6
	db	3
	db	1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	28
	db	54
	db	99
	db	99
	db	107
	db	107
	db	99
	db	99
	db	54
	db	28
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	28
	db	30
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	96
	db	48
	db	24
	db	12
	db	6
	db	3
	db	99
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	96
	db	96
	db	60
	db	96
	db	96
	db	96
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	48
	db	56
	db	60
	db	54
	db	51
	db	127
	db	48
	db	48
	db	48
	db	120
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	3
	db	3
	db	3
	db	63
	db	96
	db	96
	db	96
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	28
	db	6
	db	3
	db	3
	db	63
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	99
	db	96
	db	96
	db	48
	db	24
	db	12
	db	12
	db	12
	db	12
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	62
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	126
	db	96
	db	96
	db	96
	db	48
	db	30
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	0
	db	0
	db	0
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	0
	db	0
	db	0
	db	24
	db	24
	db	12
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	96
	db	48
	db	24
	db	12
	db	6
	db	12
	db	24
	db	48
	db	96
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	126
	db	0
	db	0
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	6
	db	12
	db	24
	db	48
	db	96
	db	48
	db	24
	db	12
	db	6
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	48
	db	24
	db	24
	db	24
	db	0
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	123
	db	123
	db	123
	db	59
	db	3
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	8
	db	28
	db	54
	db	99
	db	99
	db	127
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	63
	db	102
	db	102
	db	102
	db	62
	db	102
	db	102
	db	102
	db	102
	db	63
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	102
	db	67
	db	3
	db	3
	db	3
	db	3
	db	67
	db	102
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	31
	db	54
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	54
	db	31
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	102
	db	70
	db	22
	db	30
	db	22
	db	6
	db	70
	db	102
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	102
	db	70
	db	22
	db	30
	db	22
	db	6
	db	6
	db	6
	db	15
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	102
	db	67
	db	3
	db	3
	db	123
	db	99
	db	99
	db	102
	db	92
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	99
	db	99
	db	127
	db	99
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	120
	db	48
	db	48
	db	48
	db	48
	db	48
	db	51
	db	51
	db	51
	db	30
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	103
	db	102
	db	102
	db	54
	db	30
	db	30
	db	54
	db	102
	db	102
	db	103
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	15
	db	6
	db	6
	db	6
	db	6
	db	6
	db	6
	db	70
	db	102
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	119
	db	127
	db	127
	db	107
	db	99
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	103
	db	111
	db	127
	db	123
	db	115
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	63
	db	102
	db	102
	db	102
	db	62
	db	6
	db	6
	db	6
	db	6
	db	15
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	107
	db	123
	db	62
	db	48
	db	112
	db	0
	db	0
	db	0
	db	0
	db	63
	db	102
	db	102
	db	102
	db	62
	db	54
	db	102
	db	102
	db	102
	db	103
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	6
	db	28
	db	48
	db	96
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	126
	db	126
	db	90
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	54
	db	28
	db	8
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	99
	db	99
	db	107
	db	107
	db	107
	db	127
	db	119
	db	54
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	54
	db	62
	db	28
	db	28
	db	62
	db	54
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	102
	db	102
	db	102
	db	102
	db	60
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	99
	db	97
	db	48
	db	24
	db	12
	db	6
	db	67
	db	99
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	12
	db	12
	db	12
	db	12
	db	12
	db	12
	db	12
	db	12
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	1
	db	3
	db	7
	db	14
	db	28
	db	56
	db	112
	db	96
	db	64
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	48
	db	48
	db	48
	db	48
	db	48
	db	48
	db	48
	db	48
	db	60
	db	0
	db	0
	db	0
	db	0
	db	8
	db	28
	db	54
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	0
	db	0
	db	12
	db	12
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	30
	db	48
	db	62
	db	51
	db	51
	db	51
	db	110
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	7
	db	6
	db	6
	db	30
	db	54
	db	102
	db	102
	db	102
	db	102
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	3
	db	3
	db	3
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	56
	db	48
	db	48
	db	60
	db	54
	db	51
	db	51
	db	51
	db	51
	db	110
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	127
	db	3
	db	3
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	28
	db	54
	db	38
	db	6
	db	15
	db	6
	db	6
	db	6
	db	6
	db	15
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	110
	db	51
	db	51
	db	51
	db	51
	db	51
	db	62
	db	48
	db	51
	db	30
	db	0
	db	0
	db	0
	db	7
	db	6
	db	6
	db	54
	db	110
	db	102
	db	102
	db	102
	db	102
	db	103
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	0
	db	28
	db	24
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	96
	db	96
	db	0
	db	112
	db	96
	db	96
	db	96
	db	96
	db	96
	db	96
	db	102
	db	102
	db	60
	db	0
	db	0
	db	0
	db	7
	db	6
	db	6
	db	102
	db	54
	db	30
	db	30
	db	54
	db	102
	db	103
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	28
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	55
	db	127
	db	107
	db	107
	db	107
	db	107
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	59
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	59
	db	102
	db	102
	db	102
	db	102
	db	102
	db	62
	db	6
	db	6
	db	15
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	110
	db	51
	db	51
	db	51
	db	51
	db	51
	db	62
	db	48
	db	48
	db	120
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	59
	db	110
	db	102
	db	6
	db	6
	db	6
	db	15
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	6
	db	28
	db	48
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	8
	db	12
	db	12
	db	63
	db	12
	db	12
	db	12
	db	12
	db	108
	db	56
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	51
	db	51
	db	51
	db	51
	db	51
	db	51
	db	110
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	102
	db	102
	db	102
	db	102
	db	102
	db	60
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	107
	db	107
	db	107
	db	127
	db	54
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	54
	db	28
	db	28
	db	28
	db	54
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	126
	db	96
	db	48
	db	31
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	51
	db	24
	db	12
	db	6
	db	99
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	112
	db	24
	db	24
	db	24
	db	14
	db	24
	db	24
	db	24
	db	24
	db	112
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	24
	db	24
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	14
	db	24
	db	24
	db	24
	db	112
	db	24
	db	24
	db	24
	db	24
	db	14
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	110
	db	59
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	8
	db	28
	db	54
	db	99
	db	99
	db	99
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	8
	db	28
	db	54
	db	99
	db	99
	db	127
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	63
	db	102
	db	102
	db	102
	db	62
	db	102
	db	102
	db	102
	db	102
	db	63
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	67
	db	3
	db	3
	db	3
	db	3
	db	3
	db	3
	db	3
	db	3
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	8
	db	28
	db	54
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	102
	db	70
	db	22
	db	30
	db	22
	db	6
	db	70
	db	102
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	99
	db	97
	db	48
	db	24
	db	12
	db	6
	db	67
	db	99
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	99
	db	99
	db	127
	db	99
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	127
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	103
	db	102
	db	102
	db	54
	db	30
	db	30
	db	54
	db	102
	db	102
	db	103
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	8
	db	28
	db	54
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	119
	db	127
	db	127
	db	107
	db	99
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	103
	db	111
	db	127
	db	123
	db	115
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	65
	db	0
	db	0
	db	62
	db	0
	db	0
	db	0
	db	65
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	63
	db	102
	db	102
	db	102
	db	62
	db	6
	db	6
	db	6
	db	6
	db	15
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	99
	db	70
	db	12
	db	24
	db	24
	db	12
	db	70
	db	99
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	126
	db	126
	db	90
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	102
	db	102
	db	102
	db	102
	db	60
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	107
	db	107
	db	107
	db	107
	db	107
	db	62
	db	8
	db	8
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	54
	db	62
	db	28
	db	28
	db	62
	db	54
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	107
	db	107
	db	107
	db	107
	db	107
	db	107
	db	62
	db	8
	db	8
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	99
	db	99
	db	119
	db	54
	db	54
	db	119
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	110
	db	51
	db	51
	db	51
	db	51
	db	51
	db	110
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	30
	db	51
	db	51
	db	51
	db	31
	db	51
	db	51
	db	51
	db	51
	db	31
	db	3
	db	3
	db	3
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	99
	db	99
	db	54
	db	28
	db	54
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	63
	db	3
	db	6
	db	12
	db	24
	db	62
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	126
	db	3
	db	3
	db	62
	db	3
	db	3
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	48
	db	24
	db	12
	db	6
	db	3
	db	3
	db	3
	db	3
	db	62
	db	96
	db	96
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	59
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	30
	db	51
	db	48
	db	48
	db	62
	db	51
	db	51
	db	51
	db	51
	db	30
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	112
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	103
	db	54
	db	30
	db	30
	db	54
	db	102
	db	103
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	96
	db	96
	db	124
	db	102
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	51
	db	51
	db	51
	db	51
	db	51
	db	51
	db	111
	db	3
	db	3
	db	3
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	102
	db	102
	db	102
	db	102
	db	102
	db	60
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	48
	db	24
	db	12
	db	6
	db	6
	db	60
	db	6
	db	3
	db	62
	db	96
	db	96
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	60
	db	102
	db	102
	db	102
	db	102
	db	102
	db	62
	db	6
	db	6
	db	6
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	126
	db	51
	db	51
	db	51
	db	51
	db	51
	db	30
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	99
	db	3
	db	62
	db	96
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	63
	db	12
	db	12
	db	12
	db	12
	db	108
	db	56
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	3
	db	59
	db	107
	db	107
	db	107
	db	62
	db	8
	db	8
	db	8
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	54
	db	28
	db	28
	db	28
	db	54
	db	99
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	107
	db	107
	db	107
	db	107
	db	107
	db	107
	db	62
	db	8
	db	8
	db	8
	db	0
	db	34
	db	-120
	db	34
	db	-120
	db	34
	db	-120
	db	34
	db	-120
	db	34
	db	-120
	db	34
	db	-120
	db	34
	db	-120
	db	34
	db	-120
	db	-86
	db	85
	db	-86
	db	85
	db	-86
	db	85
	db	-86
	db	85
	db	-86
	db	85
	db	-86
	db	85
	db	-86
	db	85
	db	-86
	db	85
	db	-69
	db	-18
	db	-69
	db	-18
	db	-69
	db	-18
	db	-69
	db	-18
	db	-69
	db	-18
	db	-69
	db	-18
	db	-69
	db	-18
	db	-69
	db	-18
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	31
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	31
	db	24
	db	31
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	111
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	0
	db	0
	db	0
	db	0
	db	0
	db	31
	db	24
	db	31
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	108
	db	108
	db	108
	db	108
	db	108
	db	111
	db	96
	db	111
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	0
	db	0
	db	0
	db	0
	db	0
	db	127
	db	96
	db	111
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	111
	db	96
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	127
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	31
	db	24
	db	31
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	31
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-8
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-8
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-1
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-8
	db	24
	db	-8
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	-20
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	-20
	db	12
	db	-4
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-4
	db	12
	db	-20
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	-17
	db	0
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	0
	db	-17
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	-20
	db	12
	db	-20
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	0
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	108
	db	108
	db	108
	db	108
	db	108
	db	-17
	db	0
	db	-17
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-1
	db	0
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	0
	db	-1
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	-4
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-8
	db	24
	db	-8
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-8
	db	24
	db	-8
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-4
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	-1
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	108
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-1
	db	24
	db	-1
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	31
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-8
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	15
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-16
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	54
	db	99
	db	107
	db	107
	db	107
	db	107
	db	54
	db	0
	db	0
	db	0
	db	0
	db	0
	db	48
	db	24
	db	12
	db	0
	db	110
	db	51
	db	51
	db	51
	db	51
	db	51
	db	110
	db	0
	db	0
	db	0
	db	0
	db	0
	db	96
	db	48
	db	24
	db	0
	db	126
	db	3
	db	3
	db	62
	db	3
	db	3
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	96
	db	48
	db	24
	db	0
	db	59
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	102
	db	102
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	112
	db	0
	db	0
	db	0
	db	0
	db	0
	db	96
	db	48
	db	24
	db	0
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	112
	db	0
	db	0
	db	0
	db	0
	db	0
	db	96
	db	48
	db	24
	db	0
	db	62
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	96
	db	48
	db	24
	db	0
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	0
	db	99
	db	99
	db	99
	db	99
	db	99
	db	99
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	96
	db	48
	db	24
	db	0
	db	54
	db	99
	db	107
	db	107
	db	107
	db	107
	db	54
	db	0
	db	0
	db	0
	db	0
	db	6
	db	3
	db	9
	db	28
	db	54
	db	99
	db	99
	db	127
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	6
	db	3
	db	125
	db	76
	db	12
	db	12
	db	124
	db	12
	db	12
	db	12
	db	76
	db	124
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	107
	db	99
	db	99
	db	99
	db	127
	db	99
	db	99
	db	99
	db	99
	db	99
	db	0
	db	0
	db	0
	db	0
	db	6
	db	3
	db	61
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	6
	db	3
	db	61
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	102
	db	60
	db	0
	db	0
	db	0
	db	0
	db	48
	db	24
	db	102
	db	102
	db	102
	db	102
	db	60
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	6
	db	3
	db	61
	db	102
	db	102
	db	102
	db	102
	db	102
	db	60
	db	0
	db	0
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	126
	db	24
	db	24
	db	0
	db	0
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	12
	db	24
	db	48
	db	96
	db	48
	db	24
	db	12
	db	0
	db	126
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	48
	db	24
	db	12
	db	6
	db	12
	db	24
	db	48
	db	0
	db	126
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	28
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	99
	db	99
	db	0
	db	102
	db	102
	db	102
	db	60
	db	24
	db	24
	db	24
	db	24
	db	60
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	0
	db	126
	db	0
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	110
	db	59
	db	0
	db	110
	db	59
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	28
	db	54
	db	54
	db	28
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	24
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-16
	db	48
	db	48
	db	48
	db	48
	db	48
	db	55
	db	54
	db	54
	db	60
	db	56
	db	0
	db	0
	db	0
	db	0
	db	0
	db	27
	db	54
	db	54
	db	54
	db	54
	db	54
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	14
	db	27
	db	12
	db	6
	db	19
	db	31
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	62
	db	62
	db	62
	db	62
	db	62
	db	62
	db	62
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
vgamode_640x480:
	db	-29
	db	3
	db	1
	db	15
	db	0
	db	6
	db	95
	db	79
	db	80
	db	-126
	db	84
	db	-128
	db	11
	db	62
	db	0
	db	64
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	-22
	db	-116
	db	-33
	db	40
	db	0
	db	-25
	db	4
	db	-29
	db	-1
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	5
	db	15
	db	-1
	db	0
	db	1
	db	2
	db	3
	db	4
	db	5
	db	20
	db	7
	db	56
	db	9
	db	58
	db	11
	db	60
	db	13
	db	62
	db	15
	db	1
	db	1
	db	15
	db	3
	db	0
VGAMEM:
	dd	655360
keyb_buffer_ptr:
	db 0,0,0,0
dev_keyb_scan2ascii_HI:
	db	0
	db	-1
	db	33
	db	64
	db	35
	db	36
	db	37
	db	94
	db	38
	db	42
	db	40
	db	41
	db	95
	db	43
	db	8
	db	9
	db	81
	db	87
	db	69
	db	82
	db	84
	db	89
	db	85
	db	73
	db	79
	db	80
	db	123
	db	125
	db	10
	db	0
	db	65
	db	83
	db	68
	db	70
	db	71
	db	72
	db	74
	db	75
	db	76
	db	58
	db	34
	db	126
	db	0
	db	124
	db	90
	db	88
	db	67
	db	86
	db	66
	db	78
	db	77
	db	60
	db	62
	db	63
	db	0
	db	42
	db	0
	db	32
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	1
	db	0
	db	0
	db	0
	db	0
	db	45
	db	0
	db	0
	db	0
	db	43
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
dev_keyb_scan2ascii:
	db	0
	db	27
	db	49
	db	50
	db	51
	db	52
	db	53
	db	54
	db	55
	db	56
	db	57
	db	48
	db	45
	db	61
	db	8
	db	9
	db	113
	db	119
	db	101
	db	114
	db	116
	db	121
	db	117
	db	105
	db	111
	db	112
	db	91
	db	93
	db	10
	db	0
	db	97
	db	115
	db	100
	db	102
	db	103
	db	104
	db	106
	db	107
	db	108
	db	59
	db	39
	db	96
	db	0
	db	92
	db	122
	db	120
	db	99
	db	118
	db	98
	db	110
	db	109
	db	44
	db	46
	db	47
	db	0
	db	42
	db	0
	db	32
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	1
	db	0
	db	0
	db	0
	db	0
	db	45
	db	0
	db	0
	db	0
	db	43
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
	db	0
data_sys_task:
	db 0,0,0,0
sys_task_last:
	db 0,0
mem_keyb_buffer:
	db 0,0,0,0
mem_keyb_pressed:
	db 0,0,0,0
mem_size:
	db 0,0,0,0
data_pdbr:
	db 0,0,0,0
mem_sys:
	db 0,0,0,0
mem_top:
	dd	1048576