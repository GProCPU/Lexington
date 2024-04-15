`timescale 1ns/1ps


module uart_rx_TB;

    localparam BUS_CLK          = 10_000_000;
    localparam CLK_PERIOD       = 1_000_000_000 / BUS_CLK;
    localparam BAUD             = 9_600;

    localparam MAX_CYCLES = 32*(10*8) + 3;
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;


    // DUT Ports
    logic clk;
    logic clk_en;
    logic rst, rst_n;
    logic rx;
    logic [7:0] din;
    logic busy;
    logic recv;
    logic err;

    // Instantiate DUT
    uart_rx #(
        .BUS_CLK(BUS_CLK),
        .BAUD(BAUD)
    ) DUT (
        .clk,
        .clk_en,
        .rst_n,
        .rx,
        .din,
        .busy,
        .recv,
        .err
    );


    assign rst_n = ~rst;


    // Generate Clock
    initial clk = 1;
    initial forever #(CLK_PERIOD/2) clk <= ~clk;

    // Initialize
    initial begin

        clk_en  <= 1; // speed things up for testing
        rx      <= 1;

        fid = $fopen("uart_rx.log");
        $dumpfile("uart_rx.vcd");
        $dumpvars(4, uart_rx_TB);

        // Reset
        rst <= 1;
        #(2*CLK_PERIOD);
        rst <= 0;
    end


    // Stimulus
    logic [7:0] buff;
    integer i, j;
    initial begin
        // Wait for reset
        #(3*CLK_PERIOD);

        while (1) begin

            // Wait until not busy
            while (busy) @(posedge clk);

            // Send
            buff <= $random();
            #CLK_PERIOD;
            $write("%3d:    Sending 0x%02X \t...", clk_count, buff);
            $fwrite(fid,"%3d:    Sending 0x%02X \t...", clk_count, buff);

            // Start bit
            rx <= 0;
            #(8*CLK_PERIOD); // over-8 sampling

            // Data bits
            for (i=0; i<8; i++) begin
                rx <= buff[i];
                $write("%b", rx);
                $fwrite(fid,"%b", rx);
                #(8*CLK_PERIOD);
            end

            // Stop bit
            rx <= 1;
            #(4*CLK_PERIOD);

            // Wait for received flag
            while (!recv) #CLK_PERIOD;
            // Read output
            $write("... \tReceived 0x%02X", din);
            $fwrite(fid,"... \tReceived 0x%02X", din);
            if (err) begin
                fail_count++;
                $write("        FAIL bad stop bit reported");
                $fwrite(fid,"        FAIL bad stop bit reported");
            end
            else if (din != buff) begin
                fail_count++;
                $write("        FAIL data does not match");
                $fwrite(fid,"        FAIL data does not match");
            end
            else begin
                pass_count++;
            end
            $write("\n");
            $fwrite(fid,"\n");

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
