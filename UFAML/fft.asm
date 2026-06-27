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
    
    ;;Multiplication by 8
    shl r8, 3
    shl rcx, 3
    
    ;;scr
    mov r14, [rdi]
    mov r13, [rdi + 8]
    ;;dst
    mov r12, [rsi]
    mov r11, [rsi + 8]
    ;;Twiddles
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
    ;;So r15 = element offset within current block
    
    ;; Similar thing but opposite 
    mov rbx, rax
    not rdx
    and rbx, rdx
    ;;And rbx = base pointer of current block
    
    ;;TODO main calculation

    add rax, 64
    cmp rax, rcx
    jl .loop

.exit:
    sfence
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret



