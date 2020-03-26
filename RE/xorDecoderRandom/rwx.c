 #include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <stdint.h>
#include <stdlib.h>
#define MAP_ANONYMOUS 0x20
int main(void)
{
    int size = 1000;
    uint8_t *decryptedText = mmap (NULL, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if(decryptedText != NULL)
    {
        decryptedText[0] = 0x55;
        decryptedText[1] = 0xc9;
        decryptedText[2] = 0xc3;
        void (*f)() = (void (*)()) decryptedText;
        f();
    }
    else 
    {
        printf("Alocate Null");
    }
}