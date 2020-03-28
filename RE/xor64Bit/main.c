#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <stdint.h>
#include <stdlib.h>

#define MAP_ANONYMOUS 0x20

#include <stdint.h>

int asm_main( uint8_t *y ) ;


uint64_t  z [] = {
 0x10C3C7E77F20ED9E, 0xB75773FBD2E6788B, 0xD9ABF143B8623F5C, 0xB3741B56C38228FD, 0x9ECFEAEFCFCD2A64, 0x79B34C53A68CCBCF, 0xCC86BE6665A6F82B, 0x5F938B1E40A1971A, 0x9DA4DB315C36656B, 0x981E80C646412AF2, 0x76CFC061E333BF90, 0x4688685D6E6C3FFD, 0x70CE8D546A915F77, 0x4E82D3488FB96AFC, 0xCFA57642DF472B6E, 0x0EB93A8C1ECCD6DB, 0xA73E2BB3954E283F
  }; 

int main()
{
  int size = 1000;
  uint8_t *memory = mmap (NULL, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  int ret_status;
  ret_status = asm_main(memory);
  return ret_status;
}

