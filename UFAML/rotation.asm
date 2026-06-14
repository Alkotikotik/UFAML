%macro PUSH_Rs 0 
    push r12
    push r13
    push r14
    push r15
%endmacro
section .text


global dot_product 

;;According to some convention argv = [rdi, rsi, rdx, rcx, r8, r9] then on stack through xmm0-xmm7

dot_product:
    PUSH_Rs
;rdi = vecA base pointer
;rsi = vecB base pointer
;rdx = counter
;rcx = result base pointer
    shl rdx, 2 ;Multiply count by 4 

    mov r14, [rdi] ; vecA X 
    mov r13, [rdi + 8] ;vecA Y 
    mov r12, [rdi + 16] ;vecA Z

    mov r11, [rsi] ; vecB X
    mov r10, [rsi + 8] ; vecB Y
    mov r9, [rsi + 16] ; vecB Z


    xor rax, rax 
.loop:
