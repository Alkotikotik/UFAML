;; Basic vector operations: add, subtract, scale, length 

%macro FETCH_2 0
    push r12
    push r13
    push r14
    push r15
    push rbx


;rdi = vecA base pointer
;rsi = vecB base pointer
;rdx = counter
;rcx = result base pointer
    shl rdx, 2 ;Multiply count by 4 

    sub rsp, 24 ;Reserve 24 bytes for vecA

    mov r14, [rdi] ; vecA X
    mov r13, [rdi + 8] ; vecA Y
    mov r12, [rdi + 16]; vecA Z
    
    ; Push vecA pointers onto the stack to free up the registers
    mov [rsp], r14
    mov [rsp + 8], r13
    mov [rsp + 16], r12

    mov r14, [rsi]
    mov r13, [rsi + 8]
    mov r12, [rsi + 16]

    mov r11, [rcx]
    mov r10, [rcx + 8]
    mov r9,  [rcx + 16]

    xor rax, rax
%endmacro

%macro LOAD 0 
    ; Fetching vecA from stack
    mov rbx, [rsp]

    prefetcht1 [rbx + rax + 512]
    prefetcht1 [rbx + rax + 512 + 64]
    prefetcht1 [rbx + rax + 512 + 128]
    prefetcht1 [rbx + rax + 512 + 192]

    vmovaps zmm0, [rbx + rax]
    vmovaps zmm1, [rbx + rax + 64]
    vmovaps zmm2, [rbx + rax + 128]
    vmovaps zmm3, [rbx + rax + 192]
    
    mov rbx, [rsp + 8]

    prefetcht1 [rbx + rax + 512]
    prefetcht1 [rbx + rax + 512 + 64]
    prefetcht1 [rbx + rax + 512 + 128]
    prefetcht1 [rbx + rax + 512 + 192]

    vmovaps zmm4, [rbx + rax]
    vmovaps zmm5, [rbx + rax + 64]
    vmovaps zmm6, [rbx + rax + 128]
    vmovaps zmm7, [rbx + rax + 192]

    
    mov rbx, [rsp + 16]

    prefetcht1 [rbx + rax + 512]
    prefetcht1 [rbx + rax + 512 + 64]
    prefetcht1 [rbx + rax + 512 + 128]
    prefetcht1 [rbx + rax + 512 + 192]

    vmovaps zmm8,  [rbx + rax]
    vmovaps zmm9,  [rbx + rax + 64]
    vmovaps zmm10, [rbx + rax + 128]
    vmovaps zmm11, [rbx + rax + 192]

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


    vmovaps zmm12, [r14 + rax]
    vmovaps zmm13, [r14 + rax + 64]
    vmovaps zmm14, [r14 + rax + 128]
    vmovaps zmm15, [r14 + rax + 192]
    
    vmovaps zmm16, [r13 + rax]
    vmovaps zmm17, [r13 + rax + 64]
    vmovaps zmm18, [r13 + rax + 128]
    vmovaps zmm19, [r13 + rax + 192]

    vmovaps zmm20, [r12 + rax]
    vmovaps zmm21, [r12 + rax + 64]
    vmovaps zmm22, [r12 + rax + 128]
    vmovaps zmm23, [r12 + rax + 192]
%endmacro

%macro SAVE 0 

    vmovntps [r11 + rax], zmm0 
    vmovntps [r11 + rax + 64], zmm1
    vmovntps [r11 + rax + 128], zmm2
    vmovntps [r11 + rax + 192], zmm3

    vmovntps [r10 + rax], zmm4 
    vmovntps [r10 + rax + 64], zmm5
    vmovntps [r10 + rax + 128], zmm6
    vmovntps [r10 + rax + 192], zmm7

    vmovntps [r9 + rax], zmm8 
    vmovntps [r9 + rax + 64], zmm9
    vmovntps [r9 + rax + 128], zmm10
    vmovntps [r9 + rax + 192], zmm11
%endmacro

%macro EXIT 0
    ;Clean up
    add rsp, 24

    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    
    sfence
    ret
%endmacro

%macro COMPUTE_LENGTH 1
    vmovaps zmm0, [r14 + rax]
    vmovaps zmm1, [r14 + rax + 64]
    vmovaps zmm2, [r14 + rax + 128]
    vmovaps zmm3, [r14 + rax + 192]
    
    vmovaps zmm4, [r13 + rax]
    vmovaps zmm5, [r13 + rax + 64]
    vmovaps zmm6, [r13 + rax + 128]
    vmovaps zmm7, [r13 + rax + 192]

    vmovaps zmm8, [r12 + rax]
    vmovaps zmm9, [r12 + rax + 64]
    vmovaps zmm10, [r12 + rax + 128]
    vmovaps zmm11, [r12 + rax + 192]

    vmulps zmm0, zmm0, zmm0
    vmulps zmm1, zmm1, zmm1
    vmulps zmm2, zmm2, zmm2
    vmulps zmm3, zmm3, zmm3

    vfmadd231ps zmm0, zmm4, zmm4
    vfmadd231ps zmm1, zmm5, zmm5
    vfmadd231ps zmm2, zmm6, zmm6
    vfmadd231ps zmm3, zmm7, zmm7

    vfmadd231ps zmm0, zmm8, zmm8
    vfmadd231ps zmm1, zmm9, zmm9
    vfmadd231ps zmm2, zmm10, zmm10
    vfmadd231ps zmm3, zmm11, zmm11

    %ifidni %1, ACCURATE
        vsqrtps zmm0, zmm0
        vsqrtps zmm1, zmm1
        vsqrtps zmm2, zmm2
        vsqrtps zmm3, zmm3
    %else
        vrsqrt14ps zmm12, zmm0
        vrsqrt14ps zmm13, zmm1
        vrsqrt14ps zmm14, zmm2
        vrsqrt14ps zmm15, zmm3

        vmulps zmm0, zmm12, zmm0
        vmulps zmm1, zmm13, zmm1
        vmulps zmm2, zmm14, zmm2
        vmulps zmm3, zmm15, zmm3
    %endif

    vmovntps [rdx + rax], zmm0 
    vmovntps [rdx + rax + 64], zmm1
    vmovntps [rdx + rax + 128], zmm2
    vmovntps [rdx + rax + 192], zmm3
%endmacro

section .text 

global vec3_add

vec3_add:
    FETCH_2

.loop:
    LOAD 
    ;; X
    vaddps zmm0, zmm0, zmm12 
    vaddps zmm1, zmm1, zmm13
    vaddps zmm2, zmm2, zmm14
    vaddps zmm3, zmm3, zmm15
    
    ;; Y
    vaddps zmm4, zmm4, zmm16 
    vaddps zmm5, zmm5, zmm17
    vaddps zmm6, zmm6, zmm18
    vaddps zmm7, zmm7, zmm19
    
    ;;Z
    vaddps zmm8, zmm8, zmm20 
    vaddps zmm9, zmm9, zmm21
    vaddps zmm10, zmm10, zmm22
    vaddps zmm11, zmm11, zmm23

    SAVE   

    add rax, 256
    cmp rax, rdx
    jl .loop

.exit:
    EXIT

global vec3_subtract 
vec3_subtract:

    FETCH_2
.loop:
    LOAD 

    ;; X
    vsubps zmm0, zmm0, zmm12 
    vsubps zmm1, zmm1, zmm13
    vsubps zmm2, zmm2, zmm14
    vsubps zmm3, zmm3, zmm15
    ; Y
    vsubps zmm4, zmm4, zmm16 
    vsubps zmm5, zmm5, zmm17
    vsubps zmm6, zmm6, zmm18
    vsubps zmm7, zmm7, zmm19
    ;Z
    vsubps zmm8, zmm8, zmm20 
    vsubps zmm9, zmm9, zmm21
    vsubps zmm10, zmm10, zmm22
    vsubps zmm11, zmm11, zmm23

    SAVE

    add rax, 256
    cmp rax, rdx
    jl .loop

.exit:
    EXIT

global vec3_len_accurate
global vec3_len_fast

vec3_len_accurate:
;rdi = vecA base pointer
;rsi = counter
;rdx = result base pointer
    push r12
    push r13
    push r14
    push r15

    shl rsi, 2

    mov r14, [rdi] ; vecA X
    mov r13, [rdi + 8] ; vecA Y
    mov r12, [rdi + 16]; vecA Z
    
    xor rax, rax 
.loop:
    COMPUTE_LENGTH ACCURATE

    add rax, 256
    cmp rax, rsi
    jl .loop

.exit:
    pop r15
    pop r14
    pop r13
    pop r12
    
    sfence
    ret

vec3_len_fast:
;rdi = vecA base pointer
;rsi = counter
;rdx = result base pointer
    push r12
    push r13
    push r14
    push r15

    shl rsi, 2

    mov r14, [rdi] ; vecA X
    mov r13, [rdi + 8] ; vecA Y
    mov r12, [rdi + 16]; vecA Z
    
    xor rax, rax 
.loop:
    COMPUTE_LENGTH FAST

    add rax, 256
    cmp rax, rsi
    jl .loop

.exit:
    pop r15
    pop r14
    pop r13
    pop r12
    
    sfence
    ret

global vec3_scale 
vec3_scale:
;rdi = vecA base pointer
;xmm0 = factos
;rsi = count 
;rdx = output vector
    push r12
    push r13
    push r14
    push r15

    shl rsi, 2

    mov r14, [rdi] ; vecA X
    mov r13, [rdi + 8] ; vecA Y
    mov r12, [rdi + 16]; vecA Z

    mov r11, [rdx]
    mov r10, [rdx + 8]
    mov r9, [rdx + 16]

    vbroadcastss zmm31, xmm0

.loop:
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

    vmovaps zmm0, [r14 + rax]
    vmovaps zmm1, [r14 + rax + 64]
    vmovaps zmm2, [r14 + rax + 128]
    vmovaps zmm3, [r14 + rax + 192]

    vmovaps zmm4, [r13 + rax]
    vmovaps zmm5, [r13 + rax + 64]
    vmovaps zmm6, [r13 + rax + 128]
    vmovaps zmm7, [r13 + rax + 192]

    vmovaps zmm8, [r12 + rax]
    vmovaps zmm9, [r12 + rax + 64]
    vmovaps zmm10, [r12 + rax + 128]
    vmovaps zmm11, [r12 + rax + 192]

    vmulps zmm0, zmm0, zmm31
    vmulps zmm1, zmm1, zmm31
    vmulps zmm2, zmm2, zmm31
    vmulps zmm3, zmm3, zmm31

    vmulps zmm4, zmm4, zmm31
    vmulps zmm5, zmm5, zmm31
    vmulps zmm6, zmm6, zmm31
    vmulps zmm7, zmm7, zmm31

    vmulps zmm8, zmm8, zmm31
    vmulps zmm9, zmm9, zmm31
    vmulps zmm10, zmm10, zmm31
    vmulps zmm11, zmm11, zmm31

    SAVE

    add rax, 256
    cmp rax, rsi
    jl .loop

.exit:
    pop r15
    pop r14
    pop r13
    pop r12
    
    sfence
    ret
