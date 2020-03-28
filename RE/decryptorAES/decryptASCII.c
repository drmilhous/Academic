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
    unsigned char pt[] = {
	    0x8b, 0x13, 0x96, 0x38, 0xfc, 0x91, 0x77, 0xa7, 0x54, 0x8f, 0x3c, 0x98, 0x05, 0x34, 0x97, 0x49 };
    FILE *file = fopen("data.enc","rb");
    fread(pt,16,1,file);
    fclose(file);
    unsigned char cipherText[AES128_BLOCKLEN] = {0};
    unsigned char decryptedText[AES128_BLOCKLEN] = {0};
    puts("Encrypted Text");
    phex(pt, 16);
    aes128_init(ctx, key);
    aes128_decrypt(ctx, decryptedText, pt);
    puts("Plain Text");
    phex(decryptedText, 16);
    printf("%s\n\n", decryptedText);
}
