section .text

global bar
extern main

bar:
    mov rbx, 0
    mov ecx, 64
    mov rax, done
   a:
    mov rdx, rax
    and rdx, 1
    or rbx, rdx
    ror rax, 1
    ror rbx, 1
    loop a
    cmp rax, rbx
    jne o
    jmp rbx
    o: mov rbx, garbage
    add rbx, 0x2a2
    jmp rbx
    dd 0xEEFFAABB
   

done:
    
    mov rax, main
    add rax, 4Fh
    jmp rax

garbage:
    dd 0xCAFE0011
