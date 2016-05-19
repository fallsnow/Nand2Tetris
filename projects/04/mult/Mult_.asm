// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)

// Put your code here.

	@R2
	M=0	// Initizalize RAM[2] to zero
(LOOP)
	@R0
	D=M	// D=RAM[0]
	@R2
	M=D+M	// RAM[2] += RAM[0]
	@R1
	M=M-1	// RAM[1]--
	D=M	// Move counter value to D register
	@LOOP
	D;JGT	// Goto LOOP
(END)
	@END
	0;JMP	// Infinite loop