// True-Dual-Port BRAM
//      Read-First mode
// dual_port_ram.sv
`timescale 1ns/1ps


module dual_port_ram #(
        parameter DATA_WIDTH    = 8,
        parameter ADDR_WIDTH    = 10
    ) (
        input  logic clk_a,
        input  logic en_a,
        input  logic wen_a,
        input  logic [ADDR_WIDTH-1:0] addr_a,
        input  logic [DATA_WIDTH-1:0] din_a,
        output logic [DATA_WIDTH-1:0] dout_a,

        input  logic clk_b,
        input  logic en_b,
        input  logic wen_b,
        input  logic [ADDR_WIDTH-1:0] addr_b,
        input  logic [DATA_WIDTH-1:0] din_b,
        output logic [DATA_WIDTH-1:0] dout_b
    );


    // Memory
    logic [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    integer i;


    // Port-A
    always_ff @(posedge clk_a) begin
        if (en_a) begin
            if (wen_a) begin
                ram[addr_a] <= din_a;
            end
            dout_a <= ram[addr_a];
        end
    end


    // Port-B
    always_ff @(posedge clk_b) begin
        if (en_b) begin
            if (wen_b) begin
                ram[addr_b] <= din_b;
            end
            dout_b <= ram[addr_b];
        end
    end


endmodule
