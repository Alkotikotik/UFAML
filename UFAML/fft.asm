section .rodata
    align 64
    SIGN_MASK:         dq 0x8000000000000000 ;;To flip the sign
    SQRT_2_DIV_2:       dq 0.7071067811865476 ;;Somewhat accurate
    SQRT_2_DIV_2_NEG:   dq -0.7071067811865476
    COS_PI_8:           dq 0.9238795325112867
    COS_PI_8_NEG:       dq -0.9238795325112867
    SIN_PI_8:           dq 0.3826834323650898

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
    xor rbp, rbp

; rax = current counter
; rbx = base pointer of src
; r15 = offset within block
; r8  = stride

.loop:
    ;;prefetcht1 [r14 + rbx + r15 + 512]
    ;;prefetcht1 [r14 + rbx + r15 + r8 + 512]
    ;;prefetcht1 [r14 + rbx + r15 + 2 * r8 + 512]

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
    lea rdi, [rbx + r15]
    lea rsi, [r13 + rdi]
    add rdi, r14
    lea rdx, [r8 + 2 * r8]
    
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

    vmovapd [rsp - 64], zmm0
    
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

    vmovapd zmm0, [rsp-64]
    ;;Seems pretty readable
    
    ;;I treat radix 16 as 2d complex matrix 4x4 such: zmm{real,complex}
    ;+---------------------------------------+
    ;|zmm0,16  |zmm4,20  |zmm8,24   |zmm12,28|
    ;|zmm1,17  |zmm5,21  |zmm9,25   |zmm13,29|
    ;|zmm2,18  |zmm6,22  |zmm10,26  |zmm14,30|
    ;|zmm3,19  |zmm7,23  |zmm11,27  |zmm15,31|
    ;+---------------------------------------+
    ;(I should probably get to coding)
    ;
    ;Formulas
    ;X_0 = x_0 + x_1 + x_2 + x_3
    ;X_1 = x_0 - ix_1 - x_2 + ix_3
    ;X_2 = x_0 - x_1 + x_2 - x_3
    ;X_3 = x_0 + ix_1 + x_2 - ix_3


    ;0.
    ;Real inputs: zmm0, zmm4, zmm8, zmm12
    ;Imag inputs: zmm16, zmm20, zmm24, zmm28 

    ;reserve 
    vmovapd [rsp - 576], zmm15
    vmovapd [rsp - 640], zmm31
    
    ; --Real-- intermid
    vaddpd zmm15, zmm0, zmm8
    vmovapd [rsp - 64], zmm15
    vsubpd zmm15, zmm0, zmm8
    vmovapd [rsp - 128], zmm15

    vaddpd zmm15, zmm4, zmm12
    vmovapd [rsp - 192], zmm15
    vsubpd zmm15, zmm4, zmm12 
    vmovapd [rsp - 256], zmm15

    ;; --Imag-- intermid
    vaddpd zmm15, zmm16, zmm24
    vmovapd [rsp - 320], zmm15
    vsubpd zmm15, zmm16, zmm24
    vmovapd [rsp - 384], zmm15

    vaddpd zmm15, zmm20, zmm28
    vmovapd [rsp - 448], zmm15
    vsubpd zmm15, zmm20, zmm28 
    vmovapd [rsp - 512], zmm15

    ;;Avangeres assemble-
    vmovapd zmm0,  [rsp - 64]
    vmovapd zmm16, [rsp - 320]
    vmovapd zmm8,  [rsp - 64]
    vmovapd zmm24, [rsp - 320]

    vaddpd zmm0, zmm0,   [rsp - 192]
    vaddpd zmm16, zmm16, [rsp - 448]
    vsubpd zmm8, zmm8,   [rsp - 192]
    vsubpd zmm24, zmm24, [rsp - 448]

    vmovapd zmm4,  [rsp - 128]
    vmovapd zmm20, [rsp - 384]
    vmovapd zmm12, [rsp - 128]
    vmovapd zmm28, [rsp - 384]

    vaddpd zmm4, zmm4,   [rsp - 512]
    vsubpd zmm20, zmm20, [rsp - 256]
    vsubpd zmm12, zmm12, [rsp - 512]
    vaddpd zmm28, zmm28, [rsp - 256]

    ;1.
    ;Real inputs: zmm1, zmm5, zmm9, zmm13
    ;Imag inputs: zmm17, zmm21, zmm25, zmm29 
    vaddpd zmm15, zmm1, zmm9
    vmovapd [rsp - 64], zmm15
    vsubpd zmm15, zmm1, zmm9
    vmovapd [rsp - 128], zmm15

    vaddpd zmm15, zmm5, zmm13
    vmovapd [rsp - 192], zmm15
    vsubpd zmm15, zmm5, zmm13
    vmovapd [rsp - 256], zmm15

    vaddpd zmm15, zmm17, zmm25
    vmovapd [rsp - 320], zmm15
    vsubpd zmm15, zmm17, zmm25
    vmovapd [rsp - 384], zmm15

    vaddpd zmm15, zmm21, zmm29
    vmovapd [rsp - 448], zmm15
    vsubpd zmm15, zmm21, zmm29
    vmovapd [rsp - 512], zmm15

    vmovapd zmm1,  [rsp - 64 ]
    vmovapd zmm17, [rsp - 320]
    vmovapd zmm9,  [rsp - 64 ]
    vmovapd zmm25, [rsp - 320]

    vaddpd zmm1, zmm1,   [rsp - 192]
    vaddpd zmm17, zmm17, [rsp - 448]
    vsubpd zmm9, zmm9,   [rsp - 192]
    vsubpd zmm25, zmm25, [rsp - 448]

    vmovapd zmm5,  [rsp - 128]
    vmovapd zmm21, [rsp - 384]
    vmovapd zmm13, [rsp - 128]
    vmovapd zmm29, [rsp - 384]

    vaddpd zmm5, zmm5,   [rsp - 512]
    vsubpd zmm21, zmm21, [rsp - 256]
    vsubpd zmm13, zmm13, [rsp - 512]
    vaddpd zmm29, zmm29, [rsp - 256]

    ;2.
    ;Real inputs: zmm2, zmm6, zmm10, zmm14
    ;Imag inputs: zmm18, zmm22, zmm26, zmm30
    vaddpd zmm15, zmm2, zmm10
    vmovapd [rsp - 64], zmm15
    vsubpd zmm15, zmm2, zmm10
    vmovapd [rsp - 128], zmm15

    vaddpd zmm15, zmm6, zmm14
    vmovapd [rsp - 192], zmm15
    vsubpd zmm15, zmm6, zmm14
    vmovapd [rsp - 256], zmm15

    vaddpd zmm15, zmm18, zmm26
    vmovapd [rsp - 320], zmm15
    vsubpd zmm15, zmm18, zmm26
    vmovapd [rsp - 384], zmm15

    vaddpd zmm15, zmm22, zmm30
    vmovapd [rsp - 448], zmm15
    vsubpd zmm15, zmm22, zmm30
    vmovapd [rsp - 512], zmm15

    vmovapd zmm2,  [rsp - 64 ]
    vmovapd zmm18, [rsp - 320]
    vmovapd zmm10, [rsp - 64 ]
    vmovapd zmm26, [rsp - 320]

    vaddpd zmm2, zmm2,   [rsp - 192]
    vaddpd zmm18, zmm18, [rsp - 448]
    vsubpd zmm10, zmm10, [rsp - 192]
    vsubpd zmm26, zmm26, [rsp - 448]
    
    vmovapd zmm6,  [rsp - 128]
    vmovapd zmm22, [rsp - 384]
    vmovapd zmm14, [rsp - 128]
    vmovapd zmm30, [rsp - 384]

    vaddpd zmm6, zmm6,   [rsp - 512]
    vsubpd zmm22, zmm22, [rsp - 256]
    vsubpd zmm14, zmm14, [rsp - 512]
    vaddpd zmm30, zmm30, [rsp - 256]

    ;3.
    ;Real inputs: zmm3, zmm7, zmm11, [rsp - 576] (just realized I can do this)
    ;Imag inputs: zmm19, zmm23, zmm27, [rsp - 640]
    vaddpd zmm15, zmm3, zmm11
    vmovapd [rsp - 64], zmm15
    vsubpd zmm15, zmm3, zmm11
    vmovapd [rsp - 128], zmm15
    
    vaddpd zmm15, zmm7, [rsp - 576]
    vmovapd [rsp - 192], zmm15
    vsubpd zmm15, zmm7, [rsp - 576]
    vmovapd [rsp - 256], zmm15

    vaddpd zmm15, zmm19, zmm27
    vmovapd [rsp - 320], zmm15
    vsubpd zmm15, zmm19, zmm27
    vmovapd [rsp - 384], zmm15
    
    vaddpd zmm15, zmm23, [rsp - 640]
    vmovapd [rsp - 448], zmm15
    vsubpd zmm15, zmm23, [rsp - 640]
    vmovapd [rsp - 512], zmm15

    vmovapd zmm3,  [rsp - 64 ]
    vmovapd zmm19, [rsp - 320]
    vmovapd zmm11, [rsp - 64 ]
    vmovapd zmm27, [rsp - 320]

    vaddpd zmm3, zmm3,   [rsp - 192]
    vaddpd zmm19, zmm19, [rsp - 448]
    vsubpd zmm11, zmm11, [rsp - 192]
    vsubpd zmm27, zmm27, [rsp - 448]

    vmovapd zmm7,  [rsp - 128]
    vmovapd zmm23, [rsp - 384]

    vaddpd zmm7, zmm7,   [rsp - 512]
    vsubpd zmm23, zmm23, [rsp - 256]
    
    vmovapd zmm15, [rsp - 128]
    vsubpd zmm15, zmm15, [rsp - 512]
    vmovapd [rsp - 576], zmm15

    vmovapd zmm15, [rsp - 384]
    vaddpd zmm15, zmm15, [rsp - 256]
    vmovapd [rsp - 640], zmm15

    ;;Internal matrix twiddles, they are constant, so no need to compute them
    ;+----------------------------------------------------------------------------------------------------------------------------------------------------+
    ;| zmm0,16 * 1| zmm4,20 * 1                              | zmm8,24 * 1                                | zmm12,28 * 1                                  |
    ;| zmm1,17 * 1| zmm5,21 * (COS_PI_8 - i*SIN_PI_8)        | zmm9,25 * (SQRT_2_DIV_2 - i*SQRT_2_DIV_2)  | zmm13,29 * (SIN_PI_8 - i*COS_PI_8)            |
    ;| zmm2,18 * 1| zmm6,22 * (SQRT_2_DIV_2 - i*SQRT_2_DIV_2)| zmm10,26 * -i                              | zmm14,30 * (-SQRT_2_DIV_2 - i*SQRT_2_DIV_2)   |
    ;| zmm3,19 * 1| zmm7,23 * (SIN_PI_8 - i*COS_PI_8)        | zmm11,27 * (-SQRT_2_DIV_2 - i*SQRT_2_DIV_2)| zmm15,31 * (-COS_PI_8 + i*SIN_PI_8)            |
    ;+----------------------------------------------------------------------------------------------------------------------------------------------------+

    ;;* -i (zmm10, zmm26)
    ;Swap
    vmovapd zmm15, zmm10
    vmovapd zmm10, zmm26
    vxorpd zmm26, zmm15, [rel SIGN_MASK]{1to8} ; New Imag = -old Real

    ;* SQRT_2_DIV_2 (zmm6, zmm22)
    vaddpd zmm15, zmm6, zmm22 ; zmm15 = R + I
    vsubpd zmm31, zmm22, zmm6 ; zmm31 = I - R
    vmulpd zmm6,  zmm15, [rel SQRT_2_DIV_2]{1to8}
    vmulpd zmm22, zmm31, [rel SQRT_2_DIV_2]{1to8}

    ;(zmm9, zmm25)
    vaddpd zmm15, zmm9, zmm25
    vsubpd zmm31, zmm25, zmm9
    vmulpd zmm9,  zmm15, [rel SQRT_2_DIV_2]{1to8}
    vmulpd zmm25, zmm31, [rel SQRT_2_DIV_2]{1to8}

    ;(zmm11, zmm27)
    vaddpd zmm15, zmm11, zmm27
    vsubpd zmm31, zmm27, zmm11
    vmulpd zmm11, zmm31, [rel SQRT_2_DIV_2]{1to8}
    vmulpd zmm27, zmm15, [rel SQRT_2_DIV_2_NEG]{1to8}

    ;(zmm14, zmm30)
    vaddpd zmm15, zmm14, zmm30
    vsubpd zmm31, zmm30, zmm14
    vmulpd zmm14, zmm31, [rel SQRT_2_DIV_2]{1to8}
    vmulpd zmm30, zmm15, [rel SQRT_2_DIV_2_NEG]{1to8}

    ;*complex (zmm5, zmm21)
    vmulpd zmm15, zmm5, [rel COS_PI_8]{1to8}
    vfnmadd231pd zmm15, zmm21, [rel SIN_PI_8]{1to8}

    vmulpd zmm31, zmm21, [rel COS_PI_8]{1to8}
    vfmadd231pd zmm31, zmm5, [rel SIN_PI_8]{1to8}

    vmovapd zmm5, zmm15
    vmovapd zmm21, zmm31

    ;(zmm7, zmm23)
    vmulpd zmm15, zmm7, [rel SIN_PI_8]{1to8}
    vfmadd231pd zmm15, zmm23, [rel COS_PI_8]{1to8}

    vmulpd zmm31, zmm23, [rel SIN_PI_8]{1to8}
    vfnmadd231pd zmm31, zmm7, [rel COS_PI_8]{1to8}

    vmovapd zmm7, zmm15
    vmovapd zmm23, zmm31

    ;(zmm13, zmm29)
    vmulpd zmm15, zmm13, [rel SIN_PI_8]{1to8}
    vfmadd231pd zmm15, zmm29, [rel COS_PI_8]{1to8}

    vmulpd zmm31, zmm29, [rel SIN_PI_8]{1to8}
    vfnmadd231pd zmm31, zmm7, [rel COS_PI_8]{1to8}

    vmovapd zmm13, zmm15
    vmovapd zmm29, zmm31

    ;(zmm15, zmm31)
    vmovapd [rsp - 64], zmm0
    vmovapd [rsp - 128], zmm16
    vmovapd zmm15, [rsp - 576]
    vmovapd zmm31, [rsp - 640]

    vmulpd zmm0, zmm15, [rel COS_PI_8_NEG]{1to8}
    vfnmadd231pd zmm0, zmm31, [rel SIN_PI_8]{1to8}

    vmulpd zmm16, zmm31, [rel COS_PI_8_NEG]{1to8}
    vfmadd231pd zmm16, zmm15, [rel SIN_PI_8]{1to8}

    vmovapd [rsp - 576], zmm0
    vmovapd [rsp - 640], zmm16
    vmovapd zmm0, [rsp - 64]
    vmovapd zmm16, [rsp - 128]

    ;;Butterfly radix-4 again, same thing, slightly different inputs

    ;0.
    ;Real inputs: zmm0, zmm1, zmm2, zmm3
    ;Imag inputs: zmm16, zmm17, zmm18, zmm19
    vaddpd zmm15, zmm0, zmm2
    vmovapd [rsp - 64], zmm15
    vsubpd zmm15, zmm0, zmm2
    vmovapd [rsp - 128], zmm15

    vaddpd zmm15, zmm1, zmm3
    vmovapd [rsp - 192], zmm15
    vsubpd zmm15, zmm1, zmm3
    vmovapd [rsp - 256], zmm15

    vaddpd zmm15, zmm16, zmm18
    vmovapd [rsp - 320], zmm15
    vsubpd zmm15, zmm16, zmm18
    vmovapd [rsp - 384], zmm15

    vaddpd zmm15, zmm17, zmm19
    vmovapd [rsp - 448], zmm15
    vsubpd zmm15, zmm17, zmm19
    vmovapd [rsp - 512], zmm15

    vmovapd zmm0,  [rsp - 64]
    vmovapd zmm16, [rsp - 320]
    vmovapd zmm2,  [rsp - 64]
    vmovapd zmm18, [rsp - 320]

    vaddpd zmm0, zmm0,   [rsp - 192]
    vaddpd zmm16, zmm16, [rsp - 448]
    vsubpd zmm2, zmm2,   [rsp - 192]
    vsubpd zmm18, zmm18, [rsp - 448]

    vmovapd zmm1,  [rsp - 128]
    vmovapd zmm17, [rsp - 384]
    vmovapd zmm3,  [rsp - 128]
    vmovapd zmm19, [rsp - 384]

    vaddpd zmm1, zmm1,   [rsp - 512]
    vsubpd zmm17, zmm17, [rsp - 256]
    vsubpd zmm3, zmm3,   [rsp - 512]
    vaddpd zmm19, zmm19, [rsp - 256]

    ;1.
    ;Real inputs: zmm4, zmm5, zmm6, zmm7
    ;Imag inputs: zmm20, zmm21, zmm22, zmm23
    vaddpd zmm15, zmm4, zmm6
    vmovapd [rsp - 64], zmm15
    vsubpd zmm15, zmm4, zmm6
    vmovapd [rsp - 128], zmm15

    vaddpd zmm15, zmm5, zmm7
    vmovapd [rsp - 192], zmm15
    vsubpd zmm15, zmm5, zmm7
    vmovapd [rsp - 256], zmm15

    vaddpd zmm15, zmm20, zmm22
    vmovapd [rsp - 320], zmm15
    vsubpd zmm15, zmm20, zmm22
    vmovapd [rsp - 384], zmm15

    vaddpd zmm15, zmm21, zmm23
    vmovapd [rsp - 448], zmm15
    vsubpd zmm15, zmm21, zmm23
    vmovapd [rsp - 512], zmm15

    vmovapd zmm4,  [rsp - 64]
    vmovapd zmm20, [rsp - 320]
    vmovapd zmm6,  [rsp - 64]
    vmovapd zmm22, [rsp - 320]

    vaddpd zmm4, zmm4,   [rsp - 192]
    vaddpd zmm20, zmm20, [rsp - 448]
    vsubpd zmm6, zmm6,   [rsp - 192]
    vsubpd zmm22, zmm22, [rsp - 448]

    vmovapd zmm5,  [rsp - 128]
    vmovapd zmm21, [rsp - 384]
    vmovapd zmm7,  [rsp - 128]
    vmovapd zmm23, [rsp - 384]

    vaddpd zmm5, zmm5,   [rsp - 512]
    vsubpd zmm21, zmm21, [rsp - 256]
    vsubpd zmm7, zmm7,   [rsp - 512]
    vaddpd zmm23, zmm23, [rsp - 256]

    ;2.
    ;Real inputs: zmm8, zmm9, zmm10, zmm11
    ;Imag inputs: zmm24, zmm25, zmm26, zmm27
    vaddpd zmm15, zmm8, zmm10
    vmovapd [rsp - 64], zmm15
    vsubpd zmm15, zmm8, zmm10
    vmovapd [rsp - 128], zmm15

    vaddpd zmm15, zmm9, zmm11
    vmovapd [rsp - 192], zmm15
    vsubpd zmm15, zmm9, zmm11
    vmovapd [rsp - 256], zmm15

    vaddpd zmm15, zmm24, zmm26
    vmovapd [rsp - 320], zmm15
    vsubpd zmm15, zmm24, zmm26
    vmovapd [rsp - 384], zmm15

    vaddpd zmm15, zmm25, zmm27
    vmovapd [rsp - 448], zmm15
    vsubpd zmm15, zmm25, zmm27
    vmovapd [rsp - 512], zmm15

    vmovapd zmm8,  [rsp - 64]
    vmovapd zmm24, [rsp - 320]
    vmovapd zmm10, [rsp - 64]
    vmovapd zmm26, [rsp - 320]

    vaddpd zmm8, zmm8,   [rsp - 192]
    vaddpd zmm24, zmm24, [rsp - 448]
    vsubpd zmm10, zmm10, [rsp - 192]
    vsubpd zmm26, zmm26, [rsp - 448]

    vmovapd zmm9,  [rsp - 128]
    vmovapd zmm25, [rsp - 384]
    vmovapd zmm11, [rsp - 128]
    vmovapd zmm27, [rsp - 384]

    vaddpd zmm9, zmm9,   [rsp - 512]
    vsubpd zmm25, zmm25, [rsp - 256]
    vsubpd zmm11, zmm11, [rsp - 512]
    vaddpd zmm27, zmm27, [rsp - 256]

    ;3.
    ;Real inputs: zmm12, zmm13, zmm14, [rsp - 576]
    ;Imag inputs: zmm28, zmm29, zmm30, [rsp - 640]
    vaddpd zmm15, zmm12, zmm14
    vmovapd [rsp - 64], zmm15
    vsubpd zmm15, zmm12, zmm14
    vmovapd [rsp - 128], zmm15

    vaddpd zmm15, zmm13, [rsp - 576]
    vmovapd [rsp - 192], zmm15
    vsubpd zmm15, zmm13, [rsp - 576]
    vmovapd [rsp - 256], zmm15

    vaddpd zmm15, zmm28, zmm30
    vmovapd [rsp - 320], zmm15
    vsubpd zmm15, zmm28, zmm30
    vmovapd [rsp - 384], zmm15

    vaddpd zmm15, zmm29, [rsp - 640]
    vmovapd [rsp - 448], zmm15
    vsubpd zmm15, zmm29, [rsp - 640]
    vmovapd [rsp - 512], zmm15

    vmovapd zmm12, [rsp - 64]
    vmovapd zmm28, [rsp - 320]
    vmovapd zmm14, [rsp - 64]
    vmovapd zmm30, [rsp - 320]

    vaddpd zmm12, zmm12, [rsp - 192]
    vaddpd zmm28, zmm28, [rsp - 448]
    vsubpd zmm14, zmm14, [rsp - 192]
    vsubpd zmm30, zmm30, [rsp - 448]

    vmovapd zmm13, [rsp - 128]
    vmovapd zmm29, [rsp - 384]

    vaddpd zmm13, zmm13, [rsp - 512]
    vsubpd zmm29, zmm29, [rsp - 256]
    
    vmovapd zmm15, [rsp - 128]
    vsubpd zmm15, zmm15, [rsp - 512]
    vmovapd [rsp - 576], zmm15
    
    vmovapd zmm15, [rsp - 384]
    vaddpd zmm15, zmm15, [rsp - 256]
    vmovapd [rsp - 640], zmm15

    ;;Calculations done, now we need to store it basically the same thing as loading
    lea rdi, [rbx + r15] ;rdi = dst real pointer
    lea rsi, [r11 + rdi] ;rsi = dst imag pointer
    add rdi, r12
    
    ;;0-3
    vmovapd [rdi], zmm0
    vmovapd [rsi], zmm16

    vmovapd [rdi + r8], zmm1
    vmovapd [rsi + r8], zmm17

    vmovapd [rdi + 2 * r8], zmm2
    vmovapd [rsi + 2 * r8], zmm18

    vmovapd [rdi + rdx], zmm3
    vmovapd [rsi + rdx], zmm19

    ; --Advance pointers--
    lea rdi, [rdi + 4 * r8]
    lea rsi, [rsi + 4 * r8]

    ;4-7
    vmovapd [rdi], zmm4
    vmovapd [rsi], zmm20

    vmovapd [rdi + r8], zmm5
    vmovapd [rsi + r8], zmm21

    vmovapd [rdi + 2 * r8], zmm6
    vmovapd [rsi + 2 * r8], zmm22

    vmovapd [rdi + rdx], zmm7
    vmovapd [rsi + rdx], zmm23

    ; --Advance pointers--
    lea rdi, [rdi + 4 * r8]
    lea rsi, [rsi + 4 * r8]

    ;8-11
    vmovapd [rdi], zmm8
    vmovapd [rsi], zmm24

    vmovapd [rdi + r8], zmm9
    vmovapd [rsi + r8], zmm25

    vmovapd [rdi + 2 * r8], zmm10
    vmovapd [rsi + 2 * r8], zmm26

    vmovapd [rdi + rdx], zmm11
    vmovapd [rsi + rdx], zmm27

    ; --Advance pointers--
    lea rdi, [rdi + 4 * r8]
    lea rsi, [rsi + 4 * r8]

    ;12-15
    vmovapd [rdi], zmm12
    vmovapd [rsi], zmm28

    vmovapd [rdi + r8], zmm13
    vmovapd [rsi + r8], zmm29

    vmovapd [rdi + 2 * r8], zmm14
    vmovapd [rsi + 2 * r8], zmm30

    vmovapd zmm15, [rsp - 576]
    vmovapd zmm31, [rsp - 640]
    vmovapd [rdi + rdx], zmm15
    vmovapd [rsi + rdx], zmm31


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
