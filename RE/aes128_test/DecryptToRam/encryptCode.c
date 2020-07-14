// https://github.com/skeeto/aes128ni

#include "aes128ni.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>

const unsigned char key[] = {
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
    };

    uint8_t * pt;

static void printHex(const uint8_t* str, uint8_t len);
int main(int argc, char ** argv)
{
    struct aes128 ctx[1];
    
    FILE  *file = fopen(argv[1],"rb");

    fseek(file, 0L, SEEK_END);
    uint32_t size = ftell(file); // get the len
    fseek(file, 0L, SEEK_SET);
    uint8_t actual = size;
    if(size % 16 != 0)
    {
        size = (size / 16 + 1) * 16;
    }
    printf("Size %d\n", size);

    pt = malloc(size);

    
    int count = fread(pt,actual,1,file);
    printf(" count %d\n", count );
    while(count != actual && !feof(file))
    {
        count += fread(pt+ count, actual-count, 1, file);
         printf(" count %d\n", count );
    }
    fclose(file);

    uint8_t * cipherText = malloc(size);
    puts("Plain Text");
    printHex(pt, size);
    aes128_init(ctx, key);
    uint8_t * x = pt;
    uint8_t * y = cipherText;
    aes128_encrypt(ctx, y, x);
    x += 16; y+= 16;
    aes128_encrypt(ctx, y, x);
    x += 16; y+= 16;
    aes128_encrypt(ctx, y, x);
    //x += 16; y+= 16;
    //aes128_encrypt(ctx, y, x);
    puts("Encrypted Text");
    printHex(cipherText, size);
    file = fopen("data.enc","wb");
    fwrite(cipherText,1,size,file);
    fclose(file);

}
static void printHex(const uint8_t* str, uint8_t len)
{
    unsigned char i;
    for (i = 0; i < len; ++i)
        printf("0x%.2x, ", str[i]);
    printf("\n");
}