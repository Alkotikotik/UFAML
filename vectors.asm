%macro PUSH_R 0 
    push r12
    push r13
    push r14
    push r15
%endmacro
section .text

%macro PROCCESS_DOT_PRODUCT 1
    mov r14, [rdi + %1] ; vecA X/Y/Z base pointer depending on %1
    mov r13, [rsi + %1] ; vecB

    xor rax, rax 
    xor r15, r15
%%loop
    cmp r15, rsi
    jge %%exit

    ;;vecA
    vmovaps zmm0, [r14 + rax]
    vmovaps zmm1, [r14 + rax + 64]
    vmovaps zmm2, [r14 + rax + 128]
    vmovaps zmm3, [r14 + rax + 192]
    
    ;;vecB
    vmovaps zmm4, [r13 + rax]
    vmovaps zmm5, [r13 + rax + 64]
    vmovaps zmm6, [r13 + rax + 128]
    vmovaps zmm7, [r13 + rax + 192]
    
    vmulps zmm8, 

    add r15, 64
    add rax, 256
    jmp %%loop

%%exit:
%endmacro

global dot_product 

;;According to some convention argv = [rdi, rsi, rdx, rcx, r8, r9] then on stack through xmm0-xmm7

dot_product:
    PUSH_R
;rdi = vecA base pointer
;rsi = vecB base pointer
;rdx = counter
;xmm0 = result
