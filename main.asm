section .rodata 
    align 4 ; Align bytes here too
    _one: dd 1.0
    _half: dd 0.5

    err_null_ptr:     db "UFAML Error: NULL pointer has been passed to verlet_integration", 0x0A
    err_null_ptr_len: equ $ - err_null_ptr

    err_align:        db "UFAML Error: Input arrays must be 64-byte aligned for AVX-512", 0x0A
    err_align_len:    equ $ - err_align

%macro PROCESS_AXIS_VERLET 1
    ; Load base pointers dynamically based on offset, so 0, 8, 16 for xyz
    mov r14, [rdi + (%1)]          ; PosX/Y/Z base pointer depending on %1
    mov r13, [rdi + 24 + (%1)]     ; VelX/Y/Zbase pointer
    mov r12, [rdi + 48 + (%1)]     ; ForceX/Y/Z base pointer

    mov r11, [rdx + (%1)]          ; PosX/Y/Z output base pointer
    mov r10, [rdx + 24 + (%1)]     ; VelX/Y/Z out
    mov r9,  [rdx + 48 + (%1)]     ; AccelX/Y/Z out

    ;;rax is gonna be our "i" in "for" loop
    xor rax, rax

%%loop: ;%% means local 

    prefetcht1 [r14 + rax + 512]
    prefetcht1 [r14 + rax + 512 + 64]
    prefetcht1 [r14 + rax + 512 + 128]
    prefetcht1 [r14 + rax + 512 + 192]

    prefetcht1 [r13 + rax + 512]
    prefetcht1 [r13 + rax + 512 + 64]
    prefetcht1 [r13 + rax + 512 + 128]
    prefetcht1 [r13 + rax + 512 + 192]

    prefetcht1 [r12 + rax + 512]
    prefetcht1 [r12 + rax + 512 + 64]
    prefetcht1 [r12 + rax + 512 + 128]
    prefetcht1 [r12 + rax + 512 + 192]

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

    ; Force 
    vmovaps zmm8, [r12 + rax]
    vmovaps zmm9, [r12 + rax + 64]
    vmovaps zmm10, [r12 + rax + 128]
    vmovaps zmm11, [r12 + rax + 192]
    
    ; Calculate Accel
    vmulps zmm12, zmm8, zmm30
    vmulps zmm13, zmm9, zmm30
    vmulps zmm14, zmm10, zmm30
    vmulps zmm15, zmm11, zmm30
    
    ; Save accel, straight to RAM
    vmovntps [r9 + rax], zmm12
    vmovntps [r9 + rax + 64], zmm13
    vmovntps[r9 + rax + 128], zmm14
    vmovntps [r9 + rax + 192], zmm15
    
    
    ;;Calculate new poses in parralel
    vfmadd213ps zmm4, zmm31, zmm0
    vmulps zmm16, zmm12, zmm29
    vaddps zmm0, zmm4, zmm16

    vfmadd213ps zmm5, zmm31, zmm1
    vmulps zmm17, zmm13, zmm29
    vaddps zmm1, zmm5, zmm17

    vfmadd213ps zmm6, zmm31, zmm2
    vmulps zmm18, zmm14, zmm29
    vaddps zmm2, zmm6, zmm18

    vfmadd213ps zmm7, zmm31, zmm3
    vmulps zmm19, zmm15, zmm29
    vaddps zmm3, zmm7, zmm19


    ;;Store new pos in r11
    vmovntps [r11 + rax], zmm0
    vmovntps [r11 + rax + 64], zmm1
    vmovntps [r11 + rax + 128], zmm2
    vmovntps [r11 + rax + 192], zmm3
    
    ; Calculate new velocity 
    vfmadd231ps zmm4, zmm12, zmm31
    vfmadd231ps zmm5, zmm13, zmm31
    vfmadd231ps zmm6, zmm14, zmm31
    vfmadd231ps zmm7, zmm15, zmm31
    
    ;Store new velocity in r10
    vmovntps [r10 + rax], zmm4
    vmovntps [r10 + rax + 64], zmm5
    vmovntps [r10 + rax + 128], zmm6
    vmovntps [r10 + rax + 192], zmm7

    add rax, 256
    cmp rax, rsi
    jl %%loop

%%exit:
%endmacro

section .text

global asm_add_vectors_512 

asm_add_vectors_512:

.loop:
    ;;According to some convention argv = [rdi, rsi, rdx, rcx, r8, r9] then on stack through xmm0-xmm7
    ;; Though if any of args are float they jump straight into xmm0-xmm7
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

    push r12
    push r13
    push r14
    push r15
    
    ;Erors handeling
    test rdi, rdi ;Check if inputs are NULL pointer
    jz .handle_null_error 
    
    test rdx, rdx ; Same for outputs
    jz .handle_null_error
    
    mov r8, [rdi]; Load to check alighment
    test r8, 0x3F; Check if lowest 6 bits are aligned
    jnz .handle_align_error

    shl rsi, 2

; rdi = verlet config struct
; rsi = count
; xmm0 = dt xmm bc float
; xmm1 = mass
; rdx = verlet outputs
    vbroadcastss zmm31, xmm0

    vbroadcastss zmm29, [rel _half]
    vmulps zmm28, zmm29, zmm31
    vmulps zmm29, zmm28, zmm31
    
    vmovss xmm2, [rel _one]
    vdivss xmm2, xmm2, xmm1
    vbroadcastss zmm30, xmm2

;zmm31 = dt
;zmm30 = 1/mass 
;zmm29 = dt * 0.5 * dt 
;zmm28 = 0.5 * dt
    
    ;Clean for every axis
    PROCESS_AXIS_VERLET 0      ; X Axis
    PROCESS_AXIS_VERLET 8      ; Y Axis
    PROCESS_AXIS_VERLET 16     ; Z Axis

    pop r15
    pop r14
    pop r13
    pop r12
    
    ;; Finilize RAM storage
    sfence

ret

.handle_null_error:
    mov rax, 1 
    mov rdi, 2
    mov rsi, err_null_ptr
    mov rdx, err_null_ptr_len
    syscall

    mov rax, 60
    mov rdi, 1 ;general error
    syscall

.handle_align_error:
    mov rax, 1 
    mov rdi, 2
    mov rsi, err_align
    mov rdx, err_align_len
    syscall

    mov rax, 60
    mov rdi, 2 ;Specific error
    syscall



