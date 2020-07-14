all: xorDeconderRandom
xorDeconderRandom: xorDeconderRandom.o asm_io.o
	gcc -Xlinker -N -m32 -o $@ $+ $(HOME)/templateMake/driver.c

xorDeconderRandom.o: xorDeconderRandom.asm 
	nasm -f elf xorDeconderRandom.asm -o xorDeconderRandom.o

asm_io.o: $(HOME)/templateMake/asm_io.asm 
	nasm -f elf -d ELF_TYPE $(HOME)/templateMake/asm_io.asm -o asm_io.o

clean:
	rm xorDeconderRandom *.o
