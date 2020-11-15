ORG 100h
use16
        jmp main

__stack_chk_fail: ret
str_len:
label_LFB0:
	push	ebp
	mov	ebp, esp
	sub	esp, 16
	mov	DWORD [ebp-4], 0
	jmp label_L2
label_L3:
	add	DWORD [ebp-4], 1
label_L2:
	mov	eax, DWORD [ebp+8]
	lea	edx, [eax+1]
	mov	DWORD [ebp+8], edx
	movzx	eax, BYTE [eax]
	test	al, al
	jne label_L3
	mov	eax, DWORD [ebp-4]
	mov esp, ebp
	pop ebp
	db 66h
	ret
label_LFE0:
term_put_char:
label_LFB1:
	push	ebp
	mov	ebp, esp
	sub	esp, 4
	mov	eax, DWORD [ebp+8]
	mov	BYTE [ebp-4], al
	movzx	eax, BYTE [ebp-4]
	mov al, al
	mov ah, 0x0E
	mov bl, 0x07
	int 0x10
	mov esp, ebp
	pop ebp
	db 66h
	ret
label_LFE1:
term_waitkey:
label_LFB2:
	push	ebp
	mov	ebp, esp
	xor eax, eax
	int 0x16
	pop	ebp
	db 66h
	ret
label_LFE2:
exit_program:
label_LFB3:
	push	ebp
	mov	ebp, esp
	int 0x20
	pop	ebp
	db 66h
	ret
label_LFE3:
prints:
label_LFB4:
	push	ebp
	mov	ebp, esp
	sub	esp, 20
	mov	eax, DWORD [ebp+8]
	mov	DWORD [ebp-4], eax
	jmp label_L9
label_L10:
	mov	eax, DWORD [ebp-4]
	lea	edx, [eax+1]
	mov	DWORD [ebp-4], edx
	movzx	eax, BYTE [eax]
	movzx	eax, al
	mov	DWORD [esp], eax
	call dword term_put_char
label_L9:
	mov	eax, DWORD [ebp-4]
	movzx	eax, BYTE [eax]
	test	al, al
	jne label_L10
	mov esp, ebp
	pop ebp
	db 66h
	ret
label_LFE4:
printi:
label_LFB5:
	push	ebp
	mov	ebp, esp
	push	ebx
	sub	esp, 292
	mov	eax, DWORD [gs:20]
	mov	DWORD [ebp-12], eax
	xor	eax, eax
	mov	DWORD [ebp-276], 0
	cmp	DWORD [ebp+8], 0
	jns label_L12
	neg	DWORD [ebp+8]
	mov	DWORD [esp], 45
	call dword term_put_char
	jmp label_L13
label_L12:
	jmp label_L13
label_L14:
	mov	ebx, DWORD [ebp-276]
	lea	eax, [ebx+1]
	mov	DWORD [ebp-276], eax
	mov	ecx, DWORD [ebp+8]
	mov	edx, 1717986919
	mov	eax, ecx
	imul	edx
	sar	edx, 2
	mov	eax, ecx
	sar	eax, 31
	sub	edx, eax
	mov	eax, edx
	sal	eax, 2
	add	eax, edx
	add	eax, eax
	sub	ecx, eax
	mov	edx, ecx
	mov	eax, edx
	mov	BYTE [ebp-268+ebx], al
	mov	ecx, DWORD [ebp+8]
	mov	edx, 1717986919
	mov	eax, ecx
	imul	edx
	sar	edx, 2
	mov	eax, ecx
	sar	eax, 31
	sub	edx, eax
	mov	eax, edx
	mov	DWORD [ebp+8], eax
label_L13:
	cmp	DWORD [ebp+8], 0
	jne label_L14
	mov	eax, DWORD [ebp-276]
	sub	eax, 1
	mov	DWORD [ebp-272], eax
	jmp label_L15
label_L16:
	lea	edx, [ebp-268]
	mov	eax, DWORD [ebp-272]
	add	eax, edx
	movzx	eax, BYTE [eax]
	add	eax, 48
	movzx	eax, al
	mov	DWORD [esp], eax
	call dword term_put_char
	sub	DWORD [ebp-272], 1
label_L15:
	cmp	DWORD [ebp-272], 0
	jns label_L16
	mov	eax, DWORD [ebp-12]
	xor	eax, DWORD [gs:20]
	je label_L17
	call dword __stack_chk_fail
label_L17:
	add	esp, 292
	pop	ebx
	pop	ebp
	db 66h
	ret
label_LFE5:
print_float:
label_LFB6:
	push	ebp
	mov	ebp, esp
	sub	esp, 40
	mov	DWORD [ebp-12], 16
	fldz
	fld	DWORD [ebp+8]
	fxch	st1
	fucomip	st, st1
	fstp	st0
	jbe label_L19
	fld	DWORD [ebp+8]
	fchs
	fstp	DWORD [ebp+8]
	mov	DWORD [esp], 45
	call dword term_put_char
label_L19:
	fld	DWORD [ebp+8]
	fnstcw	WORD [ebp-26]
	movzx	eax, WORD [ebp-26]
	mov	ah, 12
	mov	WORD [ebp-28], ax
	fldcw	WORD [ebp-28]
	fistp	DWORD [ebp-32]
	fldcw	WORD [ebp-26]
	mov	eax, DWORD [ebp-32]
	mov	DWORD [esp], eax
	call dword printi
	mov	DWORD [esp], 46
	call dword term_put_char
	fld	DWORD [ebp+8]
	fnstcw	WORD [ebp-26]
	movzx	eax, WORD [ebp-26]
	mov	ah, 12
	mov	WORD [ebp-28], ax
	fldcw	WORD [ebp-28]
	fistp	DWORD [ebp-32]
	fldcw	WORD [ebp-26]
	mov	eax, DWORD [ebp-32]
	mov	DWORD [ebp-32], eax
	fild	DWORD [ebp-32]
	fld	DWORD [ebp+8]
	fsubrp	st1, st
	fstp	DWORD [ebp+8]
	jmp label_L21
label_L27:
	fld	DWORD [ebp+8]
	fld DWORD [label_LC1]
	fmulp	st1, st
	fstp	DWORD [ebp+8]
	jmp label_L22
label_L23:
	fld	DWORD [ebp+8]
	fld DWORD [label_LC1]
	fsubp	st1, st
	fstp	DWORD [ebp+8]
label_L22:
	fld	DWORD [ebp+8]
	fld DWORD [label_LC1]
	fxch	st1
	fucomip	st, st1
	fstp	st0
	jae label_L23
	fld	DWORD [ebp+8]
	fldz
	fxch	st1
	fucomip	st, st1
	fstp	st0
	jbe label_L21
	fld	DWORD [ebp+8]
	fnstcw	WORD [ebp-26]
	movzx	eax, WORD [ebp-26]
	mov	ah, 12
	mov	WORD [ebp-28], ax
	fldcw	WORD [ebp-28]
	fistp	DWORD [ebp-32]
	fldcw	WORD [ebp-26]
	mov	eax, DWORD [ebp-32]
	add	eax, 48
	movzx	eax, al
	mov	DWORD [esp], eax
	call dword term_put_char
label_L21:
	fld	DWORD [ebp+8]
	fldz
	fxch	st1
	fucomip	st, st1
	fstp	st0
	jbe label_L31
	mov	eax, DWORD [ebp-12]
	lea	edx, [eax-1]
	mov	DWORD [ebp-12], edx
	test	eax, eax
	jne label_L27
label_L31:
	mov esp, ebp
	pop ebp
	db 66h
	ret
label_LFE6:
sprint:
label_LFB7:
	push	ebp
	mov	ebp, esp
	sub	esp, 40
	mov	DWORD [ebp-16], 0
	jmp label_L33
label_L36:
	mov	eax, DWORD [ebp+8]
	movzx	eax, BYTE [eax]
	cmp	al, 37
	jne label_L34
	mov	eax, DWORD [ebp+8]
	add	eax, 1
	movzx	eax, BYTE [eax]
	cmp	al, 100
	jne label_L34
	mov	eax, DWORD [ebp-16]
	mov ebx, eax
	mov eax, dword [ebp + ebx + 12]
	mov	DWORD [ebp-12], eax
	mov	eax, DWORD [ebp-12]
	mov	DWORD [esp], eax
	call dword printi
	add	DWORD [ebp+8], 2
	add	DWORD [ebp-16], 4
label_L34:
	mov	eax, DWORD [ebp+8]
	movzx	eax, BYTE [eax]
	cmp	al, 37
	jne label_L35
	mov	eax, DWORD [ebp+8]
	add	eax, 1
	movzx	eax, BYTE [eax]
	cmp	al, 102
	jne label_L35
	mov	eax, DWORD [ebp-16]
	mov ebx, eax
	fld qword [ebp + ebx + 12]
	fstp DWORD [ebp-20]
	mov	eax, DWORD [ebp-20]
	mov	DWORD [esp], eax
	call dword print_float
	add	DWORD [ebp+8], 2
	add	DWORD [ebp-16], 8
	jmp label_L33
label_L35:
	mov	eax, DWORD [ebp+8]
	movzx	eax, BYTE [eax]
	movzx	eax, al
	mov	DWORD [esp], eax
	call dword term_put_char
	add	DWORD [ebp+8], 1
label_L33:
	mov	eax, DWORD [ebp+8]
	movzx	eax, BYTE [eax]
	test	al, al
	jne label_L36
	mov esp, ebp
	pop ebp
	db 66h
	ret
label_LFE7:
label_LC3:
	db "", 0x0A, "test", 0x0A, "", 0
label_LC6:
	db "wow %d!!! and %f", 0x0A, "", 0
main:
label_LFB8:
	push	ebp
	mov	ebp, esp
	and	esp, -16
	sub	esp, 32
	mov	DWORD [esp+20], label_LC3
	mov	DWORD [esp+24], 5001
	mov	eax, DWORD [label_LC4]
	mov	DWORD [esp+28], eax
	fld QWORD [label_LC5]
	fstp	QWORD [esp+8]
	mov	DWORD [esp+4], 511
	mov	DWORD [esp], label_LC6
	call dword sprint
	call dword term_waitkey
	call dword exit_program
	mov esp, ebp
	pop ebp
	db 66h
	ret
label_LFE8:
	align 4
label_LC1:
	dd 1092616192
	align 4
label_LC4:
	dd 1084647014
	align 8
label_LC5:
	dd 0
	dd 1071644672
