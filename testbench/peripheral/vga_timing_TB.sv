`timescale 1ns/1ps

`include "rv32.sv"


module vga_timing_TB;

    localparam MAX_CYCLES = 1_000_000;
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;

    // DUT Parameters
    localparam PIXEL_WIDTH          = 640;
    localparam PIXEL_HEIGHT         = 480;
    localparam H_SYNC_PULSE         = 96;
    localparam H_BACK_PORCH         = 48;
    localparam H_FRONT_PORCH        = 16;
    localparam V_SYNC_PULSE         = 2;
    localparam V_BACK_PORCH         = 33;
    localparam V_FRONT_PORCH        = 10;

    // DUT Ports
    logic pxclk;
    logic rst, rst_n;

    logic hsync;
    logic vsync;
    logic [$clog2(PIXEL_WIDTH)-1:0] xaddr;
    logic [$clog2(PIXEL_HEIGHT)-1:0] yaddr;
    logic addr_valid;


    assign rst_n = ~rst;

    // Instantiate DUT
    vga_timing #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .PIXEL_HEIGHT(PIXEL_HEIGHT),
        .H_SYNC_PULSE(H_SYNC_PULSE),
        .H_BACK_PORCH(H_BACK_PORCH),
        .H_FRONT_PORCH(H_FRONT_PORCH),
        .V_SYNC_PULSE(V_SYNC_PULSE),
        .V_BACK_PORCH(V_BACK_PORCH),
        .V_FRONT_PORCH(V_FRONT_PORCH)
    ) DUT (
        .pxclk,
        .rst_n,
        .hsync,
        .vsync,
        .xaddr,
        .yaddr,
        .addr_valid
    );


    // 25 MHz pixel clock
    initial pxclk = 1;
    initial forever #20 pxclk <= ~pxclk;


    // Initialize
    initial begin

        fid = $fopen("vga_timing.log");
        $dumpfile("vga_timing.vcd");
        $dumpvars(4, vga_timing_TB);

        // Reset
        rst <= 1;
        #80
        rst <= 0;

    end


    // Stimulus


    // End Simulation
    always @(posedge pxclk) begin
        clk_count <= clk_count + 1;
        if (clk_count >= MAX_CYCLES) begin
            // if (fail_count || (!pass_count)) begin
            //     $write("\n\nFAILED!    %3d/%3d\n", fail_count, fail_count+pass_count);
            //     $fwrite(fid,"\n\nFailed!    %3d/%3d\n", fail_count, fail_count+pass_count);
            // end
            // else begin
            //     $write("\n\nPASSED all %3d tests\n", pass_count);
            //     $fwrite(fid,"\n\nPASSED all %3d tests\n", pass_count);
            // end
            $write("\n\nWARNING this testbench is not self-verifying\n");
            $fwrite(fid,"\n\nWARNING this testbench is not self-verifying\n");
            $fclose(fid);
            $finish();
        end
    end

endmodule
