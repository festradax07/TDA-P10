		.data
A:	.word	-5
		.code
		lw r12, A(r0)
		daddi r9, r0, 3
		pushw r12
		pushfl
		dsub r9, r9, r9
		popfl
		daddi r10, r0, 1
		popw r15
		pushb r12
		popb r14
		halt
	