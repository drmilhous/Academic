all: main.exe

aa.obj: aa.asm
	nasm -f win64 aa.asm -o aa.obj
main.exe: main.cpp aa.obj
	x86_64-w64-mingw32-g++-win32 aa.obj main.cpp -o main.exe -lws2_32 
clean:
	rm aa.obj
	rm main.exe
