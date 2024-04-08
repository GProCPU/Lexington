`timescale 1ns/1ps


module sync #(
        parameter integer STAGES        = 2,    // number of destination sync flops
        parameter logic   RESET_VALUE   = 0     // reset/initial value of output signal
    ) (
        input  logic dest_clk,              // destination clock
        input  logic rst_n,                 // synchronous reset (active-low)
        input  logic din,                   // asynchronous input
        output logic dout                   // synchronized output
    );

    (* ASYNC_REG = "TRUE" *) // Xilinx synthesis attribute
    logic [STAGES-1:0] flops;

    assign dout = flops[STAGES-1];

    initial begin
        flops = {STAGES{RESET_VALUE}};
    end
    always_ff @(posedge dest_clk) begin
        if (!rst_n) begin
            flops <= {STAGES{RESET_VALUE}};
        end
        else begin
            flops <= {flops[STAGES-2:0], din};
        end
    end

endmodule
