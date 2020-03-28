%include "io.inc"
DEFAULT REL
;RDI, RSI, RDX, RCX, R8, R9 (R10) XMM0, XMM1, XMM2, XMM3, XMM4, XMM5, XMM6 and XMM7 are used for the first floating point arguments.
segment .data
;format: db "0x%016llX ",10,0
format: db "0x%016llX, ",0
bad: db 0x0A, 0x00
segment .bss 

;key: resq 1
;a: resq 1000
b: resq 1
%define SIZE 11

segment .text
        global  asm_main
        extern printf, srand, rand, time
asm_main:
        enter   0,0               ; setup routine
	;***************CODE STARTS HERE***************************
	mov [b], rdi

        mov r15, [b]
        mov r15, [r15]
        mov r14, [b]
        add r14, 8
        mov r12, r14
        mov r10, r14
        add r10, 8 *SIZE -8
        poper:
                mov r11, [r10 + 8]
                xor [r10], r11 ; xor win next element
                rol r15, 3
                xor [r10], r15 ; add key
                sub r10, 8
                cmp r10, r12
                jge poper

        mov r8, printf
        mov r9, [b]
        mov rsi, [b]; load our function
        add r9, 8; remove the key
        call r9
        ;call printer
        call print_nl
	;***************CODE ENDS HERE*****************************
        mov     eax, 0            ; return back to C
        leave                     
        ret
