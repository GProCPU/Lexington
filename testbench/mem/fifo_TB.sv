`timescale 1ns/1ps


module fifo_TB;

    localparam MAX_CYCLES = 128;
    integer clk_count = 0;
    integer fail = 0;
    integer fid;

    // DUT Parameters
    localparam WIDTH = 8;
    localparam DEPTH = 8;
    localparam FIRST_WORD_FALLTHROUGH = 0;

    // DUT Ports
    logic clk;
    logic rst, rst_n;
    logic wr_en, rd_en;
    logic [WIDTH-1:0] din, dout;
    logic full, empty;

    assign rst_n = ~rst;

    // Instantiate DUT
    fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .FIRST_WORD_FALLTHROUGH(FIRST_WORD_FALLTHROUGH),
        .DEBUG(1)
    ) DUT (
        .clk,
        .rst_n,
        .wr_en,
        .din,
        .full,
        .rd_en,
        .dout,
        .empty
    );


    // 10 MHz clock
    initial clk = 0;
    initial forever #50 clk = ~clk;

    // Initialize
    initial begin
        wr_en <= 0;
        din   <= 0;
        rd_en <= 0;

        fid = $fopen("fifo.log");
        $dumpfile("fifo.vcd");
        $dumpvars(3, fifo_TB);

        rst <= 1;
        #200;
        rst <= 0;
    end


    // Stimulus
    logic _rd_en;
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_en <= 0;
            din   <= 0;
            rd_en <= 0;
            _rd_en<= 0;
        end
        else begin
            wr_en <= !full;
            rd_en <= !empty;
            _rd_en<= rd_en;
            din   <= $random();
            if (wr_en) begin
                $write("write 0x%h\n", din);
                $fwrite(fid,"writing 0x%h\n", din);
            end
            if (_rd_en) begin
                $write("read 0x%h\n", dout);
                $fwrite(fid,"read 0x%h\n", dout);
            end
        end
    end


    // End Simulation
    always @(posedge clk) begin
        clk_count <= clk_count + 1;
        if (clk_count >= MAX_CYCLES) begin
            if (fail) begin
                $write("\n\nFAILED %d tests\n", fail);
                $fwrite(fid,"\n\nFailed %d tests\n", fail);
            end
            else begin
                $write("\n\nPASSED all tests\n");
                $fwrite(fid,"\n\nPASSED all tests\n");
            end
            $fclose(fid);
            $finish();
        end
    end

endmodule
