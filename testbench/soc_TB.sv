//cmd cd ${PROJ_DIR}/sw/projects/uart_demo && make clean build dump
//cmd cp ${PROJ_DIR}/sw/projects/uart_demo/rom.hex .
`timescale 1ns/1ps


module soc_TB;

    localparam CLK_PERIOD = 100;
    localparam CYCLES_PER_MILLI = 1_000_000 / CLK_PERIOD;
    localparam SIM_MILLIS = 5;

    localparam MAX_CYCLES = SIM_MILLIS * CYCLES_PER_MILLI;
    integer clk_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;

    // DUT Parameters
    localparam UART0_BAUD           = 115200;
    localparam UART0_FIFO_DEPTH     = 8;

    // DUT Ports
    logic clk, pxclk;
    logic rst, rst_n;
    wire  [15:0] gpioa, gpiob, gpioc;
    logic uart0_rx;
    logic uart0_tx;
    logic [3:0] vga_r, vga_g, vga_b;
    logic vga_hs;
    logic vga_vs;

    logic [11:0] rgb;

    assign rst_n = ~rst;
    assign rgb = {vga_r, vga_g, vga_b};

    // Instantiate DUT
    soc #(
        .CLK_FREQ(10_000_000),
        .UART0_BAUD(UART0_BAUD),
        .UART0_FIFO_DEPTH(UART0_FIFO_DEPTH)
    ) DUT (
        .clk,
        .pxclk,
        .rst_n,
        .gpioa,
        .gpiob,
        .gpioc,
        .uart0_rx,
        .uart0_tx,
        .vga_r,
        .vga_g,
        .vga_b,
        .vga_hs,
        .vga_vs
    );


    logic [15:0] sw;
    logic btnU, btnL, btnR, btnD;
    assign gpiob = sw;
    assign gpioc[11:0] = 0;
    assign gpioc[12] = btnU;
    assign gpioc[13] = btnL;
    assign gpioc[14] = btnR;
    assign gpioc[15] = btnD;


    // Core clock
    initial clk = 1;
    initial forever #(CLK_PERIOD/2) clk = ~clk;

    // Pixel clock (25 MHz)
    initial pxclk = 1;
    initial forever #20 pxclk = ~pxclk;


    // Initialize
    initial begin

        uart0_rx    <= 1;
        sw          <= 0;
        btnU        <= 0;
        btnL        <= 0;
        btnR        <= 0;
        btnD        <= 0;

        fid = $fopen("soc.log");
        $dumpfile("soc.vcd");
        $dumpvars(5, soc_TB);

        rst = 1;
        #200;
        rst = 0;

    end


    // Track sim time
    integer millis = 0;
    initial forever begin
        $write("%1d/%1d ms\n", millis, SIM_MILLIS);
        millis++;
        #(CYCLES_PER_MILLI * CLK_PERIOD);
    end


    // Read UART
    integer i;
    logic [7:0] tx_buff;
    localparam BAUD_PERIOD = 1_000_000_000 / UART0_BAUD;
    always @(posedge clk) begin
        if (!rst_n) begin
        end
        else begin
            if (!uart0_tx) begin
                // Start bit
                if (!uart0_tx) begin
                    #(BAUD_PERIOD);
                    // Data bits
                    for (i=0; i<8; i++) begin
                        tx_buff[i] = uart0_tx;
                        #(BAUD_PERIOD);
                    end
                    // Stop bit
                    $write("%5d    UART0 TX ", clk_count);
                    $fwrite(fid,"%5d    UART0 TX ", clk_count);
                    if (tx_buff >= " " && tx_buff <= "~") begin
                        $write("'%c' (0x%02X)", tx_buff, tx_buff);
                        $fwrite(fid,"'%c' (0x%02X)", tx_buff, tx_buff);
                    end
                    else if (tx_buff == 'h0D) begin // \r
                        $write("'\\r' (0x%02X)", tx_buff);
                        $fwrite(fid,"'\\r' (0x%02X)", tx_buff);
                    end
                    else if (tx_buff == "\n") begin
                        $write("'\\n' (0x%02X)", tx_buff);
                        $fwrite(fid,"'\\n' (0x%02X)", tx_buff);
                    end
                    else begin
                        $write("0x%02X (non-printable)", tx_buff);
                        $fwrite(fid,"0x%02X (non-printable)", tx_buff);
                    end
                    if (!uart0_tx) begin
                        fail_count++;
                        $write("        FAIL bad stop bit");
                        $fwrite(fid,"        FAIL bad stop bit");
                    end
                    $write("\n");
                    $fwrite(fid,"\n");
                end
            end
        end
    end


    // Debug messages
    always @(posedge clk) begin
        if (rst) begin
        end
        else begin
            if (DUT.CORE0.DECODER.opcode == DUT.CORE0.DECODER.MISC_MEM
                && DUT.CORE0.DECODER.funct3 == DUT.CORE0.DECODER.FUNCT3_FENCE)
            begin
                // Fence instruction triggers debug
                $write("%5d    ", clk_count);
                $write("PC=0x%08X\n", DUT.CORE0.pc);
                $fwrite(fid,"%5d    ", clk_count);
                $fwrite(fid,"PC=0x%08X\n", DUT.CORE0.pc);
            end
        end
    end


    // End Simulation
    always @(posedge clk) begin
        clk_count <= clk_count + 1;
        if (clk_count >= MAX_CYCLES) begin
            if (fail_count || (pass_count<1)) begin
                $write("\n\nFAILED %d tests\n\n", fail_count);
                $fwrite(fid,"\n\nFailed %d tests\n\n", fail_count);
            end
            else begin
                $write("\n\nPASSED all tests\n\n");
                $fwrite(fid,"\n\nPASSED all tests\n\n");
            end
            $fclose(fid);
            $finish();
        end
    end

endmodule
