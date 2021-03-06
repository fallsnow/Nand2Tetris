// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input. 
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel. When no key is pressed, the
// program clears the screen, i.e. writes "white" in every pixel.

// Put your code here.

(KEY_POLLING)
	@KBD
	D=M
	@FILL
	D,JNE
	@UNFILL
	0,JMP
	@KEY_POLLING
	0,JMP

(FILL)
	@SCREEN
	D=A
	@8191
	D=D+A
	@R0
	M=D
(FILL_LOOP)
	@R0
	D=M		// Dにカウンタ値をロード
	@SCREEN
	D=D-A		// D = カウンタ値 - @SCREEN(16384)
	@FILL_END
	D,JLT		// D < 0 ならループを抜ける
	@R0
	A=M
	M=-1		// カウンタ値のアドレスを黒く塗る
	AD=A-1		// カウンタ--
	@R0
	M=D
	@FILL_LOOP
	0,JMP
(FILL_END)
	@KEY_POLLING
	0,JMP

(UNFILL)
	@SCREEN
	D=A
	@8191
	D=D+A
	@R0
	M=D
(UNFILL_LOOP)
	@R0
	D=M		// Dにカウンタ値をロード
	@SCREEN
	D=D-A		// D = カウンタ値 - @SCREEN(16384)
	@UNFILL_END
	D,JLT		// D < 0 ならループを抜ける
	@R0
	A=M
	M=0		// カウンタ値のアドレスを白く塗る
	AD=A-1		// カウンタ--
	@R0
	M=D
	@UNFILL_LOOP
	0,JMP
(UNFILL_END)
	@KEY_POLLING
	0,JMP