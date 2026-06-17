
section .text 

global fft 
fft: 
; rdi = float* src_real
; rsi = float* src_imag
; rdx = float* dst_real
; rcx = float* dst_imag
; r8  = int stride
; r9  = int span
    
    push r15
    push r14
    push r12
    sub rsp, 16

    shl r8, 2
    shl r9, 2 


    xor r15, r15 
.loop_outer:
    cmp r15, r9
    jge .end_outer

    ;;TODO load twiddle

    xor r14, r14
.loop_inner:
    cmp r14, r8
    jge end_inner

    ;;TODO everything 
    

    add r14, 64
    jmp loop_outer
end_inner:

    add r15, 64
    jmp loop_p
end_outer:

    pop r12
    pop r14
    pop r15
    ret

