`timescale 1ns/1ps

`include "rv32.sv"


module mtime_TB;

    localparam CLK_FREQ     = 10_000_000;               // 10 MHz
    localparam CLK_PERIOD   = 1_000_000_000 / CLK_FREQ;
    localparam MAX_CYCLES   = 32;                   // 2 milliseconds
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;


    // DUT Ports
    logic clk;
    logic rst, rst_n;
    logic rd_en, wr_en;
    logic [1:0] addr;
    rv32::word wr_data;
    logic [(rv32::XLEN/8)-1:0] wr_strobe;
    rv32::word rd_data;
    logic [63:0] time_rd_data;
    logic interrupt;


    assign rst_n = ~rst;

    // Instantiate DUT
    mtime DUT (
        .clk,
        .rst_n,
        .rd_en,
        .wr_en,
        .addr,
        .wr_data,
        .wr_strobe,
        .rd_data,
        .time_rd_data,
        .interrupt
    );


    // 25 MHz pixel clock
    initial clk = 1;
    initial forever #(CLK_PERIOD/2) clk <= ~clk;


    // Initialize
    initial begin

        rd_en   = 0;
        wr_en   = 0;
        addr    = 0;
        wr_data = 0;
        wr_strobe = ~0;

        fid = $fopen("mtime.log");
        $dumpfile("mtime.vcd");
        $dumpvars(4, mtime_TB);

        // Reset
        rst <= 1;
        #(2*CLK_PERIOD);
        rst <= 0;

    end


    // Stimulus
    initial begin

        // Wait for reset
        #(CLK_PERIOD)
        while (rst) #(CLK_PERIOD);

        // Write 0 to mtimecmp(h)
        wr_en   <= 1;
        addr    <= 'b10; // mtimecmp
        wr_data <= 0;
        @(posedge clk);
        addr    <= 'b11; // mtimecmph
        @(posedge clk);
        wr_en   <= 0;
        @(posedge clk);

        // Check interrupt
        if (interrupt) begin
            pass_count++;
            $write("%3d:  PASSED interrupt signal asserted\n", clk_count);
            $fwrite(fid,"%3d:  PASSED interrupt signal asserted\n", clk_count);
        end
        else begin
            fail_count++;
            $write("%3d:  FAILED interrupt signal not asserted!\n", clk_count);
            $fwrite(fid,"%3d:  FAILED interrupt signal not asserted!\n", clk_count);
        end

        // Write 10 to mtimecmp
        wr_en   <= 1;
        addr    <= 'b10; //mtimecmp
        wr_data <= 10;
        @(posedge clk);
        wr_en   <= 0;
        @(posedge clk);

        // Verify interrupt is de-asserted
        if (!interrupt) begin
            pass_count++;
            $write("%3d:  PASSED interrupt signal de-asserted after mtimecmp write\n", clk_count);
            $fwrite(fid,"%3d:  PASSED interrupt signal de-asserted after mtimecmp write\n", clk_count);
        end
        else begin
            fail_count++;
            $write("%3d:  FAILED interrupt signal not de-asserted after mtimecmp write\n", clk_count);
            $fwrite(fid,"%3d:  FAILED interrupt signal not de-asserted after mtimecmp write\n", clk_count);
        end

        // Wait for interrupt
        while (!interrupt) @(posedge clk);

        // Verify time = 10
        if (time_rd_data == 10) begin
            pass_count++;
            $write("%3d:  PASSED interrupt signal asserted at mtime = 10\n", clk_count);
            $fwrite(fid,"%3d:  PASSED interrupt signal asserted at mtime = 10\n", clk_count);
        end
        else begin
            fail_count++;
            $write("%3d:  FAILED interrupt asserted at mtime = %2d; expected mtime = 10\n", clk_count, time_rd_data);
            $fwrite(fid,"%3d:  FAILED interrupt asserted at mtime = %2d; expected mtime = 10\n", clk_count, time_rd_data);
        end

        // Reset mtime
        wr_en   <= 1;
        addr    <= 'b00; // mtime
        wr_data <= 0;
        @(posedge clk);
        wr_en   <= 0;
        @(posedge clk);

        // Verify interrupt is de-asserted
        if (!interrupt) begin
            pass_count++;
            $write("%3d:  PASSED interrupt signal de-asserted after mtime reset\n", clk_count);
            $fwrite(fid,"%3d:  PASSED interrupt signal de-asserted after mtime reset\n", clk_count);
        end
        else begin
            fail_count++;
            $write("%3d:  FAILED interrupt signal not de-asserted after mtime reset\n", clk_count);
            $fwrite(fid,"%3d:  FAILED interrupt signal not de-asserted after mtime reset\n", clk_count);
        end

    end


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
