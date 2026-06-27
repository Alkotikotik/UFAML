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
    
    ;; So this is very clever trick I recently learnt
    ;; Instead of doing offset = some_count % stride(rax % r8), which is very slow 
    ;; I mov r8 into rdx and dec rdx, and then rdx AND rax which gives us rax % r8 
    mov r15, rax
    mov rdx, r8
    dec rdx
    and r15, rdx
    
    ;; Similar thing but opposite 
    mov rbx, rax
    not rdx
    and rbx, rdx
    
    ;;Prepare 
    mov rdx, rbx
    shl rdx, 4
    add rdx, r15
    
    ;;Load real
    vmovapd zmm0,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm1,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm2,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm3,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm4,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm5,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm6,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm7,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm8,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm9,  [r14 + rdx]
    add rdx, r8
    vmovapd zmm10, [r14 + rdx]
    add rdx, r8
    vmovapd zmm11, [r14 + rdx]
    add rdx, r8
    vmovapd zmm12, [r14 + rdx]
    add rdx, r8
    vmovapd zmm13, [r14 + rdx]
    add rdx, r8
    vmovapd zmm14, [r14 + rdx]
    add rdx, r8
    vmovapd zmm15, [r14 + rdx]
    
    ;;Prepare
    mov rdx, rbx
    shl rdx, 4
    add rdx, r15
    
    ;;Load imaginary
    vmovapd zmm16, [r13 + rdx]
    add rdx, r8
    vmovapd zmm17, [r13 + rdx]
    add rdx, r8
    vmovapd zmm18, [r13 + rdx]
    add rdx, r8
    vmovapd zmm19, [r13 + rdx]
    add rdx, r8
    vmovapd zmm20, [r13 + rdx]
    add rdx, r8
    vmovapd zmm21, [r13 + rdx]
    add rdx, r8
    vmovapd zmm22, [r13 + rdx]
    add rdx, r8
    vmovapd zmm23, [r13 + rdx]
    add rdx, r8
    vmovapd zmm24, [r13 + rdx]
    add rdx, r8
    vmovapd zmm25, [r13 + rdx]
    add rdx, r8
    vmovapd zmm26, [r13 + rdx]
    add rdx, r8
    vmovapd zmm27, [r13 + rdx]
    add rdx, r8
    vmovapd zmm28, [r13 + rdx]
    add rdx, r8
    vmovapd zmm29, [r13 + rdx]
    add rdx, r8
    vmovapd zmm30, [r13 + rdx]
    add rdx, r8
    vmovapd zmm31, [r13 + rdx]


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



