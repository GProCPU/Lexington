
.file "startup_lexington.S"
.section .text.startup
.balign 4
.global _start
.global __startup_entry
.global __startup_main_exit


_start:
__startup_entry:
.cfi_startproc
.cfi_undefined ra

//csrrwi  zero, mstatus, 0 // clear mstatus; disable machine-level interrupts


// Setup CPU CSRs
__startup_csr_init:
    csrw    mie, zero                       // disable all interrupt sources
    la      x1, __startup_trap_handler      // configure early-boot trap handler
    csrw    mtvec, x1


// Initialize stack pointer
__startup_pointer_init:
    .option push
    .option norelax
    la      sp, __Lexington_stack_begin  // stack pointer
    .option pop


// Copy initialized data from ROM to RAM
__startup_copy_data:
    la      x11, __Lexington_copy_data_src_begin
    la      x12, __Lexington_copy_data_dest_begin
    la      x13, __Lexington_copy_data_dest_end
    beq     x11, x12, __startup_copy_data_loop_end  // do nothing if source and destination are same
__startup_copy_data_loop:
    bge     x12, x13, __startup_copy_data_loop_end
    lw      x14, 0(x11)
    sw      x14, 0(x12)
    addi    x11, x11, 4
    addi    x12, x12, 4
    j       __startup_copy_data_loop
__startup_copy_data_loop_end:


// Clear .bss sections
__startup_clear_bss:
    la      x14, __Lexington_bss_start
    la      x15, __Lexington_bss_end
__startup_clear_bss_loop:
    bge     x14, x15, __startup_clear_bss_loop_end
    sw      zero, 0(x14)
    addi    x14, x14, 4
    j       __startup_clear_bss_loop
__startup_clear_bss_loop_end:


// Call constructors
__startup_call_constructors:
    la      x8, __init_array_start
    la      x9, __init_array_end
__startup_call_constructors_loop:
    bge     x8, x9, __startup_call_constructors_loop_end
    lw      x1, 0(x8)
    jalr    x1, 0(x1)
    addi    x8, x8, 4
    j       __startup_call_constructors_loop
__startup_call_constructors_loop_end:


// Init main trap handler
__startup_init_main_trap_handler:
    csrw    mie, zero                       // disable all interrupt sources
    csrs    mstatus, 0x4                    // enable m-mode global interrupts
    la      x1, __INTERRUPT_VECTOR_TABLE    // trap vector table
    addi    x1, x1, 1                       // set vectored addressing mode
    csrw    mtvec, x1                       // apply main trap handler


// Call main function
__startup_main_entry:
    addi    x10, zero, 0    // x10 = a0 = argc = 0
    addi    x11, zero, 0    // x11 = a1 = argv = 0
    jal     x1, main        // call application main
__startup_main_exit:
    // return or exit from main goes here
    csrw    mie, zero       // disable all interrupts
    csrw    mscratch, a0    // backup main's return code for debugger


// Call destructors
__startup_call_destructors:
    la      x8, __fini_array_start
    la      x9, __fini_array_end
__startup_call_destructors_loop:
    bge     x8, x9, __startup_call_destructors_loop_end
    lw      x1, 0(x8)
    jalr    x1, 0(x1)
    addi    x8, x8, 4
    j       __startup_call_destructors_loop
__startup_call_destructors_loop_end:


// Endless sleep
__startup_shutdown:
    wfi
    j       __startup_shutdown


// Dummy trap handler for startup stage. Try to move to next instruction
.balign 4
__startup_trap_handler:
    addi    sp, sp, -8
    sw      x8, 0(sp)
    sw      x9, 4(sp)
    csrr    x8, mcause
    blt     x8, zero, __startup_trap_handler_end  // skip mepc modification if interrupt
    // increment mepc
    csrr    x8, mepc
    addi    x8, x8, +4
    csrw    mepc, x8
__startup_trap_handler_end:
    lw      x8, 0(sp)
    lw      x9, 4(sp)
    addi    sp, sp, +8
    mret




//////////////////////////////////////////////////
//////////////////////////////////////////////////
// BEGIN: Trap handlers (vectored mode only)
//////////////////////////////////////////////////

// Interrupt Vector Table
.balign 128
__INTERRUPT_VECTOR_TABLE:
    .weak   __INTERRUPT_VECTOR_TABLE
    j       __FIRST_LEVEL_TRAP_HANDLER          // 0: non-maskable interrupt / exceptions
    j       __SSI_HANDLER                       // 1: supervisor-mode software interrupt
    j       __DEFAULT_INT_HANDLER               // 2: reserved
    j       __MSI_HANDLER                       // 3: machine-mode software interrupt
    j       __DEFAULT_INT_HANDLER               // 4: reserved
    j       __STI_HANDLER                       // 5: supervisor-mode timer interrupt
    j       __DEFAULT_INT_HANDLER               // 6: reserved
    j       __MTI_HANDLER                       // 7: machine-mode timer interrupt
    j       __DEFAULT_INT_HANDLER               // 8: reserved
    j       __SEI_HANDLER                       // 9: supervisor-mode external interrupt
    j       __DEFAULT_INT_HANDLER               // 10: reserved
    j       __MEI_HANDLER                       // 11: machine-mode external interrupt
    j       __DEFAULT_INT_HANDLER               // 12: reserved
    j       __DEFAULT_INT_HANDLER               // 13: reserved
    j       __DEFAULT_INT_HANDLER               // 14: reserved
    j       __DEFAULT_INT_HANDLER               // 15: reserved
    j       __UART0RX_HANDLER                   // 16: UART0 RX interrupt
    j       __UART0TX_HANDLER                   // 17: UART0 TX interrupt
    j       __TIM0_HANDLER                      // 18: general-purpose timer 0 interrupt
    j       __TIM1_HANDLER                      // 19: general-purpose timer 1 interrupt
    j       __GPIOA0_HANDLER                    // 20: GPIOA interrupt 0
    j       __GPIOA1_HANDLER                    // 21: GPIOA interrupt 1
    j       __GPIOB0_HANDLER                    // 22: GPIOB interrupt 0
    j       __GPIOB1_HANDLER                    // 23: GPIOB interrupt 1
    j       __GPIOC0_HANDLER                    // 24: GPIOC interrupt 0
    j       __GPIOC1_HANDLER                    // 25: GPIOC interrupt 1
    j       __DEFAULT_INT_HANDLER               // 26: reserved
    j       __DEFAULT_INT_HANDLER               // 27: reserved
    j       __DEFAULT_INT_HANDLER               // 28: reserved
    j       __DEFAULT_INT_HANDLER               // 29: reserved
    j       __DEFAULT_INT_HANDLER               // 30: reserved
    j       __DEFAULT_INT_HANDLER               // 31: reserved

// Exception Vector Table
.balign 4
__EXCEPTION_VECTOR_TABLE:
    .weak   __EXCEPTION_VECTOR_TABLE
    j       __INST_MISALIGNED_HANDLER           // 0
    j       __INST_ACCESS_FAULT_HANDLER         // 1
    j       __ILLEGAL_INST_HANDLER              // 2
    j       __BREAKPOINT_HANDLER                // 3
    j       __LOAD_MISALIGNED_HANDLER           // 4
    j       __LOAD_ACCESS_FAULT_HANDLER         // 5
    j       __STORE_MISALIGNED_HANDLER          // 6
    j       __STORE_ACCESS_FAULT_HANDLER        // 7
    j       __ECALL_UMODE_HANDLER               // 8
    j       __ECALL_SMODE_HANDLER               // 9
    j       __UNKNOWN_EX_HANDLER                // 10
    j       __ECALL_MMODE_HANDLER               // 11
    j       __INST_PAGE_FAULT_HANDLER           // 12
    j       __LOAD_PAGE_FAULT_HANDLER           // 13
    j       __STORE_PAGE_FAULT_HANDLER          // 14


// First-level trap handler (vectored mode only)
__FIRST_LEVEL_TRAP_HANDLER:
    addi    sp, sp, -8          // save registers (must be restored by ex handler)
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    csrr    t0, mcause          // get trap cause
    blt     t0, zero, __UNKNOWN_EX_HANDLER // interrupts (i.e. direct mode) not supported by this handler
    sll     t0, t0, 2           // prep exception vector offset
    la      t1, __EXCEPTION_VECTOR_TABLE
    add     t0, t0, t1          // calculate jump address
    jr      t0                  // jump to exception handler


// Misaligned data access handling
__LOAD_MISALIGNED_HANDLER:      // trap code 4
    .weak   __LOAD_MISALIGNED_HANDLER
    j       .
    # lw      t0, 0(sp)           // restore registers
    # lw      t1, 4(sp)
    # addi    sp, sp, 8
    # mret                        // return from trap

__STORE_MISALIGNED_HANDLER:     // trap code 6
    .weak   __STORE_MISALIGNED_HANDLER
    j       .
    # lw      t0, 0(sp)           // restore registers
    # lw      t1, 4(sp)
    # addi    sp, sp, 8
    # mret                        // return from trap


// Dummy second-level exception handler
__INST_MISALIGNED_HANDLER:          // 0
__INST_ACCESS_FAULT_HANDLER:        // 1
__ILLEGAL_INST_HANDLER:             // 2
__BREAKPOINT_HANDLER:               // 3
__LOAD_ACCESS_FAULT_HANDLER:        // 5
__STORE_ACCESS_FAULT_HANDLER:       // 7
__ECALL_UMODE_HANDLER:              // 8
__ECALL_SMODE_HANDLER:              // 9
__ECALL_MMODE_HANDLER:              // 11
__INST_PAGE_FAULT_HANDLER:          // 12
__LOAD_PAGE_FAULT_HANDLER:          // 13
__STORE_PAGE_FAULT_HANDLER:         // 14
__UNKNOWN_EX_HANDLER:
    .weak   __INST_MISALIGNED_HANDLER
    .weak   __INST_ACCESS_FAULT_HANDLER
    .weak   __ILLEGAL_INST_HANDLER
    .weak   __BREAKPOINT_HANDLER
    .weak   __LOAD_ACCESS_FAULT_HANDLER
    .weak   __STORE_ACCESS_FAULT_HANDLER
    .weak   __ECALL_UMODE_HANDLER
    .weak   __ECALL_SMODE_HANDLER
    .weak   __ECALL_MMODE_HANDLER
    .weak   __INST_PAGE_FAULT_HANDLER
    .weak   __LOAD_PAGE_FAULT_HANDLER
    .weak   __STORE_PAGE_FAULT_HANDLER
    .weak   __UNKNOWN_EX_HANDLER
__DEFAULT_EX_HANDLER:
    // dead loop
    j       .


// Dummy interrupt handler
__SSI_HANDLER:          // 1
__MSI_HANDLER:          // 3
__STI_HANDLER:          // 5
__MTI_HANDLER:          // 7
__SEI_HANDLER:          // 9
__MEI_HANDLER:          // 11
__UART0RX_HANDLER:      // 16
__UART0TX_HANDLER:      // 17
__TIM0_HANDLER:         // 18
__TIM1_HANDLER:         // 19
__GPIOA0_HANDLER:       // 20
__GPIOA1_HANDLER:       // 21
__GPIOB0_HANDLER:       // 22
__GPIOB1_HANDLER:       // 23
__GPIOC0_HANDLER:       // 24
__GPIOC1_HANDLER:       // 25
    .weak   __SSI_HANDLER
    .weak   __MSI_HANDLER
    .weak   __STI_HANDLER
    .weak   __MTI_HANDLER
    .weak   __SEI_HANDLER
    .weak   __MEI_HANDLER
    .weak   __UART0RX_HANDLER
    .weak   __UART0TX_HANDLER
    .weak   __TIM0_HANDLER
    .weak   __TIM1_HANDLER
    .weak   __GPIOA0_HANDLER
    .weak   __GPIOA1_HANDLER
    .weak   __GPIOB0_HANDLER
    .weak   __GPIOB1_HANDLER
    .weak   __GPIOC0_HANDLER
    .weak   __GPIOC1_HANDLER
// Dummy interrupt handler (vectored-mode only)
__DEFAULT_INT_HANDLER:
    // disables interrupt source in mie CSR
    addi    sp, sp, -8      // save 2 temporary registers to stack
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    csrr    t0, mcause      // get interrupt cause
    slli    t0, t0, 1
    srli    t0, t0, 1       // clear trap code MSB (interrupt bit)
    li      t1, 1
    sll     t1, t1, t0      // create mask for interrupt cause
    csrc    mie, t1         // disable interrupt cause
    lw      t0, 0(sp)       // restore registers
    lw      t0, 4(sp)
    addi    sp, sp, 8
    mret                    // exit trap handler


.cfi_endproc
.end
