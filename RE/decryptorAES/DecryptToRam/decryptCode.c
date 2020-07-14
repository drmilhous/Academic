// https://github.com/skeeto/aes128ni

#include "aes128ni.h"
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <stdint.h>
#include <stdlib.h>

#define MAP_ANONYMOUS 0x20
static void phex(const uint8_t* str, uint8_t len)
{
    unsigned char i;
    for (i = 0; i < len; ++i)
        printf("0x%.2x, ", str[i]);
    printf("\n");
}
int
main(void)
{
    struct aes128 ctx[1];
    const unsigned char key[] = {
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
    };
    
    FILE *file = fopen("data.enc","rb");
    fseek(file, 0L, SEEK_END);
    uint32_t size = ftell(file); // get the len
    fseek(file, 0L, SEEK_SET);
    uint8_t * pt = malloc(size);
    int count = fread(pt,size,1,file);
    while(count != size && !feof(file))
    {
        count += fread(pt+ count, size-count, 1, file);
    }
    fclose(file);
    unsigned char cipherText[AES128_BLOCKLEN] = {0};
    //uint8_t * decryptedText = malloc(size);
    uint8_t *decryptedText = mmap (NULL, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    //mprotect(decryptedText, size, PROT_READ |PROT_WRITE);
    
    puts("Encrypted Text");
    phex(pt, size);
    aes128_init(ctx, key);
    uint8_t  * x = pt;
    uint8_t * y = decryptedText;
    aes128_decrypt(ctx, y, x);
    x += 16;y += 16;
    aes128_decrypt(ctx, y, x);
    x += 16;y += 16;
    aes128_decrypt(ctx, y, x);
    //x += 16;y += 16;
    //aes128_decrypt(ctx, y, x);
 
    printf("Plain Text\n");
    phex(decryptedText, size);
    //mprotect(decryptedText, size, PROT_READ | PROT_EXEC);
    void (*f)(char *, int ) = (void (*)(char *, int)) decryptedText;
    char * space = malloc(100);
    int addr = (int)&printf;
    addr += 0x04;
    f(space, addr);

}

