all: xor64BitExecer
xor64BitExecer: xor64BitExecer.o io.o
	gcc -o $@ $+ main.c

xor64BitExecer.o: xor64BitExecer.asm 
	nasm -f elf64 xor64BitExecer.asm -o xor64BitExecer.o

io.o: io.asm 
	nasm -f elf64 -d ELF_TYPE io.asm -o io.o

clean:
	rm xor64BitExecer *.o
