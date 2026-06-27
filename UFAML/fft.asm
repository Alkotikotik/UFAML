section .text 

global fft 
fft: 
;rdi = *src real, [rdi+8] = imag
;rsi = *dst real, [rsi+8] = imag
;rdx = *twiddles real, [rdi+8] = imag
;rcx = N(of samples)
;r8 = curret stride

    push r12
    push r13
    push r14
    push r15
    push rbx

    shl r8, 3 ;for loop enrolling
    shl rcx, 3

    mov r14, [rdi]
    mov r13, [rdi + 8]
    mov r12, [rsi]
    mov r11, [rsi + 8]
    mov r10, [rdx]
    mov r9, [rdx + 8]

    xor rax, rax
.loop:
    prefetcht1 [r14 + rax + 512]
    prefetcht1 [r13 + rax + 512]
    
    ;;real
    vmovaps zmm0, [r14 + rax]
    vmovaps zmm1, [r14 + rax + 64]
    vmovaps zmm2, [r14 + rax + 128]
    vmovaps zmm3, [r14 + rax + 192]
    
    ;imag
    vmovaps zmm4, [r13 + rax]
    vmovaps zmm5, [r13 + rax + 64]
    vmovaps zmm6, [r13 + rax + 128]
    vmovaps zmm7, [r13 + rax + 192]


    add rax, 256
    cmp rax, r8
    jl .loop

.exit:
    sfence
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret



