//depend sync.sv
//depend core.sv
//depend core/*.sv
//depend debug.sv
//depend mem/*.sv
//depend axi4_lite_manager.sv
//depend axi4_lite_crossbar8.sv
//depend peripheral/*.sv
`timescale 1ns/1ps

`include "rv32.sv"
`include "lexington.sv"
`include "axi4_lite.sv"
import lexington::*;


module soc #(
        parameter CLK_FREQ              = DEFAULT_CLK_FREQ,             // Core/bus frequency
        parameter UART0_BAUD            = DEFAULT_UART_BAUD,            // UART BAUD rate
        parameter UART0_FIFO_DEPTH      = DEFAULT_UART_FIFO_DEPTH       // FIFO depth for both TX and RX (depth 0 is invalid)
    ) (
        input  logic clk,                       // system clock
        input  logic pxclk,                     // VGA pixel clock
        input  logic rst_n,                     // reset signal (active-low)

        inout  logic [15:0] gpioa,
        inout  logic [15:0] gpiob,
        inout  logic [15:0] gpioc,
        input  logic uart0_rx,
        output logic uart0_tx,
        output logic [3:0] vga_r,
        output logic [3:0] vga_g,
        output logic [3:0] vga_b,
        output logic vga_hs,
        output logic vga_vs
    );

    // Core Parameters
    localparam ROM_ADDR_WIDTH       = DEFAULT_ROM_ADDR_WIDTH;       // ROM address width (word-addressable, default 4kB)
    localparam RAM_ADDR_WIDTH       = DEFAULT_RAM_ADDR_WIDTH;       // RAM address width (word-addressable, default 4kB)
    localparam AXI_ADDR_WIDTH       = DEFAULT_AXI_ADDR_WIDTH;       // AXI bus address space width (byte-addressable)
    localparam ROM_BASE_ADDR        = DEFAULT_ROM_BASE_ADDR;        // ROM base address (must be aligned to ROM size)
    localparam RAM_BASE_ADDR        = DEFAULT_RAM_BASE_ADDR;        // RAM base address (must be aligned to RAM size)
    localparam MTIME_BASE_ADDR      = DEFAULT_MTIME_BASE_ADDR;      // machine timer base address (see [CSR](./CSR.md))
    localparam AXI_BASE_ADDR        = DEFAULT_AXI_BASE_ADDR;        // AXI bus address space base (must be aligned to AXI address space)
    localparam AXI_TIMEOUT          = DEFAULT_AXI_TIMEOUT;          // AXI bus timeout in cycles
    localparam RESET_ADDR           = DEFAULT_RESET_ADDR;           // program counter reset/boot address


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Internal Wires
    ////////////////////////////////////////////////////////////
    // ROM ports
    logic rom_rd_en1;                                   // IBus
    logic [ROM_ADDR_WIDTH-1:0] rom_addr1;               // IBus
    rv32::word rom_rd_data1;                            // IBus
    logic rom_rd_en2;                                   // DBus
    logic rom_wr_en2;                                   // DBus
    logic [ROM_ADDR_WIDTH-1:0] rom_addr2;               // DBus
    rv32::word rom_rd_data2;                            // DBus
    // RAM ports
    logic ram_rd_en;                                    // DBus
    logic ram_wr_en;                                    // DBus
    logic [RAM_ADDR_WIDTH-1:0] ram_addr;                // DBus
    rv32::word ram_rd_data;                             // DBus
    // AXI Manager ports
    logic axi_rd_en;                                    // DBus
    logic axi_wr_en;                                    // DBus
    logic [AXI_ADDR_WIDTH-1:0] axi_addr;                // DBus
    rv32::word axi_rd_data;                             // DBus
    logic axi_access_fault;                             // DBus
    logic axi_busy;                                     // DBus
    rv32::word wr_data;                                 // shared write data
    logic [(rv32::XLEN/8)-1:0] wr_strobe;               // shared write strobe
    // Interrupt flags
    logic gpioa_int_0;                                  // GPIOA interrupt 0
    logic gpioa_int_1;                                  // GPIOA interrupt 1
    logic gpiob_int_0;                                  // GPIOA interrupt 0
    logic gpiob_int_1;                                  // GPIOA interrupt 1
    logic gpioc_int_0;                                  // GPIOA interrupt 0
    logic gpioc_int_1;                                  // GPIOA interrupt 1
    logic uart0_rx_int;                                 // UART0 RX interrupt
    logic uart0_tx_int;                                 // UART0 TX interrupt
    logic timer0_int;                                   // timer0 interrupt
    logic timer1_int;                                   // timer1 interrupt
    // AXI bus
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(AXI_ADDR_WIDTH)) axi_m();
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(GPIO_ADDR_WIDTH)) axi_gpioa();
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(GPIO_ADDR_WIDTH)) axi_gpiob();
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(GPIO_ADDR_WIDTH)) axi_gpioc();
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(UART_ADDR_WIDTH)) axi_uart0();
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(VGA_ADDR_WIDTH)) axi_vga();
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(1)) axi_s05(); // unused
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(1)) axi_s06(); // unused
    axi4_lite #(.WIDTH(rv32::XLEN), .ADDR_WIDTH(1)) axi_s07(); // unused
    ////////////////////////////////////////////////////////////
    // END: Internal Wires
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Core Instantiation
    ////////////////////////////////////////////////////////////
    core #(
        .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH),
        .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .ROM_BASE_ADDR(ROM_BASE_ADDR),
        .RAM_BASE_ADDR(RAM_BASE_ADDR),
        .MTIME_BASE_ADDR(MTIME_BASE_ADDR),
        .AXI_BASE_ADDR(AXI_BASE_ADDR),
        .RESET_ADDR(RESET_ADDR),
        .HART_ID(0)
    ) CORE0 (
        .clk,
        .rst_n,
        .rom_rd_en1,
        .rom_addr1,
        .rom_rd_data1,
        .rom_rd_en2,
        .rom_wr_en2,
        .rom_addr2,
        .rom_rd_data2,
        .ram_rd_en,
        .ram_wr_en,
        .ram_addr,
        .ram_rd_data,
        .axi_rd_en,
        .axi_wr_en,
        .axi_addr,
        .axi_rd_data,
        .axi_access_fault,
        .axi_busy,
        .wr_data,
        .wr_strobe,
        .gpioa_int_0,
        .gpioa_int_1,
        .gpiob_int_0,
        .gpiob_int_1,
        .gpioc_int_0,
        .gpioc_int_1,
        .uart0_rx_int,
        .uart0_tx_int,
        .timer0_int,
        .timer1_int
    );
    ////////////////////////////////////////////////////////////
    // END: Core Instantiation
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: ROM & RAM Instantiation
    ////////////////////////////////////////////////////////////
    rom #(
        .ADDR_WIDTH(ROM_ADDR_WIDTH)
    ) ROM0 (
        .clk,
        .rd_en1(rom_rd_en1),
        .addr1(rom_addr1),
        .rd_data1(rom_rd_data1),
        .rd_en2(rom_rd_en2),
        .wr_en2(rom_wr_en2),
        .addr2(rom_addr2),
        .wr_data2(wr_data),
        .wr_strobe2(wr_strobe),
        .rd_data2(rom_rd_data2)
    );

    ram #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .DUMP_MEM(0)
    ) RAM0 (
        .clk,
        .rd_en(ram_rd_en),
        .wr_en(ram_wr_en),
        .addr(ram_addr),
        .wr_data,
        .wr_strobe,
        .rd_data(ram_rd_data)
    );
    ////////////////////////////////////////////////////////////
    // END: ROM & RAM Instantiation
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: AXI Manager & Crossbar Instantiation
    ////////////////////////////////////////////////////////////
    axi4_lite_manager #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .TIMEOUT(AXI_TIMEOUT)
    ) CORE0_AXI (
        .clk,
        .rst_n,
        .rd_en(axi_rd_en),
        .wr_en(axi_wr_en),
        .addr(axi_addr),
        .wr_data,
        .wr_strobe,
        .rd_data(axi_rd_data),
        .access_fault(axi_access_fault),
        .busy(axi_busy),
        .axi_m(axi_m.manager)
    );
    axi4_lite_crossbar8 #(
        .WIDTH(rv32::XLEN),
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .S00_ADDR_WIDTH(GPIO_ADDR_WIDTH),
        .S01_ADDR_WIDTH(GPIO_ADDR_WIDTH),
        .S02_ADDR_WIDTH(GPIO_ADDR_WIDTH),
        .S03_ADDR_WIDTH(UART_ADDR_WIDTH),
        .S04_ADDR_WIDTH(VGA_ADDR_WIDTH),
        .S00_BASE_ADDR(GPIOA_BASE_ADDR),
        .S01_BASE_ADDR(GPIOB_BASE_ADDR),
        .S02_BASE_ADDR(GPIOC_BASE_ADDR),
        .S03_BASE_ADDR(UART0_BASE_ADDR),
        .S04_BASE_ADDR(VGA_BASE_ADDR),
        .S05_ENABLE(0),
        .S06_ENABLE(0),
        .S07_ENABLE(0)
    ) CROSSBAR (
        .axi_m,
        .axi_s00(axi_gpioa),
        .axi_s01(axi_gpiob),
        .axi_s02(axi_gpioc),
        .axi_s03(axi_uart0),
        .axi_s04(axi_vga),
        .axi_s05(axi_s05), // unused
        .axi_s06(axi_s06), // unused
        .axi_s07(axi_s07)  // unused
    );
    ////////////////////////////////////////////////////////////
    // END: AXI Manager & Crossbar Instantiation
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////




    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Peripheral Instantiations
    ////////////////////////////////////////////////////////////
    gpio #(
        .WIDTH(rv32::XLEN),
        .PIN_COUNT(16)
    ) GPIOA (
        .io_pins(gpioa),
        .int0(gpioa_int_0),
        .int1(gpioa_int_1),
        .axi(axi_gpioa)
    );
    gpio #(
        .WIDTH(rv32::XLEN),
        .PIN_COUNT(16)
    ) GPIOB (
        .io_pins(gpiob),
        .int0(gpiob_int_0),
        .int1(gpiob_int_1),
        .axi(axi_gpiob)
    );
    gpio #(
        .WIDTH(rv32::XLEN),
        .PIN_COUNT(16)
    ) GPIOC (
        .io_pins(gpioc),
        .int0(gpioc_int_0),
        .int1(gpioc_int_1),
        .axi(axi_gpioc)
    );
    uart #(
        .WIDTH(rv32::XLEN),
        .BUS_CLK(CLK_FREQ),
        .BAUD(UART0_BAUD),
        .FIFO_DEPTH(UART0_FIFO_DEPTH)
    ) UART0 (
        .rx(uart0_rx),
        .tx(uart0_tx),
        .rx_int(uart0_rx_int),
        .tx_int(uart0_tx_int),
        .axi(axi_uart0)
    );
    vga #(
        .H_LINE(VGA_H_LINE),
        .H_SYNC_PULSE(VGA_H_SYNC_PULSE),
        .H_BACK_PORCH(VGA_H_BACK_PORCH),
        .H_FRONT_PORCH(VGA_H_FRONT_PORCH),
        .V_LINE(VGA_V_LINE),
        .V_SYNC_PULSE(VGA_V_SYNC_PULSE),
        .V_BACK_PORCH(VGA_V_BACK_PORCH),
        .V_FRONT_PORCH(VGA_V_FRONT_PORCH),
        .AXI_DATA_WIDTH(rv32::XLEN),
        .PIXEL_WIDTH(VGA_PIXEL_WIDTH),
        .PIXEL_HEIGHT(VGA_PIXEL_HEIGHT),
        .PIXEL_FORMAT(VGA_PIXEL_FORMAT)
    ) VGA0 (
        .pxclk,
        .rst_n,
        .r(vga_r),
        .g(vga_g),
        .b(vga_b),
        .hsync(vga_hs),
        .vsync(vga_vs),
        .axi(axi_vga)
    );
    assign timer0_int = 0;
    assign timer1_int = 0;
    ////////////////////////////////////////////////////////////
    // END: Peripheral Instantiations
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


endmodule
