		.data
NUM1:	.float	7.0
NUM2:	.float	1.0
DIRRET:	.word	8240
RES:	.word	0
COPIARA:	.word	0
BANDERAS:	.byte	0
		.code
		lf f1, NUM1(r0)
		lf f2, NUM2(r0)
		ltf f2, f1
		nop
		nop
		nop
		nop
		pushfp
		eqf f1, f2
		nop
		nop
		nop
		nop
		popfp
		bfpt SIGUE
		daddi r5, r0, 1
		jmp FIN
SIGUE:	daddi r5, r0, 7
FIN:	sw r5, RES(r0)
		lw r1, DIRRET(r0)
		pushw r1
		popra
		pushra
		popw r2
		sw r2, COPIARA(r0)
		pushfl
		popb r6
		sb r6, BANDERAS(r0)
		halt
		