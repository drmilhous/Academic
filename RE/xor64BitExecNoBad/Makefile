all: xor64BitExecNoBad decode

decode: decode.o io.o
	gcc -o $@ $+ hello.c

decode.o: decode.asm 
	nasm -f elf64 decode.asm -o decode.o

xor64BitExecNoBad: xor64BitExecNoBad.o io.o
	gcc -o $@ $+ main.c

xor64BitExecNoBad.o: xor64BitExecNoBad.asm 
	nasm -f elf64 xor64BitExecNoBad.asm -o xor64BitExecNoBad.o

io.o: io.asm 
	nasm -f elf64 -d ELF_TYPE io.asm -o io.o

clean:
	rm xor64BitExecNoBad *.o
