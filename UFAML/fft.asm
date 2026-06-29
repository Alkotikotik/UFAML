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
    push rbp
    
    ; 1. Calculate loop limit: rcx = (N / 16) * 8
    shr rcx, 4
    shl rcx, 3
    
    ;Scale stride to bytes
    shl r8, 3
    
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
    xor rbx, rbx 
    xor r15, r15

; rax = current counter
; rbx = base pointer of src
; r15 = offset within block
; r8  = stride

.loop:
    prefetcht1 [r14 + rbx + r15 + 512]
    prefetcht1 [r14 + rbx + r15 + r8 + 512]
    prefetcht1 [r14 + rbx + r15 + 2 * r8 + 512]

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

    shl rbx, 4
    
    ;;Set up offsets for loading 
    lea rdi, [r14 + rbx + r15]   ; rdi = base real pointer
    lea rsi, [r13 + rbx + r15]   ; rsi = base imag pointer
    lea rdx, [r8 + 2 * r8]       ; rdx = 3 * r8 scale offset
    
    ;; Load them by chunks of 4 and immidiately add twiddles 
    
    ; --Load 0-3
    vmovapd zmm0,  [rdi]
    vmovapd zmm16, [rsi]

    vmovapd zmm1,  [rdi + r8]
    vmovapd zmm17, [rsi + r8]

    vmovapd zmm2,  [rdi + 2 * r8]
    vmovapd zmm18, [rsi + 2 * r8]

    vmovapd zmm3,  [rdi + rdx]
    vmovapd zmm19, [rsi + rdx]

    ; Real new = R * T_R - I * T_I
    ; Imag new = I * T_R + R * T_I

    vmovapd zmm15, [r10 + rbp] ;dw its empty atm
    vmulpd zmm15, zmm15, zmm1
    ;;This is negative add so -(2*3) + 1
    vfnmadd231pd zmm15, zmm17, [r9 + rbp]

    vmulpd zmm17, zmm17, [r10+rbp]
    vfmadd231pd zmm17, zmm1, [r9 + rbp]
    vmovapd zmm1, zmm15

    vmovapd zmm15, [r10 + rbp + 64]
    vmulpd zmm15, zmm15, zmm2
    vfnmadd231pd zmm15, zmm18, [r9 + rbp + 64]

    vmulpd zmm18, zmm18, [r10 + rbp + 64]
    vfmadd231pd zmm18, zmm2, [r9 + rbp + 64]
    vmovapd zmm2, zmm15

    vmovapd zmm15, [r10 + rbp + 128]
    vmulpd zmm15, zmm15, zmm3
    vfnmadd231pd zmm15, zmm19, [r9 + rbp + 128]

    vmulpd zmm19, zmm19, [r10 + rbp + 128]
    vfmadd231pd zmm19, zmm3, [r9 + rbp + 128]
    vmovapd zmm3, zmm15
    
    ; --Advance pointers--
    ; Its fine bc it works in parralel since lea is AGU 
    lea rdi, [rdi + 4 * r8]
    lea rsi, [rsi + 4 * r8]
    
    ; --Load 4-7--
    vmovapd zmm4,  [rdi]
    vmovapd zmm20, [rsi]

    vmovapd zmm5,  [rdi + r8]
    vmovapd zmm21, [rsi + r8]

    vmovapd zmm6,  [rdi + 2 * r8]
    vmovapd zmm22, [rsi + 2 * r8]

    vmovapd zmm7,  [rdi + rdx]
    vmovapd zmm23, [rsi + rdx]

    vmovapd zmm15, [r10 + rbp + 192] ;Why bother with pointers inc and stuff..?
    vmulpd zmm15, zmm15, zmm4
    vfnmadd231pd zmm15, zmm20, [r9 + rbp + 192]

    vmulpd zmm20, zmm20, [r10 + rbp + 192]
    vfmadd231pd zmm20, zmm4, [r9 + rbp + 192]
    vmovapd zmm4, zmm15

    vmovapd zmm15, [r10 + rbp + 256]
    vmulpd zmm15, zmm15, zmm5
    vfnmadd231pd zmm15, zmm21, [r9 + rbp + 256]

    vmulpd zmm21, zmm21, [r10 + rbp + 256]
    vfmadd231pd zmm21, zmm5, [r9 + rbp + 256]
    vmovapd zmm5, zmm15

    vmovapd zmm15, [r10 + rbp + 320]
    vmulpd zmm15, zmm15, zmm6
    vfnmadd231pd zmm15, zmm22, [r9 + rbp + 320]

    vmulpd zmm22, zmm22, [r10 + rbp + 320]
    vfmadd231pd zmm22, zmm6, [r9 + rbp + 320]
    vmovapd zmm6, zmm15

    vmovapd zmm15, [r10 + rbp + 384]
    vmulpd zmm15, zmm15, zmm7
    vfnmadd231pd zmm15, zmm23, [r9 + rbp + 384]

    vmulpd zmm23, zmm23, [r10 + rbp + 384]
    vfmadd231pd zmm23, zmm7, [r9 + rbp + 384]
    vmovapd zmm7, zmm15
    
    ; --Advance pointers--
    lea rdi, [rdi + 4 * r8]
    lea rsi, [rsi + 4 * r8]
    
    ; --Load 8-11
    vmovapd zmm8,  [rdi]
    vmovapd zmm24, [rsi]

    vmovapd zmm9,  [rdi + r8]
    vmovapd zmm25, [rsi + r8]

    vmovapd zmm10, [rdi + 2 * r8]
    vmovapd zmm26, [rsi + 2 * r8]

    vmovapd zmm11, [rdi + rdx]
    vmovapd zmm27, [rsi + rdx]

    vmovapd zmm15, [r10 + rbp + 448]
    vmulpd zmm15, zmm15, zmm8
    vfnmadd231pd zmm15, zmm24, [r9 + rbp + 448]

    vmulpd zmm24, zmm24, [r10 + rbp + 448]
    vfmadd231pd zmm24, zmm8, [r9 + rbp + 448]
    vmovapd zmm8, zmm15

    vmovapd zmm15, [r10 + rbp + 512]
    vmulpd zmm15, zmm15, zmm9
    vfnmadd231pd zmm15, zmm25, [r9 + rbp + 512]

    vmulpd zmm25, zmm25, [r10 + rbp + 512]
    vfmadd231pd zmm25, zmm9, [r9 + rbp + 512]
    vmovapd zmm9, zmm15

    vmovapd zmm15, [r10 + rbp + 576]
    vmulpd zmm15, zmm15, zmm10
    vfnmadd231pd zmm15, zmm26, [r9 + rbp + 576]

    vmulpd zmm26, zmm26, [r10 + rbp + 576]
    vfmadd231pd zmm26, zmm10, [r9 + rbp + 576]
    vmovapd zmm10, zmm15

    vmovapd zmm15, [r10 + rbp + 640]
    vmulpd zmm15, zmm15, zmm11
    vfnmadd231pd zmm15, zmm27, [r9 + rbp + 640]

    vmulpd zmm27, zmm27, [r10 + rbp + 640]
    vfmadd231pd zmm27, zmm11, [r9 + rbp + 640]
    vmovapd zmm11, zmm15
    
    ; --Advance pointers--
    lea rdi, [rdi + 4 * r8]
    lea rsi, [rsi + 4 * r8]

    mov [rsp - 64], zmm0
    
    ; Load 12-15
    vmovapd zmm12, [rdi]
    vmovapd zmm28, [rsi]

    vmovapd zmm13, [rdi + r8]
    vmovapd zmm29, [rsi + r8]

    vmovapd zmm14, [rdi + 2 * r8]
    vmovapd zmm30, [rsi + 2 * r8]

    vmovapd zmm15, [rdi + rdx]
    vmovapd zmm31, [rsi + rdx]

    vmovapd zmm0, [r10 + rbp + 704]
    vmulpd zmm0, zmm0, zmm12
    vfnmadd231pd zmm0, zmm28, [r9 + rbp + 704]

    vmulpd zmm28, zmm28, [r10 + rbp + 704]
    vfmadd231pd zmm28, zmm12, [r9 + rbp + 704]
    vmovapd zmm12, zmm0

    vmovapd zmm0, [r10 + rbp + 768]
    vmulpd zmm0, zmm0, zmm13
    vfnmadd231pd zmm0, zmm29, [r9 + rbp + 768]

    vmulpd zmm29, zmm29, [r10 + rbp + 768]
    vfmadd231pd zmm29, zmm13, [r9 + rbp + 768]
    vmovapd zmm13, zmm0

    vmovapd zmm0, [r10 + rbp + 832]
    vmulpd zmm0, zmm0, zmm14
    vfnmadd231pd zmm0, zmm30, [r9 + rbp + 832]

    vmulpd zmm30, zmm30, [r10 + rbp + 832]
    vfmadd231pd zmm30, zmm14, [r9 + rbp + 832]
    vmovapd zmm14, zmm0

    vmovapd zmm0, [r10 + rbp + 896]
    vmulpd zmm0, zmm0, zmm15
    vfnmadd231pd zmm0, zmm31, [r9 + rbp + 896]

    vmulpd zmm31, zmm31, [r10 + rbp + 896]
    vfmadd231pd zmm31, zmm15, [r9 + rbp + 896]
    vmovapd zmm15, zmm0

    mov zmm0, [rsp-64]
    ;;Seems pretty readable


    add rax, 64
    add rbp, 960
    cmp rax, rcx
    jl .loop

.exit:
    sfence

    pop rbp
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret



