//depend sync.sv
//depend core/*.sv
`timescale 1ns/1ps

`include "rv32.sv"
`include "lexington.sv"
import lexington::*;


module core #(
        parameter ROM_ADDR_WIDTH    = DEFAULT_ROM_ADDR_WIDTH,       // ROM address width (word-addressable, default 4kB)
        parameter RAM_ADDR_WIDTH    = DEFAULT_RAM_ADDR_WIDTH,       // RAM address width (word-addressable, default 4kB)
        localparam MTIME_ADDR_WIDTH = 2,
        parameter AXI_ADDR_WIDTH    = DEFAULT_AXI_ADDR_WIDTH,       // AXI bus address space width (byte-addressable)
        parameter ROM_BASE_ADDR     = DEFAULT_ROM_BASE_ADDR,        // ROM base address (must be aligned to ROM size)
        parameter RAM_BASE_ADDR     = DEFAULT_RAM_BASE_ADDR,        // RAM base address (must be aligned to RAM size)
        parameter MTIME_BASE_ADDR   = DEFAULT_MTIME_BASE_ADDR,      // machine timer base address (see [CSR](./CSR.md))
        parameter AXI_BASE_ADDR     = DEFAULT_AXI_BASE_ADDR,        // AXI bus address space base (must be aligned to AXI address space)
        parameter RESET_ADDR        = DEFAULT_RESET_ADDR,           // program counter reset/boot address
        parameter HART_ID           = 0                             // hardware thread id (see mhartid CSR)
    ) (
        input  logic clk,                                           // global system clock
        input  logic rst_n,                                         // global reset, active-low

        // ROM ports
        output logic rom_rd_en1,                                    // IBus
        output logic [ROM_ADDR_WIDTH-1:0] rom_addr1,                // IBus
        input  rv32::word rom_rd_data1,                             // IBus
        output logic rom_rd_en2,                                    // DBus
        output logic [ROM_ADDR_WIDTH-1:0] rom_addr2,                // DBus
        input  rv32::word rom_rd_data2,                             // DBus

        // RAM ports
        output logic ram_rd_en,                                     // DBus
        output logic ram_wr_en,                                     // DBus
        output logic [RAM_ADDR_WIDTH-1:0] ram_addr,                 // DBus
        input  rv32::word ram_rd_data,                              // DBus

        // AXI port
        output logic axi_rd_en,                                     // DBus
        output logic axi_wr_en,                                     // DBus
        output logic [AXI_ADDR_WIDTH-1:0] axi_addr,                 // DBus
        input  rv32::word axi_rd_data,                              // DBus
        input  logic axi_access_fault,                              // DBus
        input  logic axi_busy,                                      // DBus

        output rv32::word wr_data,                                  // share write data
        output logic [(rv32::XLEN/8)-1:0] wr_strobe,                // share write strobe

        // Interrupt flags
        input  logic gpioa_int_0,                                   // GPIOA interrupt 0
        input  logic gpioa_int_1,                                   // GPIOA interrupt 1
        input  logic gpiob_int_0,                                   // GPIOA interrupt 0
        input  logic gpiob_int_1,                                   // GPIOA interrupt 1
        input  logic gpioc_int_0,                                   // GPIOA interrupt 0
        input  logic gpioc_int_1,                                   // GPIOA interrupt 1
        input  logic uart0_rx_int,                                  // UART0 RX interrupt
        input  logic uart0_tx_int,                                  // UART0 TX interrupt
        input  logic timer0_int,                                    // timer0 interrupt
        input  logic timer1_int                                     // timer1 interrupt
    );


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Internal Wires
    ////////////////////////////////////////////////////////////
    // IBus
    logic ibus_rd_en;
    rv32::word ibus_addr;
    rv32::word ibus_rd_data;
    rv32::word inst;
    // DBus
    logic dbus_rd_en;
    logic dbus_wr_en;
    rv32::word dbus_addr;
    rv32::word dbus_rd_data;
    rv32::word dbus_wr_data;
    logic [(rv32::XLEN/8)-1:0] dbus_wr_strobe;
    logic dbus_wait;
    logic dbus_err;
    // PC
    rv32::word pc;
    rv32::word next_pc;
    rv32::word decoder_next_pc;
    // Register File
    logic rs1_en;
    logic rs2_en;
    logic dest_en;
    rv32::gpr_addr_t rs1_addr;
    rv32::gpr_addr_t rs2_addr;
    rv32::gpr_addr_t dest_addr;
    rv32::word rs1_data;
    rv32::word rs2_data;
    rv32::word dest_data;
    // Decode/ALU/LSU
    rv32::word src1;
    rv32::word src2;
    rv32::word alt_data;
    rv32::word alu_result;
    alu_op_t alu_op;
    lsu_op_t lsu_op;
    logic alu_zero;
    // CSR
    rv32::priv_mode_t priv;
    logic csr_rd_en;
    logic csr_explicit_rd;
    logic csr_wr_en;
    rv32::csr_addr_t csr_addr;
    rv32::word csr_rd_data;
    rv32::word csr_wr_data;
    logic trap_rd_en;
    logic trap_wr_en;
    rv32::word trap_rd_data;
    // Control signals
    logic global_mie;
    logic endianness;
    logic mret;
    logic exception;
    logic trap;
    // Machine Timer
    logic mtime_rd_en;
    logic mtime_wr_en;
    logic [MTIME_ADDR_WIDTH-1:0] mtime_addr;
    rv32::word mtime_rd_data;
    logic [63:0] time_rd_data;  // unprivileged alias
    logic mtime_interrupt;
    // Exceptions
    logic inst_access_fault;
    logic inst_misaligned;
    logic data_access_fault;
    logic data_misaligned;
    logic load_store_n;
    logic illegal_inst;
    logic ecall;
    logic ebreak;
    logic illegal_csr;
    ////////////////////////////////////////////////////////////
    // END: Internal Wires
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Memory Bus Instantiations
    ////////////////////////////////////////////////////////////
    ibus #(
        .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH),
        .ROM_BASE_ADDR(ROM_BASE_ADDR)
    ) IBUS (
        .rd_en(ibus_rd_en),
        .addr(ibus_addr),
        .rom_rd_data(rom_rd_data1),
        .rom_rd_en(rom_rd_en1),
        .rom_addr(rom_addr1),
        .rd_data(ibus_rd_data),
        .inst_access_fault
    );
    dbus #(
        .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .ROM_BASE_ADDR(ROM_BASE_ADDR),
        .RAM_BASE_ADDR(RAM_BASE_ADDR),
        .MTIME_BASE_ADDR(MTIME_BASE_ADDR),
        .AXI_BASE_ADDR(AXI_BASE_ADDR)
    ) DBUS (
        .rd_en(dbus_rd_en),
        .wr_en(dbus_wr_en),
        .addr(dbus_addr),
        .wr_data_i(dbus_wr_data),
        .wr_strobe_i(dbus_wr_strobe),
        .rom_rd_data(rom_rd_data2),
        .ram_rd_data,
        .mtime_rd_data,
        .axi_rd_data,
        .axi_access_fault,
        .axi_busy,
        .rd_data(dbus_rd_data),
        .rom_rd_en(rom_rd_en2),
        .rom_addr(rom_addr2),
        .ram_rd_en,
        .ram_wr_en,
        .ram_addr,
        .mtime_rd_en,
        .mtime_wr_en,
        .mtime_addr,
        .axi_rd_en,
        .axi_wr_en,
        .axi_addr,
        .wr_data_o(wr_data),
        .wr_strobe_o(wr_strobe),
        .data_misaligned,
        .data_access_fault,
        .load_store_n,
        .dbus_wait,
        .dbus_err
    );
    ////////////////////////////////////////////////////////////
    // END: Memory Bus Instantiations
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: PC and Register File Instantiations
    ////////////////////////////////////////////////////////////
    pc PC (
        .clk,
        .rst_n,
        .next_pc,
        .pc
    );
    regfile REGFILE (
        .clk,
        .rs1_en,
        .rs2_en,
        .rs1_addr,
        .rs2_addr,
        .rs1_data,
        .rs2_data,
        .dest_en,
        .dest_addr,
        .dest_data
    );
        ////////////////////////////////////////////////////////////
    // END: PC and Register File Instantiations
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Fetch/Decoder/ALU/LSU Instantiations
    ////////////////////////////////////////////////////////////
    fetch Fetch_inst (
        .pc,
        .ibus_rd_en,
        .ibus_addr,
        .ibus_rd_data,
        .inst
        );
    decoder DECODER (
        .inst,
        .pc,
        .rs1_data,
        .rs2_data,
        .csr_rd_data,
        .alu_zero,
        .rs1_en,
        .rs2_en,
        .rs1_addr,
        .rs2_addr,
        .csr_rd_en,
        .csr_explicit_rd,
        .csr_addr,
        .src1,
        .src2,
        .alt_data,
        .alu_op,
        .lsu_op,
        .dest_addr,
        .next_pc(decoder_next_pc),
        .illegal_inst,
        .inst_misaligned,
        .ecall,
        .ebreak,
        .mret
    );
    alu ALU (
        .src1,
        .src2,
        .alu_op,
        .result(alu_result),
        .zero(alu_zero)
    );
    lsu LSU (
        .lsu_op,
        .alu_result,
        .alt_data,
        .dest_addr,
        .dbus_rd_data,
        .dbus_wait,
        .dbus_err,
        .endianness,
        .exception,
        .dest_en,
        .dest_data,
        .dbus_rd_en,
        .dbus_wr_en,
        .dbus_addr,
        .dbus_wr_data,
        .dbus_wr_strobe,
        .csr_wr_en,
        .csr_wr_data
    );
    ////////////////////////////////////////////////////////////
    // END: Fetch, Decoder, ALU, LSU, Register File Instantiations
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: CSR Instantiation
    ////////////////////////////////////////////////////////////
    csr #(
        .HART_ID(HART_ID)
    ) CSR (
        .clk,
        .rst_n,
        .rd_en(csr_rd_en),
        .explicit_rd(csr_explicit_rd),
        .wr_en(csr_wr_en),
        .addr(csr_addr),
        .rd_data(csr_rd_data),
        .wr_data(csr_wr_data),
        .trap_rd_en,
        .trap_wr_en,
        .trap_rd_data,
        .time_rd_data,
        .global_mie,
        .endianness,
        .illegal_csr,
        .dbus_wait,
        .mret,
        .trap,
        .exception,
        .priv
    );
    ////////////////////////////////////////////////////////////
    // END: CSR Instantiation
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Trap Unit Instantiation
    ////////////////////////////////////////////////////////////
    trap #(
        .RESET_ADDR(RESET_ADDR)
    ) TRAP (
        .clk,
        .rst_n,
        .pc,
        .decoder_next_pc,
        .global_mie,
        .csr_rd_en(trap_rd_en),
        .csr_wr_en(trap_wr_en),
        .csr_addr,
        .csr_wr_data,
        .mret,
        .dbus_wait,
        .inst_access_fault,
        .inst_misaligned,
        .illegal_inst,
        .illegal_csr,
        .inst,
        .ecall,
        .ebreak,
        .data_misaligned,
        .data_access_fault,
        .load_store_n,
        .data_addr(alu_result),
        .mtime_interrupt,
        .gpioa_int_0,
        .gpioa_int_1,
        .gpiob_int_0,
        .gpiob_int_1,
        .gpioc_int_0,
        .gpioc_int_1,
        .uart0_rx_int,
        .uart0_tx_int,
        .timer0_int,
        .timer1_int,
        .next_pc,
        .csr_rd_data(trap_rd_data),
        .exception,
        .trap,
        .priv
    );
    ////////////////////////////////////////////////////////////
    // END: Trap Unit Instantiation
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Machine Timer Instantiation
    ////////////////////////////////////////////////////////////
    mtime MTIME (
        .clk,
        .rst_n,
        .rd_en(mtime_rd_en),
        .wr_en(mtime_wr_en),
        .addr(mtime_addr),
        .wr_data,
        .wr_strobe,
        .rd_data(mtime_rd_data),
        .time_rd_data,
        .interrupt(mtime_interrupt)
    );
    ////////////////////////////////////////////////////////////
    // END: Machine Timer Instantiation
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

endmodule
