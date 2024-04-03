//depend sync.sv
`timescale 1ns/1ps


module reset #(
        parameter MIN_RESET_CYCLES  = 3
    )(
        input  logic clk,
        input  logic rst_n_i,
        output logic rst_n_o
    );

    logic rst_n_sync;
    logic rst_n_extended;
    integer counter;

    // Synchronize reset to clock domain
    sync #(
        .STAGES(2),
        .RESET_VALUE(0) // start in reset
    ) SLOW_SYNC (
        .dest_clk(clk),
        .rst_n(1'b1),
        .din(rst_n_i),
        .dout(rst_n_sync)
    );

    // Extend to minimum number of cycles
    initial rst_n_extended <= 0; // start in reset
    initial counter <= 0;
    always_ff @(posedge clk) begin
        if (!rst_n_sync) begin
            counter <= 0;
            rst_n_extended <= 0;
        end
        else begin
            if (counter >= MIN_RESET_CYCLES-1) begin
                rst_n_extended <= 1;
            end
            else begin
                rst_n_extended <= 0;
                counter++;
            end
        end
    end

    // Use global clock buffer for output reset signal (lower skew)
    // BUFG: Global Clock Simple Buffer
    // 7 Series
    // Xilinx HDL Libraries Guide, version 2012.2
    BUFG RST_BUFG (
        .I(rst_n_extended), // 1-bit input: Clock input
        .O(rst_n_o)         // 1-bit output: Clock output
    );
    // End of BUFG_inst instantiation

endmodule
