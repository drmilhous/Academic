all: xor64BitExec
xor64BitExec: xor64BitExec.o asm_io.o
	gcc -m32 -o $@ $+ driver.c

xor64BitExec.o: xor64BitExec.asm 
	nasm -f elf xor64BitExec.asm -o xor64BitExec.o

asm_io.o: asm_io.asm 
	nasm -f elf -d ELF_TYPE asm_io.asm -o asm_io.o

clean:
	rm xor64BitExec *.o
