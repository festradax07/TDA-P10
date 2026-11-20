		.data
VALOR:	.word	0x12345678
		.code
		lw r1, VALOR(r0)
		pushw r1		; SP 8000h -> 7FFCh, pila: 78 56 34 12
		pushb r1		; SP 7FFCh -> 7FFBh, pila: 78
		popb r2			; r2 = 00000078h, SP -> 7FFCh
		popw r3			; r3 = 12345678h, SP -> 8000h
		dadd r4, r1, r0
		nop
		pushfl			; guarda FLAGS = 00h (resultado distinto de cero), SP -> 7FFFh
		dsub r5, r1, r1
		popfl			; FLAGS pasa de 21h (Z, P) a 00h, SP -> 8000h
		pushw r1		; SP -> 7FFCh
		popra			; RA = 12345678h, SP -> 8000h
		pushra			; apila RA, SP -> 7FFCh
		popw r6			; r6 = 12345678h, SP -> 8000h
		daddi r8, r0, 0x80
		pushb r8		; apila 80h (bit 7 = bandera F), SP -> 7FFFh
		popfp			; FPFLAGS = 80h (F = 1), SP -> 8000h
		pushfp			; apila FPFLAGS, SP -> 7FFFh
		popb r7			; r7 = 00000080h, SP -> 8000h
		bfpf FALLO
		daddi r9, r0, 1
FALLO:	nop
		halt
	