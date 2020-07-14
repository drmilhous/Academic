#include <stdio.h>
#include <string.h>
#include <stdint.h>

// Enable ECB, CTR and CBC mode. Note this can be done before including aes.h or at compile-time.
// E.g. with GCC by using the -D flag: gcc -c aes.c -DCBC=0 -DCTR=1 -DECB=1
#define CBC 1
#define CTR 1
#define ECB 1

#include "aes.h"
static void phex(uint8_t* str, int len);
int main(void)
{
	
	//256
    uint8_t key[] = { 0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe, 0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81,
                      0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7, 0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4 };
    uint8_t in[]  = { 0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a};
    uint8_t out[16];
	
	for(int i = 0; i < 16; i++)
	{
		out[i] = in[i];
	}
	phex(out,16);
	
    struct AES_ctx ctx;
    AES_init_ctx(&ctx, key);
    AES_ECB_encrypt(&ctx, in);
	phex(in,16);
	AES_init_ctx(&ctx, key);
	AES_ECB_decrypt(&ctx, in);
	phex(out,16);


    return 0;
}


// prints string as hex
static void phex(uint8_t* str, int len)
{
    for (int i = 0; i < len; ++i)
        printf("%.2x", str[i]);
    printf("\n");
}

