// https://github.com/skeeto/aes128ni

#include "aes128ni.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>


static void phex(const uint8_t* str, uint8_t len)
{
    unsigned char i;
    for (i = 0; i < len; ++i)
        printf("0x%.2x, ", str[i]);
    printf("\n");
}
int main(void)
{
    struct aes128 ctx[1];
    const unsigned char key[] = {
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
    };
    const unsigned char pt[] = {
        0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a 
    };
    unsigned char cipherText[AES128_BLOCKLEN] = {0};
    puts("Plain Text");
    phex(pt, 16);
    aes128_init(ctx, key);
    aes128_encrypt(ctx, cipherText, pt);
    puts("Encrypted Text");
    phex(cipherText, 16);

}
