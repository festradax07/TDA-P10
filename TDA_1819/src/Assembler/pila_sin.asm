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
		daddi r8, r0, 2
		dsub r5, r2, r3
		pushh r1
		lh r7, LEGAJO(r8)
		pushh r7
		pushh r2
		dmul r1, r1, r2
		sw r1, PROD(r0)
		dsub r2, r2, r2
		poph r2
		poph r7
		poph r1
		sh r1, COPIA(r0)
		sh r7, COPIA(r8)
		lw r1, COPIA(r0)
		dsub r5, r2, r3
		halt
	