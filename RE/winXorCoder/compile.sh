nasm -f win64 aa.asm -o aa.obj
x86_64-w64-mingw32-g++-win32 aa.obj main.cpp -o mainxx.exe -lws2_32 
