section .rodata 
    _one: dd 1.0
    _half: dd 0.5

section .text

global asm_add_vectors_512 

asm_add_vectors_512:

.loop:
    ;;According to some convention argv = [rdi, rsi, rdx, rcx, r8, r9] then on stack through xmm0-xmm7
    cmp rcx, 0
    jle .exit

    vmovaps zmm0, [rdi] ;; Vector mov aligned packed float 
    vmovaps zmm1, [rsi] 

    vaddps zmm2, zmm0, zmm1 ;;Vector add

    vmovaps [rdx], zmm2

    ;; Proccess next chunk 
    add rdi, 64
    add rsi, 64
    add rdx, 64
    
    ;;Dec rcx by 16
    sub rcx, 16
    jmp .loop

.exit:
    ret

global verlet_integration

verlet_integration:
; rdi = verlet config struct
; rsi = count
; xmm0 = dt xmm bc float
; xmm1 = mass
; rdx = verlet outputs
    vbroadcastss zmm31, xmm0 ;; dt is now all over zmm28

    vbroadcastss zmm29, [_half]
    vmulps zmm29, zmm29, zmm31
    vmulps zmm29, zmm29, zmm31 ; dt * 0.5 * dt in zmm31
    
    ;;Calc 1/mass to then multiply by force which is much more efficient
    vmovss xmm2, [_one]
    vdivss xmm2, xmm2, xmm1
    vbroadcastss zmm30, xmm2
    
    ;;rax is gonna be our "i" in "for" loop
    xor rax, rax
    xor r15, r15

.loop:
    cmp r15, rsi
    jge .exit
    
    ; X 
    mov r14, [rdi] ; PosX base pointer
    mov r13, [rdi + 24] ; VelX base pointer
    mov r12, [rdi + 48] ; AccelX base pointer

    mov r11, [rdx] ; PosX output base pointer
    mov r10, [rdx + 24] ; Same
    mov r9, [rdx + 48]
    
    ; Pos
    vmovaps zmm0, [r14 + rax] ; 0 to 64 bytes float is 4 bytes so 0-15
    vmovaps zmm1, [r14 + rax + 64] ; Hence 16 - 32
    vmovaps zmm2, [r14 + rax + 128] ; And 32 - 48
    vmovaps zmm3, [r14 + rax + 192]

    ; Vel 
    vmovaps zmm4, [r13 + rax]
    vmovaps zmm5, [r13 + rax + 64]
    vmovaps zmm6, [r13 + rax + 128]
    vmovaps zmm7, [r13 + rax + 192]

    ; Accel 
    vmovaps zmm8, [r12 + rax]
    vmovaps zmm9, [r12 + rax + 64]
    vmovaps zmm10, [r12 + rax + 128]
    vmovaps zmm11, [r12 + rax + 192]

    vmulps zmm8, zmm4, zmm31
    vmulps zmm9, zmm5, zmm31
    vmulps zmm10, zmm6, zmm31
    vmulps zmm11, zmm7, zmm31

    vfmadd231ps zmm0, zmm8, zmm29
    vfmadd231ps zmm1, zmm9, zmm29
    vfmadd231ps zmm2, zmm10, zmm29
    vfmadd231ps zmm3, zmm11, zmm29

    vaddps zmm12, zmm0, zmm8
    vaddps zmm13, zmm1, zmm9
    vaddps zmm14, zmm2, zmm10
    vaddps zmm15, zmm3, zmm11

    vmovaps [r11 + rax], zmm8
    vmovaps [r11 + rax + 64], zmm9
    vmovaps [r11 + rax + 128], zmm10
    vmovaps [r11 + rax + 192], zmm11



    add r15, 64
    add rax, 256 ; 64 * 4 bytes(per float)
    jmp .loop

.exit:
    ret
