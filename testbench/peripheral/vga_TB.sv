`timescale 1ns/1ps


module vga_TB;

    localparam MAX_CYCLES = 16*8;
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;

    // DUT Parameters


    // DUT Ports


    logic clk;
    logic rst, rst_n;

    assign rst_n = ~rst;

    // Instantiate DUT
    vga #(
    ) DUT (
    );


    // 100 MHz clock
    initial clk = 1;
    initial forever #5 clk <= ~clk;

    // Initialize
    initial begin

        fid = $fopen("vga.log");
        $dumpfile("vga.vcd");
        $dumpvars(4, vga_TB);

        // Reset
        rst <= 1;
        #20
        rst <= 0;

    end



    // Stimulus


    // End Simulation
    always @(posedge clk) begin
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
