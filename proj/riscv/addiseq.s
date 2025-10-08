# ==========================================================
# addiseq.s — Simple ADDI sequence test for RISC-V
# Lab 3 test program for CPR E 3810
# ==========================================================

    .data               # (optional) data section
# No data needed for this test

    .text               # code section
    .globl _start       # define program entry point

_start:
    addi x1,  x0, 1     # x1 = 1
    addi x2,  x0, 2     # x2 = 2
    addi x3,  x0, 3     # x3 = 3
    addi x4,  x0, 4     # x4 = 4
    addi x5,  x0, 5     # x5 = 5
    addi x6,  x0, 6     # x6 = 6
    addi x7,  x0, 7     # x7 = 7
    addi x8,  x0, 8     # x8 = 8
    addi x9,  x0, 9     # x9 = 9
    addi x10, x0, 10    # x10 = 10

    ecall               # end program
