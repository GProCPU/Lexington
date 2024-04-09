.file "main.S"
.section .text
.balign 4
.global inst_test
.global check
.global error
.global done

// Important: all registers should contain their index (i.e. x21 = 21) except:
//  - x1: link register/return address (alias ra)
//  - x2: stack pointer (alias sp)
//  - x10: function argument
//  - x11: second function argument


// Instruction test function
inst_test:
    csrw    mie, 0          // disable all interrupt sources
    addi    sp, sp, -12
    sw      ra, 8(sp)       // push return address
    csrr    ra, mscratch
    sw      ra, 4(sp)       // push mscratch
    csrr    ra, mtvec
    sw      ra, 0(sp)       // push mtvec

    csrw    mscratch, x0
    call    init_regs
    // test NOP
    __test_nop:
    nop
    call    check_all
    // test ADD
    __test_add:
    add     x10, x7, x31    // 7 + 31 = 38
    li      x11, 38
    call    check
    // test SUB
    __test_sub:
    sub     x10, x7, x13    // 7 - 13 = -6
    li      x11, -6
    call    check
    // test SLL
    __test_sll:
    sll     x10, x31, x3    // 0x1F << 3 = 0xF8
    li      x11, 0xF8
    call    check
    // test SLT
    __test_slt:
    slt     x10, x13, x13   // 13 !< 13
    li      x11, 0
    call    check
    li      x10, -2047
    slt     x10, x10, x0    // -2047 < 0
    li      x11, 1
    call    check
    // test SLTU
    __test_sltu:
    li      x10, -2047
    sltu    x10, x10, x23   // 0xFFFF_F801 !< 23
    li      x11, 0
    call    check
    // test XOR
    __test_xor:
    xor     x10, x31, x21   // 0b1_1111 ^ 0b1_0101 = 0b0_1010
    li      x11, 0xA
    call    check
    // test SRL
    __test_srl:
    li      x10, 0xFFFFFF00
    srl     x10, x10, x7    // 0xFFFF_FFFF >> 7 = 0x01FF_FFFE
    li      x11, 0x01FFFFFE
    call    check
    // test SRA
    __test_sra:
    li      x10, 0xFFFFFF00
    sra     x10, x10, x7    // 0xFFFF_FF00 >>> 7 = 0xFFFF_FFFE
    li      x11, 0xFFFFFFFE
    call    check
    // test OR
    __test_or:
    li      x10, 0xFFAA5500
    li      x11, 0xAA5500F3
    or      x10, x10, x11   // 0xFFAA_5500 | 0xAA55_00F3 = 0xFFFF_55F3
    li      x11, 0xFFFF55F3
    call    check
    // test AND
    __test_and:
    li      x10, 0xFFAA5503
    li      x11, 0xAA5500EB
    and     x10, x10, x11   // 0xFFAA_5500 & 0xAA55_00F3 = 0xAA00_0003
    li      x11, 0xAA000003
    call    check
    // test ADDI
    __test_addi:
    addi    x10, x14, -2048 // 14 - 2048 = -2034
    li      x11, -2034
    call    check
    // test SLLI
    __test_slli:
    slli    x10, x27, 27    // 0x0000_001B << 11 = 0xD800_0000
    li      x11, 0xD8000000
    call    check
    // test SLTI
    __test_slti:
    slti    x10, x7, -12    // 7 !< -12
    li      x11, 0
    call    check
    // test SLTUI
    __test_sltui:
    sltiu   x10, x7, -12    // 7 < 0xFFFF_FFF4
    li      x11, 1
    call    check
    // test XORI
    __test_xori:
    xori    x10, x23, 0xF0  // 0x17 ^ 0xF0 = 0xE7
    li      x11, 0xE7
    call    check
    // test ANDI
    __test_andi:
    andi    x10, x23, 0xF0  // 0x17 & 0xF0 = 0x10
    li      x11, 0x10
    call    check
    // test LUI
    __test_lui:
    lui     x10, 0x5A5FF    // 0x5A5FF << 12 = 0x0A5F_F000
    li      x11, 0x5A5
    slli    x11, x11, 8
    addi    x11, x11, 0xFF
    slli    x11, x11, 12
    call    check
    // test auipc
    __test_auipc:
    auipc   x10, 0
    jalr    x11, x10, 8
    addi    x11, x11, -8
    call    check
    // test BEQ
    __test_beq_taken:
    li      x10, 0
    li      x11, 0
    beq     x10, x11, (__test_beq_taken + 16)
    li      x11, 1
    call    check
    __test_beq_not_taken:
    li      x10, 0
    li      x11, 10
    beq     x10, x11, (__test_beq_not_taken + 16)
    li      x11, 5
    addi    x11, x11, -5
    call    check
    // test BNE
    __test_bne_taken:
    li      x10, 0
    li      x11, 5
    bne     x10, x11, (__test_bne_taken + 16)
    li      x11, 10
    addi    x11, x11, -5
    call    check
    __test_bne_not_taken:
    li      x10, 0
    li      x11, 0
    bne     x10, x11, (__test_bne_not_taken + 16)
    li      x11, -5
    addi    x11, x11, 5
    call    check
    // test BLT
    __test_blt_taken:
    li      x10, -5
    li      x11, 0
    blt     x10, x11, (__test_blt_taken + 16)
    li      x10, -10
    addi    x10, x10, 5
    call    check
    __test_blt_not_taken:
    li      x10, -5
    li      x11, -5
    blt     x10, x11, (__test_blt_not_taken + 16)
    li      x11, 0
    addi    x10, x10, 5
    call    check
    // test BGE
    __test_bge_taken:
    li      x10, 0
    li      x11, 0
    bge     x10, x11, (__test_bge_taken + 16)
    li      x11, 0xFF
    call    check
    __test_bge_not_taken:
    li      x10, -5
    li      x11, 0
    bge     x10, x11, (__test_bge_not_taken + 24) // not taken
    addi    x10, x10, 5
    bge     x10, x11, (__test_bge_not_taken + 24) // taken
    addi    x10, x10, 5
    call    check
    // test BLTU
    __test_bltu_taken:
    li      x10, 0
    li      x11, -5
    bltu    x10, x11, (__test_bltu_taken + 16)
    li      x11, -10
    addi    x11, x11, 5
    call    check
    __test_bltu_not_taken:
    li      x10, -1
    li      x11, 0
    bltu    x10, x11, (__test_bltu_not_taken + 16)
    li      x10, 0
    call    check
    // test BGEU
    __test_bgeu_taken:
    li      x10, -27
    li      x11, 40
    bgeu    x10, x11, (__test_bgeu_taken + 16)
    li      x11, 0
    addi    x11, x11, -67
    call    check
    __test_bgeu_not_taken:
    li      x10, 4
    li      x11, -4
    bgeu    x10, x11, (__test_bgeu_not_taken + 24) // not taken
    li      x11, 4
    bgeu    x10, x11, (__test_bgeu_not_taken + 24) //taken
    addi    x11, x11, 10
    call    check

    // initialize memory test
    __test_mem:
    addi    sp, sp, -4
    // test SW & LW
    __test_sw_lw:
    li      x10, 0xBAADCAFE
    li      x11, 0
    sw      x10, 0(sp)
    lw      x11, 0(sp)
    call    check
    // test SH
    __test_sh:
    li      x10, 0xBAADCAFE
    li      x11, 0xAAAAF00D
    sw      x10, 0(sp)
    sh      x11, 0(sp)
    lw      x10, 0(sp)
    li      x11, 0xBAADF00D
    call    check
    // test LH LHU
    __test_lh_lhu:
    li      x10, 0xBAADCAFE
    sw      x10, 0(sp)
    lh      x11, 0(sp)
    li      x10, 0xFFFFCAFE
    call    check
    lhu     x11, 0(sp)
    li      x10, 0x0000CAFE
    call    check
    // test SB
    __test_sb:
    li      x10, 0xBAADCAFE
    li      x11, 0xAAAAF00D
    sw      x10, 0(sp)
    sb      x11, 0(sp)
    lw      x10, 0(sp)
    li      x11, 0xBAADCA0D
    call    check
    // test LB LBU
    __test_lb_lbu:
    li      x10, 0xBAADCAFE
    sw      x10, 0(sp)
    lb      x11, 0(sp)
    li      x10, 0xFFFFFFFE
    call    check
    lbu     x11, 0(sp)
    li      x10, 0x000000FE
    call    check
    __end_test_mem:
    addi    sp, sp, 4

    // CSR Tests
    // test csrrw
    __test_csrrw:
    li      x11, 0xFFAA5522
    li      x12, 0x5FF00AA5
    csrw    mscratch, x11
    csrrw   x10, mscratch, x12
    csrr    x13, mscratch
    call    check
    mv      x10, x13
    mv      x11, x12
    call    check
    li      x12, 12
    li      x13, 13
    // test misa
    __test_misa:
    li      x10, 0xFFFFFFFF
    csrrw   x10, misa, x10
    li      x11, 0x40000100     // expected value
    call    check
    csrr    x10, misa
    call    check
    // test mvendorid
    __test_mvendorid:
    li      x10, 0xFFFFFFFF
    csrrw   x10, mvendorid, x10
    li      x11, 0              // expected value
    call    check
    csrr    x10, mvendorid
    call    check
    // test marchid
    __test_marchid:
    li      x10, 0xFFFFFFFF
    csrrw   x10, marchid, x10
    li      x11, 0              // expected value
    call    check
    csrr    x10, marchid
    call    check
    // test mimpid
    __test_mimpid:
    li      x10, 0xFFFFFFFF
    csrrw   x10, mimpid, x10
    li      x11, 1              // expected value
    call    check
    csrr    x10, mimpid
    call    check
    // test mstatus(h)
    __test_mstatus:
    addi    sp, sp, -8
    csrr    x11, mstatush       // save values
    li      x10, 0x20
    csrc    mstatush, x10       // ensure little-endian data access
    csrr    x10, mstatus
    sw      x10, 4(sp)
    sw      x11, 0(sp)
    __test_mstatus_1s:
    li      x10, 0xFFFFFFFF
    csrw    mstatus, x10
    csrw    mstatush, x10
    csrr    x10, mstatus
    li      x11, 0x000218EA     // MPRV, MPP, MPIE, UBE, SPIE, MIE, SIE bits set
    call    check
    csrr    x10, mstatush
    li      x11, 0x20           // MBE bit set
    call    check
    __test_mstatus_0s:
    csrw    mstatus, 0
    csrw    mstatush, 0
    csrr    x10, mstatus
    li      x11, 0x22           // SPIE & SIE bits set
    call    check
    csrr    x10, mstatush
    li      x11, 0              // no bits set
    call    check
    __end_test_mstatus:
    li      x10, 0x20
    csrc    mstatush, x10       // ensure little-endian data access
    lw      x10, 4(sp)
    lw      x11, 0(sp)
    csrw    mstatus, x10        // restore value
    csrw    mstatush, x11
    addi    sp, sp, 8
    // test mcycle(h)
    __test_mcycle:
    addi    sp, sp, -4
    csrr    x10, mcountinhibit  // save value
    sw      x10, 0(sp)
    csrw    mcountinhibit, 0    // ensure counter is not inhibited
    __test_mcycle_set:
    csrw    mcycle, 0
    csrr    x10, mcycle
    li      x11, 0
    call    check
    __test_mcycle_inc:
    csrr    x10, mcycle
    nop
    nop
    nop
    csrr    x11, mcycle
    addi    x11, x11, -4
    call    check
    __test_mcycle_overflow:
    li      x10, -1
    csrw    mcycleh, 1
    csrw    mcycle, x10
    nop
    nop
    csrr    x10, mcycle
    li      x11, 8
    bgt     x10, x11, +8
    mv      x11, x10
    call    check
    csrr    x10, mcycleh
    li      x11, 2
    call    check
    __test_cycle:
    csrw    mcycle, 0
    csrr    x10, cycle
    li      x11, 0
    call    check
    csrw    mcycle, 0
    nop
    nop
    csrr    x10, cycle
    li      x11, 2
    call    check
    __end_test_mcycle:
    lw      x10, 0(sp)
    csrw    mcountinhibit, x10  // restore value
    addi    sp, sp, 4
    __test_mtvec_rw:
    li      x11, 0xFFAA5501
    csrrw   x12, mtvec, x11
    csrr    x10, mtvec
    call    check
    csrw    mtvec, x12
    li      x12, 12
    __test_mip_rw:
    li      x10, 0x0000FFFF
    csrr    x12, mip            // save value
    and     x10, x10, x12       // get bits 15:0
    li      x11, 0xFFAA0000
    or      x10, x10, x11       // build expected value
    li      x11, 0xFFAA55FF
    csrw    mip, x11
    csrr    x11, mip
    call    check
    csrw    mip, x12            // restore value
    li      x12, 12
    __test_mie_rw:
    li      x11, 0xFFAA55FF
    csrrw   x12, mie, x11       // save value, write new value
    csrr    x10, mie
    li      x11, 0xFFAA0080     // only MTIE is writable in 15:0
    call    check
    mv      x11, x0
    csrw    mie, 0
    csrr    x10, mie
    call    check
    csrw    mie, x12            // restore value
    li      x12, 12
    __test_mepc_rw:
    li      x11, 0xAAFF55FF
    csrrw   x12, mepc, x11      // save value, write new value
    csrr    x10, mepc
    li      x11, 0xAAFF55FC     // lowest 2 bits are read-only zero
    call    check
    mv      x11, x0
    csrw    mepc, 0
    csrr    x10, mepc
    call    check
    csrw    mepc, x12           // restore value
    li      x12, 12
    __test_mcause_rw:
    li      x11, 0x55AAFF55
    csrrw   x12, mcause, x11    // save value, write new value
    csrr    x10, mcause
    call    check
    mv      x11, x0
    csrw    mcause, 0
    csrr    x10, mcause
    call    check
    csrw    mcause, x12         // restore value
    li      x12, 12
    __test_mtval_rw:
    li      x11, 0xFAA5500F
    csrrw   x12, mtval, x11     // save value, write new value
    csrr    x10, mtval
    call    check
    mv      x11, x0
    csrw    mtval, 0
    csrr    x10, mtval
    call    check
    csrw    mtval, x12          // restore value
    li      x12, 12

    // Exception Tests
    __test_ex:
    addi    sp, sp, -4
    la      x10, exception_isr
    csrw    mtvec, x10          // set new interrupt handler
    __test_ex_inst_misaligned_jalr:
    // check mepc
    auipc   x10, 0
    addi    x10, x10, 10
    jr      x10                 // inst misaligned exception
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check mtval
    addi    x11, x11, -2
    csrr    x10, mtval
    call    check
    // check mcause
    li      x11, 0
    csrr    x10, mcause
    call    check
    __test_ex_inst_misaligned_beq:
    beq     x0, x0, (__test_ex_inst_misaligned_beq + 2) // inst misaligned exception
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    __test_ex_inst_misaligned_bne:
    bne     x0, x0, (__test_ex_inst_misaligned_bne + 2) // no exception
    nop
    csrr    x10, mepc           // mepc should be unchanged
    call    check
    __test_ex_inst_access_fault_reserved:
    // check mepc
    li      x11, 0x80000000     // reserved address space
    auipc   x10, 0
    add     x10, x10, 12        // pass trap-return address
    jr      x11                 // inst access fault exception
    nop
    li      x11, 0x80000000
    call    check               // x10 is set to mepc when exception traps
    // check mtval
    csrr    x10, mtval
    call    check
    // check mcause
    li      x11, 1
    csrr    x10, mcause
    call    check
    __test_ex_inst_access_fault_ram:
    mv      x11, sp             // RAM address
    auipc   x10, 0
    addi    x10, x10, 12        // pass trap-return address
    jr      x11                 // inst access fault exception
    nop
    mv      x11, sp
    call    check               // x10 is set to mepc when exception traps
    __test_ex_illegal_inst:
    // check mepc
    .word   0x00000000          // illegal instruction (zeros)
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check mepc
    .word   0x3020007F          // illegal instruction (MRET, but incorrect opcode)
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check mtval
    lw      x11, -4(x11)
    csrr    x10, mtval
    call    check
    // check mcause
    li      x11, 2
    csrr    x10, mcause
    call    check
    __test_ex_breakpoint:
    // check mepc
    ebreak                      // breakpoint exception
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check mcause
    li      x11, 3
    csrr    x10, mcause
    call    check
    __test_ex_load_misaligned:
    // check mepc
    li      x11, -1
    sw      x11, 0(sp)
    lw      x12, 3(sp)          // load address misaligned exception
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check destination register
    li      x11, 12
    mv      x10, x12
    call    check
    // check mtval
    addi    x11, sp, 3
    csrr    x10, mtval
    call    check
    // check mcause
    li      x11, 4
    csrr    x10, mcause
    call    check
    __test_ex_load_access_fault:
    // check mepc
    li      x11, 0x80000000     // reserved address space
    lw      x12, 0(x11)         // load access fault exception
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check destination register
    li      x11, 12
    mv      x10, x12
    call    check
    // check mtval
    li      x11, 0x80000000
    csrr    x10, mtval
    call    check
    // check mcause
    li      x11, 5
    csrr    x10, mcause
    call    check
    __test_ex_store_misaligned:
    // check mepc
    sw      zero, 0(sp)
    li      x11, -1
    sw      x11, 3(sp)          // store address misaligned exception
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check write address
    li      x11, 0
    lw      x10, 0(sp)
    call    check
    // check mtval
    addi    x11, sp, 3
    csrr    x10, mtval
    // check mcause
    li      x11, 6
    csrr    x10, mcause
    __test_ex_store_access_fault:
    // check mepc
    auipc   x11, 0              // read-only ROM address
    sw      zero, 0(x11)        // store access fault exception
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check mtval
    la      x11, __test_ex_store_access_fault
    csrr    x10, mtval
    call    check
    // check mcause
    li      x11, 7
    csrr    x10, mcause
    call    check
    __test_ex_ecall_mmode:
    // check mepc
    ecall                       // environment call from M-mode exception
    auipc   x11, 0
    csrr    x10, mepc
    call    check
    // check mtval
    li      x11, 0
    csrr    x10, mtval
    call    check
    // check mcause
    li      x11, 11
    csrr    x10, mcause
    call    check
    __end_test_ex:
    addi    sp, sp, 4

    // Simple interrupt test
    __test_interrupt_begin:
    la      x10, trap_vector_table
    csrw    mtvec, x10          // set trap vector table
    csrs    mtvec, 1            // enable vectored mode
    csrw    mip, x0             // clear pending interrupts
    csrw    mie, x0             // disable all interrupts
    csrsi   mstatus, 0x8        // enable global machine-mode interrupts
    __test_interrupt_31:
    li      x11, 1
    sll     x11, x11, 31        // unused interrupt source
    csrw    mie, x11            // enable interrupt
    csrw    mip, x11            // trigger interrupt
    nop
    auipc   x11, 0
    // check mepc
    csrr    x10, mepc
    call    check
    // check mtval
    li      x11, 0
    csrr    x10, mtval
    call    check
    // check mcause
    li      x11, 0x80000000     // mcause interrupt bit
    or      x11, x11, 31        // interrupt cause
    csrr    x10, mcause
    call    check
    __test_interrupt_end:
    csrw    mie, x0             // disable all interrupts
    csrci   mstatus, 0x8        // disable global machine-mode interrupts


    // Test User Mode
    __test_umode_begin:
    la      x10, umode_handler
    csrw    mtvec, x10          // set trap handler
    la      x10, __test_umode_csr
    csrw    mepc, x10           // umode function address
    li      x11, 0x00001800     // MPP mask for mstatus
    csrc    mstatus, x11        // set previous privilege to umode
    mret                        // enter user mode
    __test_umode_csr:
    li      x11, -1
    mv      x10, x11
    csrr    x10, mstatus        // unprivileged access
    call    check               // x10 should be unchanged
    __test_umode_end:
    ecall                       // return to machine mode


    // FENCE, MRET, and WFI are not explicitly tested


    // Memory misaligned handler tests
    __test_misaligned:
    // initialize misaligned memory test
    lw      x10, 0(sp)          // re-load main vector table
    csrw    mtvec, x10
    // initialize memory
    addi    sp, sp, -8          // allocate 2 words on the stack
    li      x10, 0x76543210
    li      x11, 0xFEDCBA98
    sw      x10, 0(sp)
    sw      x11, 4(sp)
    __test_lw_misaligned_1:
    lw      x10, 1(sp)
    li      x11, 0x98765432
    call    check
    __test_lw_misaligned_2:
    lw      x10, 2(sp)
    li      x11, 0xBA987654
    call    check
    __test_lw_misaligned_3:
    lw      x10, 3(sp)
    li      x11, 0xDCBA9876
    call    check
    __test_lh_misaligned_1:
    lh      x10, 5(sp)
    li      x11, 0xFFFFDCBA
    call    check
    __test_lh_misaligned_2:
    lh      x10, 2(sp)
    li      x11, 0x00007654
    call    check
    __test_lh_misaligned_3:
    lh      x10, 3(sp)
    li      x11, 0xFFFF9876
    call    check
    __test_lhu_misaligned_3:
    lhu     x10, 3(sp)
    li      x11, 0x00009876
    call    check
    __test_lb_misaligned_1:
    lb      x10, 5(sp)
    li      x11, 0xFFFFFFBA
    call    check
    __test_lb_misaligned_2:
    lb      x10, 2(sp)
    li      x11, 0x00000054
    call    check
    __test_lb_misaligned_3:
    lb      x10, 7(sp)
    li      x11, 0xFFFFFFFE
    call    check
    __test_lbu_misaligned_1:
    lbu     x10, 5(sp)
    li      x11, 0x000000BA
    call    check
    __test_sw_misaligned_1:
    li      x11, 0xC001CAFE
    sw      x11, 1(sp)
    lw      x10, 1(sp)
    call    check
    lw      x10, 0(sp)
    li      x11, 0x01CAFE10
    call    check
    __test_sw_misaligned_2:
    li      x11, 0xBAADB002
    sw      x11, 2(sp)
    lw      x10, 2(sp)
    call    check
    lw      x10, 4(sp)
    li      x11, 0xFEDCBAAD
    call    check
    __test_sw_misaligned_3:
    li      x11, 0xFA180F4F
    sw      x11, 3(sp)
    lw      x10, 3(sp)
    call    check
    lw      x10, 4(sp)
    li      x11, 0xFEFA180F
    __test_sh_misaligned_1:
    sw      zero, 0(sp)
    li      x11, 0xFFFF1234
    sh      x11, 1(sp)
    lw      x10, 0(sp)
    li      x11, 0x00123400
    call    check
    __test_sh_misaligned_2:
    sw      zero, 4(sp)
    li      x11, 0xEFDA3301
    sh      x11, 2(sp)
    lw      x10, 0(sp)
    li      x11, 0x33013400
    call    check
    lw      x10, 4(sp)
    mv      x11, zero
    call    check
    __test_sh_misaligned_3:
    li      x11, 0xBAADF00D
    sh      x11, 3(sp)
    lw      x10, 0(sp)
    li      x11, 0x0D013400
    call    check
    lw      x10, 4(sp)
    li      x11, 0x000000F0
    call    check
    __test_sb_misaligned_1:
    sw      zero, 4(sp)
    li      x11, 0xFFFFFF77
    sb      x11, 1(sp)
    lw      x10, 0(sp)
    li      x11, 0x0d017700
    call    check
    __test_sb_misaligned_2:
    li      x11, 0xFFFFFF99
    sb      x11, 2(sp)
    lw      x10, 0(sp)
    li      x11, 0x0d997700
    call    check
    __test_sb_misaligned_3:
    li      x11, 0xFFFFFFAD
    sb      x11, 3(sp)
    lw      x10, 0(sp)
    li      x11, 0xAD997700
    call    check
    lw      x10, 4(sp)
    mv      x11, zero
    call    check
    __test_misaligned_end:
    addi    sp, sp, 8
    // de-initialize misaligned memory test


    __test_done:
    // finally test that all registers are correct (except x1, x2, x10, & x11)
    li      x10, 10
    li      x11, 11
    call    check_all
    lw      ra, 0(sp)       // pop mtvec
    csrw    mtvec, ra
    lw      ra, 4(sp)       // pop mscratch
    csrw    mscratch, ra
    lw      ra, 8(sp)       // pop return address
    addi    sp, sp, 12
    ret




// Check values function
check: // void check(int test_value, int correct_value)
    csrw    mscratch, 0
    nop
    fence
    ret


// Done trap
done:
    li      x10, 0x0D15EA5E
    csrw    mscratch, x10
    nop
    fence
    __dead_loop:
    j       __dead_loop


// Trap Vector Table
.balign 128
trap_vector_table:
    j       exception_isr       // 0: non-maskable interrupt / exceptions
    j       ssi_isr             // 1: supervisor-mode software interrupt
    j       default_isr         // 2: reserved
    j       msi_isr             // 3: machine-mode software interrupt
    j       default_isr         // 4: reserved
    j       sti_isr             // 5: supervisor-mode timer interrupt
    j       default_isr         // 6: reserved
    j       mti_isr             // 7: machine-mode timer interrupt
    j       default_isr         // 8: reserved
    j       sei_isr             // 9: supervisor-mode external interrupt
    j       default_isr         // 10: reserved
    j       mei_isr             // 11: machine-mode external interrupt
    j       default_isr         // 12: reserved
    j       default_isr         // 13: reserved
    j       default_isr         // 14: reserved
    j       default_isr         // 15: reserved
    j       uart0rx_isr         // 16: UART0 RX interrupt
    j       uart0tx_isr         // 17: UART0 TX interrupt
    j       tim0_isr            // 18: general-purpose timer 0 interrupt
    j       tim1_isr            // 19: general-purpose timer 1 interrupt
    j       gpioa0_isr          // 20: GPIOA interrupt 0
    j       gpioa1_isr          // 21: GPIOA interrupt 1
    j       gpiob0_isr          // 22: GPIOB interrupt 0
    j       gpiob1_isr          // 23: GPIOB interrupt 1
    j       gpioc0_isr          // 24: GPIOC interrupt 0
    j       gpioc1_isr          // 25: GPIOC interrupt 1
    j       default_isr         // 26: reserved
    j       default_isr         // 27: reserved
    j       default_isr         // 28: reserved
    j       default_isr         // 29: reserved
    j       default_isr         // 30: reserved
    j       default_isr         // 31: reserved


ssi_isr:
msi_isr:
sti_isr:
mti_isr:
sei_isr:
mei_isr:
uart0rx_isr:
uart0tx_isr:
tim0_isr:
tim1_isr:
gpioa0_isr:
gpioa1_isr:
gpiob0_isr:
gpiob1_isr:
gpioc0_isr:
gpioc1_isr:
default_isr:
    csrw    mip, 0              // clear all interrupts
    mret


// Exception handler for testing
exception_isr: // sets x10 to mepc, trap-return to mepc+4
    csrr    x11, mcause
    addi    x11, x11, -1 // mcause = 1: inst access fault
    beq     x11, x0, test_ex_isr_inst_access_fault
    csrr    x10, mepc
    addi    x10, x10, 4
    csrrw   x10, mepc, x10
    mret
test_ex_isr_inst_access_fault: // sets x10 to mepc, trap-return to x10 argument
    csrrw   x10, mepc, x10
    mret


// User Mode tests trap handler
umode_handler:
    addi    sp, sp, -8
    sw      x10, 0(sp)
    sw      x11, 4(sp)
    csrr    x10, mcause
    blt     x10, x0, umode_isr
    li      x11, 8              // ECALL from umode trap code
    beq     x10, x11, ecall_from_umode_handler
umode_ex_handler:
    csrr    x10, mepc           // return to next instruction
    addi    x10, x10, 4
    csrw    mepc, x10
    j       umode_handler_exit
umode_isr:
    j       umode_handler_exit
ecall_from_umode_handler:
    li      x10, 0x00001800     // MPP mask for mstatus
    csrs    mstatus, x10        // set previous privilege to mmode
    j       umode_handler_exit
umode_handler_exit:
    lw      x10, 0(sp)
    lw      x11, 4(sp)
    addi    sp, sp, 8
    mret


// Initialize registers function
init_regs:
    //li      x0, 0     // hardwired to zero
    //li      x1, 1     // link register
    //li      x2, 2     // stack pointer
    li      x3, 3
    li      x4, 4
    li      x5, 5
    li      x6, 6
    li      x7, 7
    li      x8, 8
    li      x9, 9
    li      x10, 10
    li      x11, 11
    li      x12, 12
    li      x13, 13
    li      x14, 14
    li      x15, 15
    li      x16, 16
    li      x17, 17
    li      x18, 18
    li      x19, 19
    li      x20, 20
    li      x21, 21
    li      x22, 22
    li      x23, 23
    li      x24, 24
    li      x25, 25
    li      x26, 26
    li      x27, 27
    li      x28, 28
    li      x29, 29
    li      x30, 30
    li      x31, 31
    ret


// Check all registers are their initialized values (except x1 and x2)
check_all:
    addi    sp, sp, -4
    sw      ra, 0(sp)   // push return address to stack
    li      x1, 1
    //bne     x1, x1, __check_all_fail      // link register
    addi    x1, x1, 1
    //bne     x2, x1, __check_all_fail      // stack pointer
    addi    x1, x1, 1
    bne     x3, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x4, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x5, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x6, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x7, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x8, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x9, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x10, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x11, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x12, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x13, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x14, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x15, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x16, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x17, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x18, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x19, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x20, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x21, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x22, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x23, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x24, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x25, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x26, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x27, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x28, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x29, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x30, x1, __check_all_fail
    addi    x1, x1, 1
    bne     x31, x1, __check_all_fail
    lw      ra, 0(sp)   // pull return address from stack
    addi    sp, sp, 4
    ret
__check_all_fail:
    mv      x10, x1
    lw      ra, 0(sp)   // pull return address from stack
    addi    sp, sp, 4
    csrw    mscratch, 1
    fence
    ret
