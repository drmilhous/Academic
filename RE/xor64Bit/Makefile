all: xor64Bit
xor64Bit: xor64Bit.o io.o
	gcc -fPIE -o $@ $+ main.c

xor64Bit.o: xor64Bit.asm 
	nasm  -f elf64 -d ELF_TYPE xor64Bit.asm -o xor64Bit.o

io.o: io.asm 
	nasm -f elf64 -d ELF_TYPE io.asm -o io.o

clean:
	rm xor64Bit *.o
