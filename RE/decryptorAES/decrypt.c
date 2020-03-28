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
int
main(void)
{
    struct aes128 ctx[1];
    const unsigned char key[] = {
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
    };
    const unsigned char pt[] = {
	    0x3a, 0xd7, 0x7b, 0xb4, 0x0d, 0x7a, 0x36, 0x60, 0xa8, 0x9e, 0xca, 0xf3, 0x24, 0x66, 0xef, 0x97
    };
    const unsigned char et[] = {
       0x3a, 0xd7, 0x7b, 0xb4, 0x0d, 0x7a, 0x36, 0x60, 0xa8, 0x9e, 0xca, 0xf3, 0x24, 0x66, 0xef, 0x97
    };
    unsigned char cipherText[AES128_BLOCKLEN] = {0};
    unsigned char decryptedText[AES128_BLOCKLEN] = {0};
    puts("Encrypted Text");
    phex(pt, 16);
    aes128_init(ctx, key);
    aes128_decrypt(ctx, decryptedText, pt);
    puts("Plain Text");
    phex(decryptedText, 16);
}
