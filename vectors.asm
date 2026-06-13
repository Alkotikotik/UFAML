%macro PUSH_R 0 
    push r12
    push r13
    push r14
    push r15
%endmacro
section .text


global dot_product 

;;According to some convention argv = [rdi, rsi, rdx, rcx, r8, r9] then on stack through xmm0-xmm7

dot_product:
    PUSH_R
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

    prefetcht0 [r14 + rax + 512]
    prefetcht0 [r13 + rax + 512]
    prefetcht0 [r12 + rax + 512]
    prefetcht0 [r11 + rax + 512]
    prefetcht0 [r10 + rax + 512]
    prefetcht0 [r9 + rax + 512]

    ;;vecA X
    vmovaps zmm0, [r14 + rax]
    vmovaps zmm1, [r14 + rax + 64]
    vmovaps zmm2, [r14 + rax + 128]
    vmovaps zmm3, [r14 + rax + 192]
    
    ;VecA Y
    vmovaps zmm4, [r13 + rax]
    vmovaps zmm5, [r13 + rax + 64]
    vmovaps zmm6, [r13 + rax + 128]
    vmovaps zmm7, [r13 + rax + 192]

    ;VecA Z
    vmovaps zmm8, [r12 + rax]
    vmovaps zmm9, [r12 + rax + 64]
    vmovaps zmm10, [r12 + rax + 128]
    vmovaps zmm11, [r12 + rax + 192]
   
    ;;vecB X
    vmovaps zmm12, [r11 + rax]
    vmovaps zmm13, [r11 + rax + 64]
    vmovaps zmm14, [r11 + rax + 128]
    vmovaps zmm15, [r11 + rax + 192]
    
    ;VecB Y
    vmovaps zmm16, [r10 + rax]
    vmovaps zmm17, [r10 + rax + 64]
    vmovaps zmm18, [r10 + rax + 128]
    vmovaps zmm19, [r10 + rax + 192]

    ;VecB Z
    vmovaps zmm20, [r9 + rax]
    vmovaps zmm21, [r9 + rax + 64]
    vmovaps zmm22, [r9 + rax + 128]
    vmovaps zmm23, [r9 + rax + 192]
    
    ;a_x * b_x
    vmulps zmm0, zmm0, zmm12
    vmulps zmm1, zmm1, zmm13
    vmulps zmm2, zmm2, zmm14
    vmulps zmm3, zmm3, zmm15

    vfmadd231ps zmm0, zmm4, zmm16
    vfmadd231ps zmm1, zmm5, zmm17
    vfmadd231ps zmm2, zmm6, zmm18
    vfmadd231ps zmm3, zmm7, zmm19

    vfmadd231ps zmm0, zmm8, zmm20
    vfmadd231ps zmm1, zmm9, zmm21
    vfmadd231ps zmm2, zmm10, zmm22
    vfmadd231ps zmm3, zmm11, zmm23

    vmovntps [rcx + rax], zmm0 
    vmovntps [rcx + rax + 64], zmm1
    vmovntps [rcx + rax + 128], zmm2
    vmovntps [rcx + rax + 192], zmm3

    add rax, 256
    cmp rax, rdx
    jl .loop

.exit:
    pop r15
    pop r14
    pop r13
    pop r12
    
    sfence
    ret

