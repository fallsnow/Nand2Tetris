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
	@R2
	M=0
	@DRAW
	D,JEQ
	@R2
	M=-1
	@DRAW
	0,JMP
	@KEY_POLLING
	0,JMP

(DRAW)
	@SCREEN
	D=A
	@8191
	D=D+A
	@R0
	M=D
(DRAW_LOOP)
	@R0
	D=M		// D�ɃJ�E���^�l�����[�h
	@SCREEN
	D=D-A		// D = �J�E���^�l - @SCREEN(16384)
	@DRAW_END
	D,JLT		// D < 0 �Ȃ烋�[�v�𔲂���
	
	@R2		// �s�N�Z���ɏ������ރf�[�^��R2����ǂݍ���
	D=M

	@R0
	A=M
	//M=-1		// �J�E���^�l�̃A�h���X�������h��
	M=D
	AD=A-1		// �J�E���^--
	@R0
	M=D
	@DRAW_LOOP
	0,JMP
(DRAW_END)
	@KEY_POLLING
	0,JMP
