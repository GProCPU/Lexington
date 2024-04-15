`timescale 1ns/1ps

`include "rv32.sv"
`include "lexington.sv"
import lexington::*;


module rom #(
        parameter ADDR_WIDTH    = DEFAULT_ROM_ADDR_WIDTH    // word-addressable address bits
    ) (
        input  logic clk,
        // reset not needed; memory can start in undefined state

        input  logic rd_en1,                                // read enable 1
        input  logic [ADDR_WIDTH-1:0] addr1,                // read address 1 (word-addressable)
        output rv32::word rd_data1,                         // read data 1

        // Port 2 has write port for reprogramming (not true ROM ¯\_(ツ)_/¯)
        input  logic rd_en2,                                // read enable 2
        input  logic wr_en2,                                // write enable 2
        input  logic [ADDR_WIDTH-1:0] addr2,                // read/write address 2 (word-addressable)
        input  rv32::word wr_data2,                         // write data 2
        input  logic [(rv32::XLEN/8)-1:0] wr_strobe2,       // write strobe 2
        output rv32::word rd_data2                          // read data 2
    );

    localparam DEPTH = 2 ** ADDR_WIDTH;
    rv32::word data [DEPTH-1:0];

    initial begin
        $readmemh("rom.hex", data, 0, DEPTH-1);
    end


    assign rd_data1 = (rd_en1) ? data[addr1] : 0;
    assign rd_data2 = (rd_en2) ? data[addr2] : 0;

    // Write logic
    generate
        for (genvar i=0; i<rv32::XLEN; i+=8) begin
            always_ff @(posedge clk) begin
                if (wr_en2 & wr_strobe2[i/8]) begin
                    data[addr2][i+7:i] <= wr_data2[i+7:i];  // write byte lane
                end
            end
        end
    endgenerate

endmodule
