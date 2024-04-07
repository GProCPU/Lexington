`timescale 1ns/1ps


`include "rv32.sv"
`include "lexington.sv"
import lexington::*;


module mtime (
        input  logic clk,                                   // system clock
        input  logic rst_n,                                 // reset (active-low)

        input  logic rd_en,                                 // read enable from DBus
        input  logic wr_en,                                 // write enable from DBus
        input  logic [1:0] addr,                            // read/write address from DBus
        input  rv32::word wr_data,                          // write data from DBus
        input  logic [(rv32::XLEN/8)-1:0] wr_strobe,        // byte enable for writes from DBus
        output rv32::word rd_data,                          // read data to DBus
        output logic [63:0] time_rd_data,                   // read-only time(h) CSR
        output logic interrupt                              // machine timer interrupt flag
    );

    logic [63:0] mtime;
    logic [63:0] mtimecmp;

    assign time_rd_data = mtime;
    assign interrupt = (mtime >= mtimecmp);


    // Read logic
    always_comb begin
        if (rd_en) begin
            case (addr)
                'b00: rd_data = mtime[31:0];
                'b01: rd_data = mtime[63:32];
                'b10: rd_data = mtimecmp[31:0];
                'b11: rd_data = mtimecmp[63:32];
            endcase
        end
        else begin
            rd_data = 0;
        end
    end


    // Write and Increment logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            mtime    <= 0;
            mtimecmp <= 0;
        end
        else begin

            // Increment
            // overwritten by writes
            mtime <= mtime + 1;

            // Write
            if (wr_en) begin
                for (integer i=0; i<rv32::XLEN; i+=8) begin
                    if (wr_strobe[i/8]) begin
                        case (addr)
                            'b00: mtime[i+:8]           <= wr_data[i+:8];
                            'b01: mtime[(i+32)+:8]      <= wr_data[i+:8];
                            'b10: mtimecmp[i+:8]        <= wr_data[i+:8];
                            'b11: mtimecmp[(i+32)+:8]   <= wr_data[i+:8];
                        endcase
                    end
                end
            end

        end
    end


endmodule
