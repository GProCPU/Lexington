`timescale 1ns/1ps

`include "rv32.sv"


module vga_TB;

    localparam MAX_CYCLES = 16*8;
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;

    // DUT Parameters
    localparam VGA_PIXEL_WIDTH          = 640;
    localparam VGA_PIXEL_HEIGHT         = 480;
    localparam VGA_PIXEL_DEPTH          = 8;
    localparam VGA_H_SYNC_PULSE         = 96;
    localparam VGA_H_BACK_PORCH         = 48;
    localparam VGA_H_FRONT_PORCH        = 16;
    localparam VGA_V_SYNC_PULSE         = 2;
    localparam VGA_V_BACK_PORCH         = 33;
    localparam VGA_V_FRONT_PORCH        = 10;
    localparam VGA_ADDR_WIDTH           = $clog2(VGA_PIXEL_WIDTH * VGA_PIXEL_HEIGHT * ((VGA_PIXEL_DEPTH-1)/2 + 1)); // byte-addressable VGA address

    localparam AXI_DATA_WIDTH = rv32::XLEN;
    localparam AXI_ADDR_WIDTH = VGA_ADDR_WIDTH;

    // DUT Ports
    logic aclk;
    logic pxclk;
    logic rst, rst_n;

    logic [3:0] r;
    logic [3:0] g;
    logic [3:0] b;
    logic hsync;
    logic vsync;

    axi4_lite #(.AXI_DATA_WIDTH(AXI_DATA_WIDTH), .ADDR_WIDTH(AXI_ADDR_WIDTH)) axi();

    logic _axi_err;
    logic [VGA_ADDR_WIDTH-1:0] _axi_addr;
    logic [AXI_DATA_WIDTH-1:0] _axi_data;
    logic [(AXI_DATA_WIDTH/8)-1:0] _axi_wstrb;


    assign axi.aclk = aclk;
    assign axi.areset_n = rst_n;
    assign rst_n = ~rst;

    // Instantiate DUT
    vga #(
        .PIXEL_WIDTH(VGA_PIXEL_WIDTH),
        .PIXEL_HEIGHT(VGA_PIXEL_HEIGHT),
        .PIXEL_DEPTH(VGA_PIXEL_DEPTH),
        .H_SYNC_PULSE(VGA_H_SYNC_PULSE),
        .H_BACK_PORCH(VGA_H_BACK_PORCH),
        .H_FRONT_PORCH(VGA_H_FRONT_PORCH),
        .V_SYNC_PULSE(VGA_V_SYNC_PULSE),
        .V_BACK_PORCH(VGA_V_BACK_PORCH),
        .V_FRONT_PORCH(VGA_V_FRONT_PORCH),
        .AXI_DATA_WIDTH(rv32::XLEN)
    ) DUT (
        .pxclk,
        .rst_n,
        .r,
        .g,
        .b,
        .hsync,
        .vsync,
        .axi
    );


    // 100 MHz AXI clock
    initial aclk = 1;
    initial forever #5 aclk <= ~aclk;

    // 25 MHz pixel clock
    initial pxclk = 1;
    initial forever #20 pxclk <= ~pxclk;


    // Initialize
    initial begin

        axi.awvalid <= 0;
        axi.awaddr  <= 0;
        axi.awprot  <= 0;
        axi.wvalid  <= 0;
        axi.wdata   <= 0;
        axi.wstrb   <= 4'b1111;
        axi.bready  <= 0;
        axi.arvalid <= 0;
        axi.araddr  <= 0;
        axi.arprot  <= 0;
        axi.rready  <= 0;

        _axi_err    <= 0;
        _axi_addr   <= 0;
        _axi_data   <= 0;
        _axi_wstrb  <= 0;

        fid = $fopen("vga.log");
        $dumpfile("vga.vcd");
        $dumpvars(4, vga_TB);

        // Reset
        rst <= 1;
        #20
        rst <= 0;

    end


    task axi_wr(input  [AXI_ADDR_WIDTH-1:0] awaddr,
                input  [AXI_DATA_WIDTH-1:0] wdata,
                input  [AXI_DATA_WIDTH-1:0] wstrb,
                output err);
        begin
            axi.awvalid <= 1;
            axi.awaddr  <= awaddr;
            axi.wvalid  <= 1;
            axi.wdata   <= wdata;
            axi.wstrb   <= wstrb;
            @(posedge axi.aclk);
            while ((axi.awvalid && !axi.awready)
                || (axi.wvalid && !axi.wready))
            begin
                if (axi.awready) begin
                    axi.awvalid <= 0;
                end
                if (axi.wready) begin
                    axi.wvalid <= 0;
                end
                @(posedge axi.aclk);
            end
            axi.awvalid <= 0;
            axi.wvalid  <= 0;
            axi.bready  <= 1;
            @(posedge axi.aclk);
            while (!axi.bvalid) @(posedge axi.aclk);
            axi.bready  <= 0;
            err <= (axi.bresp != 2'b00);
            @(posedge axi.aclk);
        end
    endtask
    task axi_rd(input [AXI_ADDR_WIDTH-1:0] araddr,
                output [AXI_DATA_WIDTH-1:0] rdata,
                output err);
        begin
            axi.arvalid <= 1;
            axi.araddr  <= araddr;
            @(posedge axi.aclk);
            while (!axi.arready) @(posedge axi.aclk);
            axi.arvalid <= 0;
            axi.rready  <= 1;
            @(posedge axi.aclk);
            while (!axi.rvalid) @(posedge axi.aclk);
            axi.rready  <= 0;
            rdata       <= axi.rdata;
            err         <= (axi.rresp != 2'b00);
            @(posedge axi.aclk);
        end
    endtask



    // Stimulus


    // End Simulation
    always @(posedge aclk) begin
        clk_count <= clk_count + 1;
        if (clk_count >= MAX_CYCLES) begin
            if (fail_count || (!pass_count)) begin
                $write("\n\nFAILED!    %3d/%3d\n", fail_count, fail_count+pass_count);
                $fwrite(fid,"\n\nFailed!    %3d/%3d\n", fail_count, fail_count+pass_count);
            end
            else begin
                $write("\n\nPASSED all %3d tests\n", pass_count);
                $fwrite(fid,"\n\nPASSED all %3d tests\n", pass_count);
            end
            $fclose(fid);
            $finish();
        end
    end

endmodule
