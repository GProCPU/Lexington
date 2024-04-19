//depend sync.sv
//depend mem/dual_port_ram.sv
//depend peripheral/vga_timing.sv
//depend peripheral/vga_frame_buff.sv
`timescale 1ns/1ps


// Not fully parameterized
module vga #(
        parameter H_LINE            = 640,
        parameter H_SYNC_PULSE      = 96,
        parameter H_BACK_PORCH      = 48,
        parameter H_FRONT_PORCH     = 16,
        parameter V_LINE            = 480,
        parameter V_SYNC_PULSE      = 2,
        parameter V_BACK_PORCH      = 33,
        parameter V_FRONT_PORCH     = 10,
        parameter AXI_DATA_WIDTH    = 32,
        parameter PIXEL_WIDTH       = H_LINE,
        parameter PIXEL_HEIGHT      = V_LINE,
        parameter PIXEL_FORMAT      = "rgb332"
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

    // Pixel formats
    localparam PIXEL_DEPTH =        ("rgb332" == PIXEL_FORMAT) ? 8 :
                                    ("rgb12"  == PIXEL_FORMAT) ? 12 :
                                    0;
    localparam BYTES_PER_PIXEL =    ("rgb332" == PIXEL_FORMAT) ? 1 :
                                    ("rgb12"  == PIXEL_FORMAT) ? 2 :
                                    0;
    generate if (0 == PIXEL_DEPTH) begin
        $error("Invalid pixel format in module VGA. Expected 'rgb332' or 'rgb12', not '%s'", PIXEL_FORMAT);
    end endgenerate

    localparam H_SCALE = H_LINE / PIXEL_WIDTH;
    localparam V_SCALE = V_LINE / PIXEL_HEIGHT;
    localparam AXI_ADDR_WIDTH = $clog2(PIXEL_WIDTH * PIXEL_HEIGHT * BYTES_PER_PIXEL);

    logic [$clog2(H_LINE)-1:0] xaddr;
    logic [$clog2(V_LINE)-1:0] yaddr;
    logic addr_valid, addr_valid_buff;

    logic [$clog2(PIXEL_WIDTH*PIXEL_HEIGHT)-1:0] px_addr;
    logic [PIXEL_DEPTH-1:0] px_data;

    logic [$clog2(PIXEL_WIDTH*PIXEL_HEIGHT)-1:0] row_addr;
    logic [$clog2(H_SCALE)-1:0] h_count;
    logic [$clog2(V_SCALE)-1:0] v_count;

    logic [PIXEL_DEPTH-1:0] rgb;
    logic hsync_wire;
    logic vsync_wire;

    enum {V_BLANK, H_BLANK, VISIBLE} state;

    // Delay sync signals
    logic hsync_delay, vsync_delay;
    always_ff @(posedge pxclk) begin
        if (!rst_n) begin
            hsync       <= 0;
            vsync       <= 0;
            hsync_delay <= 0;
            vsync_delay <= 0;
        end
        else begin
            hsync       <= hsync_delay;
            vsync       <= vsync_delay;
            hsync_delay <= hsync_wire;
            vsync_delay <= vsync_wire;
        end
    end


    // Register rgb output
    always_ff @(posedge pxclk) begin
        if (!rst_n) begin
            rgb <= 0;
            addr_valid_buff <= 0;
        end
        else begin
            addr_valid_buff <= addr_valid;
            if (addr_valid_buff) begin
                rgb <= px_data;
            end
            else begin
                rgb <= 0;
            end
        end
    end

    generate
        if ("rgb332" == PIXEL_FORMAT) begin
            assign r = {rgb[7:5], rgb[7]};
            assign g = {rgb[4:2], rgb[4]};
            assign b = {rgb[1:0], rgb[1:0]};
        end
        else if ("rgb12" == PIXEL_FORMAT) begin
            assign r = rgb[11:8];
            assign g = rgb[7:4];
            assign b = rgb[3:0];
        end
    endgenerate

    always_ff @(posedge pxclk) begin
        if (!rst_n) begin
            state   <= V_BLANK;
            px_addr <= 0;
            row_addr<= 0;
            h_count <= 0;
            v_count <= 0;
        end
        else begin
            case (state)

                V_BLANK: begin
                    px_addr <= 0;
                    row_addr<= 0;
                    h_count <= 0;
                    v_count <= 0;
                    if (addr_valid) begin
                        state   <= VISIBLE;
                        h_count <= h_count + 1;
                    end
                end

                H_BLANK: begin
                    if (addr_valid) begin
                        state   <= VISIBLE;
                        h_count <= h_count + 1;
                    end
                    else if (vsync_wire) begin
                        state   <= V_BLANK;
                    end
                end

                VISIBLE: begin
                    if (addr_valid) begin
                        if (h_count >= H_SCALE-1) begin
                            px_addr <= px_addr + 1;
                            h_count <= 0;
                        end
                        else begin
                            h_count <= h_count + 1;
                        end
                    end
                    else begin
                        state   <= H_BLANK;
                        if (v_count >= V_SCALE-1) begin
                            row_addr<= px_addr;
                            v_count <= 0;
                        end
                        else begin
                            px_addr <= row_addr;
                            v_count <= v_count + 1;
                        end
                    end
                end

            endcase
        end
    end


    vga_timing #(
        .H_LINE(H_LINE),
        .V_LINE(V_LINE),
        .H_SYNC_PULSE(H_SYNC_PULSE),
        .H_BACK_PORCH(H_BACK_PORCH),
        .H_FRONT_PORCH(H_FRONT_PORCH),
        .V_SYNC_PULSE(V_SYNC_PULSE),
        .V_BACK_PORCH(V_BACK_PORCH),
        .V_FRONT_PORCH(V_FRONT_PORCH)
    ) TIMING (
        .pxclk,
        .rst_n,
        .hsync(hsync_wire),
        .vsync(vsync_wire),
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
