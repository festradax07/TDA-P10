		.data
NUM1:	.float	7.0
NUM2:	.float	1.0
RES:	.word	0
		.code
		lf f1, NUM1(r0)
		lf f2, NUM2(r0)
		ltf f2, f1
		nop
		nop
		nop
		nop
		pushfp
		popfp
		eqf f1, f2
		nop
		nop
		nop
		nop
		bfpt MAL
		daddi r5, r0, 7
		jmp FIN
MAL:	daddi r5, r0, 1
FIN:	sw r5, RES(r0)
		halt
		
