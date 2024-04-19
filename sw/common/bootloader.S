.file "bootloader.S"
.section .text.bootloader
.balign 4
.global __bootloader_entry


.cfi_startproc
.cfi_undefined ra


__bootloader_entry:
    la      a0, header_msg
    call    print_str
    la      a0, 0xFFFFFF80      // UART0 base address
    // Flush UART0 RX
__bootloader_entry_flush_rx:
    lw      t0, 4(a0)           // Read UART0 conf register
    andi    t0, t0, 0x8         // isolate RX empty flag
    beq     zero, t0, __bootloader_entry_flush_rx
    // Read 32-bit program size (little-endian)
    li      s0, 0               // size
    li      s1, 0               // loop/shift counter
    li      s2, 32              // loop condition
__bootloader_entry_size_loop:
    call    uart_rx             // read byte
    sll     a0, a0, s1          // shift byte
    or      s0, s0, a0          // append byte
    addi    s1, s1, 8
    blt     s1, s2, __bootloader_entry_size_loop
    la      t0, __Lexington_rom_size
    bgt     s0, t0, __bootloader_entry_too_big

    la      s1, __Lexington_imem_begin  // data pointer
    add     s2, s1, s0                  // data end pointer
    la      s3, __Lexington_bootloader_end
__bootloader_entry_ignore_loop:
    bge     s1, s3, __bootloader_entry_data_loop
    call    uart_rx             // read byte
    addi    s1, s1, 1           // increment data pointer
    j       __bootloader_entry_ignore_loop
__bootloader_entry_data_loop:
    call    uart_rx             // read byte
    sw      a0, 0(s1)           // write byte
    addi    s1, s1, 1           // increment data pointer
    blt     s1, s2, __bootloader_entry_data_loop
    la      a0, done_msg
    call    print_str
    j       _start

__bootloader_entry_too_big:
    la      a0, too_big_msg
    call    print_str
    j       .




uart_rx:
    li      t0, 0xFFFFFF80      // UART0 base address
__uart_rx_wait:
    lw      t1, 4(t0)           // Read UART0 conf register
    andi    t1, t1, 0x8         // isolate RX empty flag
    bne     zero, t1, __uart_rx_wait
    lbu     a0, 0(t0)           // Read byte from UART0
    ret


print_str:
    li      t0, 0xFFFFFF80      // UART0 base address
__print_str_loop:
    lbu     t1, 0(a0)           // load next byte
    beq     zero, t1, __print_str_exit // exit if null
__print_str_wait:
    lw      t2, 4(t0)           // Read UART0 conf register
    andi    t2, t2, 0x10        // isolate TX full flag
    bne     zero, t2, __print_str_wait
    sw      t1, 0(t0)           // Write byte to UART0
    addi    a0, a0, 1
    j       __print_str_loop
__print_str_exit:
    ret

header_msg:
    .string "GPro 1 Lexington Bootloader:\r\nReady to reprogram\r\n"
too_big_msg:
    .string "program size too large\r\n"
done_msg:
    .string "done\r\n"


.cfi_endproc
.end
