%include "io.inc"
DEFAULT REL
;RDI, RSI, RDX, RCX, R8, R9 (R10) XMM0, XMM1, XMM2, XMM3, XMM4, XMM5, XMM6 and XMM7 are used for the first floating point arguments.
segment .data
;format: db "0x%016llX ",10,0
format: db "0x%016llX, ",0
segment .bss 
key: resq 1
a: resq 1000
%define SIZE 60

segment .text
        global  asm_main
        extern printf, srand, rand, time
asm_main:
        enter   0,0               ; setup routine
	;***************CODE STARTS HERE***************************
	mov edi, 0
        call time wrt ..plt
        mov edi, eax
        call srand wrt ..plt
        call rand wrt ..plt
        mov [ key ], rax

        mov rcx, 8
        keygen:
                push rcx
                shl qword [key], 8
                call rand wrt ..plt
                xor [ key ], rax
                pop rcx
        loop keygen
        mov r8, printf
        mov rbx, printer
        mov rdx, a
        mov rcx, 0
        a1:
                mov rax, printer
                mov rax, [rax + rcx]
                mov rbx, a
                mov [rbx + rcx], rax
                add rcx, 8
                cmp rcx, 8 * SIZE
        jle a1
        mov r8, printf
        call printer
        call print_nl
        call print_nl
        mov r9, [key]
        mov r10, a
        mov r12, a + 8*SIZE ; 46
        toper:
                mov r11, [r10 + 8]
                xor [r10], r11 ; xor win next element
                xor [r10], r9 ; add key
                ror r9, 3
                add r10, 8
                cmp r10, r12
                jl toper
        mov [key], r9

         mov r8, printf
        call printer
        call print_nl
        call print_nl
        
        mov r9, [key]
        mov r12, a
        mov r10, a + 8 *SIZE -8
        poper:
                mov r11, [r10 + 8]
                xor [r10], r11 ; xor win next element
                rol r9, 3
                xor [r10], r9 ; add key
                sub r10, 8
                cmp r10, r12
                jge poper
        mov r8, printf
        call printer
        call print_nl
	;***************CODE ENDS HERE*****************************
        mov     eax, 0            ; return back to C
        leave                     
        ret



printer:
	enter 0,0
        sub rsp, 16
        push rax
        mov rax, 7812679038470027312
        mov     QWORD  [rbp-12], rax
        mov     DWORD  [rbp-4], 2108504
	push rcx

	mov rcx, 0
        
yy:	
        push rcx
	push rsi
	push rdi
        push r8

	mov rax, key
	add rax, rcx
	mov rsi, [rax]
	lea rdi , [rbp-12]
        mov eax, 0
        
	call r8

	pop r8
        pop rdi
	pop rsi

	pop rcx
        add rcx, 8
	cmp rcx, 8*SIZE
	jle yy
        pop rax
	
        pop rcx
        add rsp, 8
	leave
	ret