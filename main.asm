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

verlet_integration:
    vmovaps zmm3, [rcx] ;dt
    vmulps zmm3, zmm3, zmm3 ;; dt^2
    vmulps zmm3, zmm3, 0.5 ;;dt^2 * 0.5

    vmovaps zmm5, xxm1 ;;Force
    vmovaps zmm6, xxm2 ;;Mass

    vdivps zmm5 

.loop 
    cmp xxm0, 0 ;; xmm0 is count here
    jle .exit

    vmovaps zmm0, [rdi] ;pos
    vmovaps zmm1, [rsi] ;vel
    vmovaps zmm2, [rdx] ;accel

    vfmadd231ps zmm0, zmm1, zmm2 ;; pos + (vel * dt) in zmm0
    vmulps zmm4, zmm2, zmm3 ;; (0.5 * accel * dt^2)
    vaddps zmm4, zmm4, zmm0 ;; New pos in zmm0

    
