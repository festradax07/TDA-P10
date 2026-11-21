		.data
A:	.word	33771
B:	.byte	7
C:	.byte	1
		.code
		lw r1, A(r0)
		lb r2, B(r0)
		lb r3, C(r0)
		dsub r5, r2, r3
		daddi r9, r0, 5
		daddi r10, r0, 6
		halt
	