`timescale 1ns/1ps


module uart_tx_TB;

    localparam BUS_CLK          = 10_000_000;
    localparam CLK_PERIOD       = 1_000_000_000 / BUS_CLK;
    localparam BAUD             = 9_600;

    localparam MAX_CYCLES = 32*12 + 3;
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;


    // DUT Ports
    logic clk;
    logic clk_en;
    logic rst, rst_n;
    logic tx;
    logic send;
    logic [7:0] dout;
    logic busy;

    // Instantiate DUT
    uart_tx #(
        .BUS_CLK(BUS_CLK),
        .BAUD(BAUD)
    ) DUT (
        .clk,
        .clk_en,
        .rst_n,
        .tx,
        .send,
        .dout,
        .busy
    );


    assign rst_n = ~rst;


    // Generate Clock
    initial clk = 1;
    initial forever #(CLK_PERIOD/2) clk <= ~clk;

    // Initialize
    initial begin

        clk_en  <= 1; // speed things up for testing
        send    <= 0;

        fid = $fopen("uart_tx.log");
        $dumpfile("uart_tx.vcd");
        $dumpvars(4, uart_tx_TB);

        // Reset
        rst <= 1;
        #(2*CLK_PERIOD);
        rst <= 0;
    end


    // Stimulus
    logic [7:0] buff;
    integer i;
    initial begin
        // Wait for reset
        #(3*CLK_PERIOD);

        while (1) begin

            // Wait until not busy
            while (busy) @(posedge clk);

            // Send
            dout <= $random();
            @(posedge clk);
            $write("%3d:    Sending 0x%02X \t...", clk_count, dout);
            $fwrite(fid,"%3d:    Sending 0x%02X \t...", clk_count, dout);
            send <= 1;
            @(posedge clk);
            send <= 0;

            // Wait for start bit
            while (tx) @(posedge clk);
            @(posedge clk);

            // Data bits
            for (i=0; i<8; i++) begin
                buff[i] <= tx;
                $write("%b", tx);
                $fwrite(fid,"%b", tx);
                @(posedge clk);
            end

            // Stop bit
            $write("... \tReceived 0x%02X", buff);
            $fwrite(fid,"... \tReceived 0x%02X", buff);
            if (tx) begin
                if (dout == buff) begin
                    pass_count++;
                end
                else begin
                    fail_count++;
                    $write("        FAIL data does not match");
                    $fwrite(fid,"        FAIL data does not match");
                end
            end
            else begin
                fail_count++;
                $write("        FAIL bad stop bit");
                $fwrite(fid,"        FAIL bad stop bit");
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
