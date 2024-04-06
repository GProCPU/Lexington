//depend mem/dual_port_ram.sv
//depend peripheral/vga_timing.sv
//depend peripheral/vga_frame_buff.sv
`timescale 1ns/1ps


// Not fully parameterized
module vga #(
        parameter PIXEL_WIDTH       = 640,
        parameter PIXEL_HEIGHT      = 480,
        parameter PIXEL_DEPTH       = 8,
        parameter H_SYNC_PULSE      = 96,
        parameter H_BACK_PORCH      = 48,
        parameter H_FRONT_PORCH     = 16,
        parameter V_SYNC_PULSE      = 2,
        parameter V_BACK_PORCH      = 33,
        parameter V_FRONT_PORCH     = 10,
        parameter AXI_DATA_WIDTH    = 32
    ) (
        input  logic pxclk,
        input  logic rst_n,

        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b,
        output logic hsync,
        output logic vsync,

        axi4_lite.subordinate axi
    );

    localparam AXI_ADDR_WIDTH = $clog2(PIXEL_WIDTH * PIXEL_HEIGHT * ((PIXEL_DEPTH-1)/2 + 1));

    logic [$clog2(PIXEL_WIDTH)-1:0] xaddr;
    logic [$clog2(PIXEL_HEIGHT)-1:0] yaddr;
    logic addr_valid;

    logic [AXI_ADDR_WIDTH/2-1:0] px_addr;
    logic [PIXEL_DEPTH-1:0] px_data;

    logic [PIXEL_DEPTH-1:0] rgb;
    logic hsync_buff;
    logic vsync_buff;

    enum {V_BLANK, H_BLANK, VISIBLE} state;


    // Not parameterized to PIXEL_DEPTH
    // RGB332
    assign r = {rgb[7:5], rgb[5]};
    assign g = {rgb[4:2], rgb[2]};
    assign b = {rgb[1:0], rgb[1:0]};
    assign rgb = (state == VISIBLE) ? px_data : 0;

    always_ff @(posedge pxclk) begin
        if (!rst_n) begin
            state   <= V_BLANK;
            px_addr <= 0;
            hsync   <= 0;
            vsync   <= 0;
        end
        else begin
            hsync   <= hsync_buff;
            vsync   <= vsync_buff;
            case (state)

                V_BLANK: begin
                    px_addr <= 0;
                    if (addr_valid) begin
                        state <= VISIBLE;
                    end
                end

                H_BLANK: begin
                    if (addr_valid) begin
                        state <= VISIBLE;
                    end
                    else if (vsync) begin
                        state <= V_BLANK;
                    end
                end

                VISIBLE: begin
                    px_addr <= px_addr + 1;
                    if (!addr_valid) begin
                        state <= H_BLANK;
                    end
                end

            endcase
        end
    end


    vga_timing #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .PIXEL_HEIGHT(PIXEL_HEIGHT),
        .H_SYNC_PULSE(H_SYNC_PULSE),
        .H_BACK_PORCH(H_BACK_PORCH),
        .H_FRONT_PORCH(H_FRONT_PORCH),
        .V_SYNC_PULSE(V_SYNC_PULSE),
        .V_BACK_PORCH(V_BACK_PORCH),
        .V_FRONT_PORCH(V_FRONT_PORCH)
    ) TIMING (
        .pxclk,
        .rst_n,
        .hsync(hsync_buff),
        .vsync(vsync_buff),
        .xaddr,
        .yaddr,
        .addr_valid
    );

    vga_frame_buff #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .PIXEL_HEIGHT(PIXEL_HEIGHT),
        .PIXEL_DEPTH(PIXEL_DEPTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) FRAME_BUFF (
        .pxclk,
        .rst_n,
        .px_addr,
        .px_data,
        .axi
    );

endmodule
