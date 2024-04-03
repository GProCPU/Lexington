`timescale 1ns/1ps


module vga_timing #(
        parameter PIXEL_WIDTH      = 640,
        parameter PIXEL_HEIGHT     = 480,
        parameter H_SYNC_PULSE     = 96,
        parameter H_BACK_PORCH     = 48,
        parameter H_FRONT_PORCH    = 16,
        parameter V_SYNC_PULSE     = 2,
        parameter V_BACK_PORCH     = 33,
        parameter V_FRONT_PORCH    = 10
    ) (
        input  logic pxclk,
        input  logic rst_n,

        output logic hsync,
        output logic vsync,

        output logic [$clog2(PIXEL_WIDTH)-1:0] xaddr,
        output logic [$clog2(PIXEL_HEIGHT)-1:0] yaddr,
        output logic addr_valid
    );

    typedef enum {SYNC, BACK_PORCH, VISIBLE, FRONT_PORCH} state_t;
    state_t hstate;
    state_t vstate;
    logic v_enable;


    // H Sync
    always_ff @(posedge pxclk) begin
        if (!rst_n) begin
            hstate  <= FRONT_PORCH;
            hsync   <= 0;
            xaddr   <= 0;
            addr_valid  <= 0;
            v_enable    <= 0;
        end
        else begin
            case (hstate)

                SYNC: begin
                    v_enable <= 0;
                    if (xaddr < H_SYNC_PULSE-1) begin
                        xaddr <= xaddr + 1;
                    end
                    else begin
                        hstate  <= BACK_PORCH;
                        hsync   <= 0;
                        xaddr   <= 0;
                    end
                end

                BACK_PORCH: begin
                    if (xaddr < H_BACK_PORCH-1) begin
                        xaddr <= xaddr + 1;
                    end
                    else begin
                        hstate  <= VISIBLE;
                        xaddr   <= 0;
                        addr_valid  <= 1;
                    end
                end

                VISIBLE: begin
                    if (xaddr < PIXEL_WIDTH-1) begin
                        xaddr <= xaddr + 1;
                    end
                    else begin
                        hstate  <= FRONT_PORCH;
                        xaddr   <= 0;
                        addr_valid  <= 0;
                    end
                end

                FRONT_PORCH: begin
                    if (xaddr < H_FRONT_PORCH-1) begin
                    end
                    else begin
                        hstate  <= SYNC;
                        hsync   <= 1;
                        xaddr   <= 0;
                        addr_valid  <= 0;
                        v_enable    <= 1;
                    end
                end

                default: begin
                    hstate  <= FRONT_PORCH;
                    hsync   <= 0;
                    xaddr   <= 0;
                    v_enable  <= 0;
                end

            endcase
        end
    end


    // V Sync
    always_ff @(posedge pxclk) begin
        if (!rst_n) begin
            vstate  <= FRONT_PORCH;
            vsync   <= 0;
            yaddr   <= 0;
        end
        else if (v_enable) begin
            case (vstate)

                SYNC: begin
                    if (yaddr < V_SYNC_PULSE-1) begin
                        yaddr <= yaddr + 1;
                    end
                    else begin
                        vstate  <= BACK_PORCH;
                        vsync   <= 0;
                        yaddr   <= 0;
                    end
                end

                BACK_PORCH: begin
                    if (yaddr < V_BACK_PORCH-1) begin
                        yaddr <= yaddr + 1;
                    end
                    else begin
                        vstate  <= VISIBLE;
                        yaddr   <= 0;
                    end
                end

                VISIBLE: begin
                    if (yaddr < PIXEL_WIDTH-1) begin
                        yaddr <= yaddr + 1;
                    end
                    else begin
                        vstate  <= FRONT_PORCH;
                        yaddr   <= 0;
                    end
                end

                FRONT_PORCH: begin
                    if (yaddr < V_FRONT_PORCH-1) begin
                    end
                    else begin
                        vstate  <= SYNC;
                        vsync   <= 1;
                        yaddr   <= 0;
                    end
                end

                default: begin
                    vstate  <= FRONT_PORCH;
                    hsync   <= 0;
                    yaddr   <= 0;
                end

            endcase
        end
    end


endmodule
