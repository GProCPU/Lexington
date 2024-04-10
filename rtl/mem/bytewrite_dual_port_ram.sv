// True-Dual-Port BRAM with Byte-wide Write Enable
//      Read-First mode
// dual_port_ram.sv
`timescale 1ns/1ps


module bytewrite_dual_port_ram #(
        parameter NUM_COL       = 4,
        parameter COL_WIDTH     = 8,
        parameter ADDR_WIDTH    = 10,                   // addr width in bits : 2 * ADDR_WIDTH = RAM Depth
        parameter DATA_WIDTH    = NUM_COL*COL_WIDTH     // data width in bits
    ) (
        input  logic clk_a,
        input  logic en_a,
        input  logic [NUM_COL-1:0] wen_a,
        input  logic [ADDR_WIDTH-1:0] addr_a,
        input  logic [DATA_WIDTH-1:0] din_a,
        output logic [DATA_WIDTH-1:0] dout_a,

        input  logic clk_b,
        input  logic en_b,
        input  logic [NUM_COL-1:0] wen_b,
        input  logic [ADDR_WIDTH-1:0] addr_b,
        input  logic [DATA_WIDTH-1:0] din_b,
        output logic [DATA_WIDTH-1:0] dout_b
    );

    integer i, j;

    // Memory
    logic [DATA_WIDTH-1:0] ram_block [(2**ADDR_WIDTH)-1:0];
    initial for (j=0; j<2**ADDR_WIDTH; j++) begin
        ram_block[j] = 0;
    end


    // Port-A
    always_ff @(posedge clk_a) begin
        if (en_a) begin
            for (i=0; i<NUM_COL; i=i+1) begin
                if (wen_a[i]) begin
                    ram_block[addr_a][i*COL_WIDTH +: COL_WIDTH]
                            <= din_a[i*COL_WIDTH +: COL_WIDTH];
                end
            end
            dout_a <= ram_block[addr_a];
        end
    end


    // Port-B
    always_ff @(posedge clk_b) begin
        if (en_b) begin
            for (i=0; i<NUM_COL; i=i+1) begin
                if (wen_b[i]) begin
                    ram_block[addr_b][i*COL_WIDTH +: COL_WIDTH]
                            <= din_b[i*COL_WIDTH +: COL_WIDTH];
                end
            end
            dout_b <= ram_block[addr_b];
        end
    end


endmodule
