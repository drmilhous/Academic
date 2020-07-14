%include "asm_io.inc"
segment .data
key dd 0x8970089
a dd 0x01020304, 0xAABBCCDD, 0xBB11CC22, 0x98765432, 0xBEEF1010
end: dd 0xF00DB00F

format: db "0x%08X ",10,0
segment .bss 

segment .text
        global  asm_main
		extern printf, time, rand, srand
asm_main:
        enter   0,0               ; setup routine
        pusha
	;***************CODE STARTS HERE***************************
	call printer
	call print_nl
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;obfuscation
	push 0
	call time
	mov [esp], eax
	call srand
	call rand
	mov [key], eax
	add esp, 4


    mov edx, [key]
	mov eax, a
toper:
	;mov ebx, [eax]
	mov ecx, [eax + 4]
	xor [eax], ecx
    xor [eax], edx
    ror edx, 3
	add eax, 4
	cmp eax, end
	jl toper
    mov [key], edx
	call printer
	call print_nl
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Deobfuscation
	mov edi, 16
    mov edx, [key]
boper:  
        
    mov eax, a
	add eax, edi
	mov ebx, [eax]
	mov ecx, [eax + 4]
	xor ecx, ebx
        rol edx, 3
        xor ecx, edx
	mov [eax], ecx
	sub edi, 4
	cmp edi, 0
	jge boper


	call printer
	;***************CODE ENDS HERE*****************************
        popa
        mov     eax, 0            ; return back to C
        leave                     
        ret
printer:
	enter 0,0
	push ecx
	mov ecx, 0

yy:	pushad
	mov eax, key
	add eax, ecx
	mov eax, [eax]
	push eax
	push format
	call printf
	add esp, 4*2
	popad
	add ecx, 4
	cmp ecx, 28
	jle yy

	pop ecx
	leave
	ret
