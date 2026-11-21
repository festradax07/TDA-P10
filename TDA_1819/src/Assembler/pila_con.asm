		.data
LEGAJO:	.word	33771
MAYOR:	.byte	7
MENOR:	.byte	1
PROD:	.word	0
COPIA:	.word	0
		.code
		lb r2, MAYOR(r0)
		lb r3, MENOR(r0)
		lw r1, LEGAJO(r0)
		dsub r5, r2, r3
		pushw r1
		pushb r2
		pushfl
		dmul r1, r1, r2
		sw r1, PROD(r0)
		dsub r2, r2, r2
		popfl
		popb r2
		popw r1
		sw r1, COPIA(r0)
		halt
	