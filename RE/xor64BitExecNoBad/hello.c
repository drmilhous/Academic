#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <stdint.h>
#include <stdlib.h>

#define MAP_ANONYMOUS 0x20

#include <stdint.h>

int asm_main( uint8_t *y ) ;


uint64_t  z [] = {
0xEDA954402C715404, 0x793E0E39EBEAE018, 0xFDD835F043BE7176, 0x7FC6CF094359DAD1, 0xB82A272528B55511, 0x81A251377614FC7A, 0x647D70B92DD237F4, 0x28EC5E08214A0621, 0xE94D5B994A18B7FE, 0x059EB9FF3EB840CA, 0x7DE260361C5550A2, 0xBCB7E4BD7A7E278E, 0x123456789ABCDEF1
}
; 

int main()
{
  int size = 1000;
  uint8_t *memory = mmap (NULL, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  int ret_status;
  memcpy(memory,&z,1000);
  ret_status = asm_main(memory);
  return ret_status;
}

