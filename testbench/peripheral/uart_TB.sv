`timescale 1ns/1ps


module uart_TB;

    localparam MAX_CYCLES = 64*100;
    integer clk_count  = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer fid;

    // DUT Parameters
    localparam WIDTH        = 32;
    localparam BUS_CLK      = 8_000_000;
    localparam BAUD         = 1_000_000;
    localparam FIFO_DEPTH   = 4;

    localparam CLK_PERIOD   = 1_000_000_000 / BUS_CLK;

    localparam UARTx_DATA           = 'h0;
    localparam UARTx_CONF           = 'h4;
    localparam UARTx_CONF_RX_FULL   = (32'h1 << 2);
    localparam UARTx_CONF_RX_EMPTY  = (32'h1 << 3);
    localparam UARTx_CONF_TX_FULL   = (32'h1 << 4);
    localparam UARTx_CONF_TX_EMPTY  = (32'h1 << 5);
    localparam UARTx_CONF_RX_ERR    = (32'h1 << 31);
    localparam AXI_ADDR_WIDTH = 3;

    // DUT Ports
    logic clk;
    logic rst, rst_n;
    logic rx, tx;
    logic rx_int, tx_int;
    axi4_lite #(.WIDTH(WIDTH), .ADDR_WIDTH(AXI_ADDR_WIDTH)) axi();

    logic _err;
    logic [7:0] _data;
    logic [31:0] _data32;

    assign axi.aclk = clk;
    assign axi.areset_n = rst_n;
    assign rst_n = ~rst;

    // Instantiate DUT
    uart #(
        .WIDTH(WIDTH),
        .BUS_CLK(BUS_CLK),
        .BAUD(BAUD),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) DUT (
        .rx,
        .tx,
        .rx_int,
        .tx_int,
        .axi
    );


    // 10 MHz clock
    initial clk = 0;
    initial forever #(CLK_PERIOD/2) clk <= ~clk;

    // Initialize
    initial begin

        rx <= 1;

        axi.awvalid <= 0;
        axi.awaddr  <= 0;
        axi.awprot  <= 0;
        axi.wvalid  <= 0;
        axi.wdata   <= 0;
        axi.wstrb   <= 0;
        axi.bready  <= 0;
        axi.arvalid <= 0;
        axi.araddr  <= 0;
        axi.arprot  <= 0;
        axi.rready  <= 0;

        _err        <= 0;
        _data       <= 0;

        fid = $fopen("uart.log");
        $dumpfile("uart.vcd");
        $dumpvars(4, uart_TB);

        // Reset
        rst <= 1;
        #(2*CLK_PERIOD);
        rst <= 0;
    end





    task axi_wr(input  [AXI_ADDR_WIDTH-1:0] awaddr,
                input  [WIDTH-1:0] wdata,
                output err);
        begin
            axi.awvalid <= 1;
            axi.awaddr  <= awaddr;
            axi.wvalid  <= 1;
            axi.wdata   <= wdata;
            @(posedge axi.aclk);
            while ((axi.awvalid && !axi.awready)
                || (axi.wvalid && !axi.wready))
            begin
                if (axi.awready) begin
                    axi.awvalid <= 0;
                end
                if (axi.wready) begin
                    axi.wvalid <= 0;
                end
                @(posedge axi.aclk);
            end
            axi.awvalid <= 0;
            axi.wvalid  <= 0;
            axi.bready  <= 1;
            @(posedge axi.aclk);
            while (!axi.bvalid) @(posedge axi.aclk);
            axi.bready  <= 0;
            err <= (axi.bresp != 2'b00);
            @(posedge axi.aclk);
        end
    endtask
    task axi_rd(input [AXI_ADDR_WIDTH-1:0] araddr,
                output [WIDTH-1:0] rdata,
                output err);
        begin
            axi.arvalid <= 1;
            axi.araddr  <= araddr;
            @(posedge axi.aclk);
            while (!axi.arready) @(posedge axi.aclk);
            axi.arvalid <= 0;
            axi.rready  <= 1;
            @(posedge axi.aclk);
            while (!axi.rvalid) @(posedge axi.aclk);
            axi.rready  <= 0;
            rdata       <= axi.rdata;
            err         <= (axi.rresp != 2'b00);
            @(posedge axi.aclk);
        end
    endtask


    // Stimulus
    integer i;
    logic ready;
    initial begin

        #CLK_PERIOD;
        while (rst) #CLK_PERIOD;
        #CLK_PERIOD;

        while (1) begin

            ready = $random();
            if (ready) begin
                // Test TX

                $write("%4d:    Testing TX function\n", clk_count);
                $fwrite(fid,"%4d:    Testing TX function\n", clk_count);
                ready = 0;
                while (!ready) begin
                    // Wait until TX FIFO empty
                    axi_rd(UARTx_CONF, _data32, _err);
                    if (_err) begin
                        fail_count++;
                        $write("%4d:        AXI ERROR unable to check tx_empty\n", clk_count);
                        $fwrite(fid,"%4d:        AXI ERROR unable to check tx_empty\n", clk_count);
                    end
                    ready = (_data32 & UARTx_CONF_TX_EMPTY) ? 1 : 0;
                    if (!ready) begin
                        $write("%4d:        Waiting until TX FIFO is empty ", clk_count);
                        $write("(0x%04X_%04X)\n", _data32[31:16], _data32[15:0]);
                        $fwrite(fid,"%4d:        Waiting until TX FIFO is empty ", clk_count);
                        $fwrite(fid,"(0x%04X_%04X)\n", _data32[31:16], _data32[15:0]);
                    end
                end

                _data = $random();
                _data32 = 0;
                $write("%4d:        Sending 0x%02X\n", clk_count, _data);
                $fwrite(fid,"%4d:        Sending 0x%02X\n", clk_count, _data);
                axi_wr(UARTx_DATA, _data, _err);
                if (_err) begin
                    fail_count++;
                    $write("%4d:        AXI ERROR unable to write byte to TX\n", clk_count);
                    $fwrite(fid,"%4d:        AXI ERROR unable to write byte to TX\n", clk_count);
                end
                else begin
                    // Wait for start bit
                    while (tx) #CLK_PERIOD;
                    #(3*CLK_PERIOD); // sample between transitions
                    #(8*CLK_PERIOD);
                    $write("%4d:        TX: ", clk_count);
                    $fwrite(fid,"%4d:        TX: ", clk_count);
                    // Data bits
                    for (i=0; i<8; i++) begin
                        $write("%b", tx);
                        $fwrite(fid,"%b", tx);
                        _data32[i] = tx;
                        #(8*CLK_PERIOD);
                    end
                    $write("  (0x%02X)\n", _data32[7:0]);
                    $fwrite(fid,"  (0x%02X)\n", _data32[7:0]);
                    // Stop bit
                    if (!tx) begin
                        fail_count++;
                        $write("%4d:        ERROR bad stop bit detected\n", clk_count);
                        $fwrite(fid,"%4d:        ERROR bad stop bit detected\n", clk_count);
                    end
                    else if (_data32[7:0] != _data) begin
                        fail_count++;
                        $write("%4d:        ERROR incorrect data transmitted\n", clk_count);
                        $fwrite(fid,"%4d:        ERROR incorrect data transmitted\n", clk_count);
                    end
                    else begin
                        pass_count++;
                        $write("%04d        Pass\n", clk_count);
                        $fwrite(fid,"%04d        Pass\n", clk_count);
                    end
                end

            end // end test TX
            else begin
                // Test RX

                $write("%4d:    Testing RX function\n", clk_count);
                $fwrite(fid,"%4d:    Testing RX function\n", clk_count);
                ready = 0;
                while (!ready) begin
                    // Wait for RX FIFO empty
                    axi_rd(UARTx_CONF, _data32, _err);
                    if (_err) begin
                        fail_count++;
                        $write("%4d:        AXI ERROR unable to check rx_empty\n", clk_count);
                        $fwrite(fid,"%4d:        AXI ERROR unable to check rx_empty\n", clk_count);
                    end
                    ready = (_data32 & UARTx_CONF_RX_EMPTY) ? 1 : 0;
                    if (!ready) begin
                        $write("%4d:        Waiting until RX FIFO is empty (0x%04X_%04X)\n",
                            clk_count, _data32[31:16], _data32[15:0]);
                        $fwrite(fid,"%4d:        Waiting until RX FIFO is empty (0x%04X_%04X)\n",
                            clk_count, _data32[31:16], _data32[15:0]);
                    end
                end

                _data = $random();
                $write("%4d:        Sending 0x%02X\n", clk_count, _data);
                $fwrite(fid,"%4d:        Sending 0x%02X\n", clk_count, _data);
                // Start bit
                rx <= 0;
                #(8*CLK_PERIOD);
                $write("%4d:        RX: ", clk_count);
                $fwrite(fid,"%4d:        RX: ", clk_count);
                // Data bits
                for (i=0; i<8; i++) begin
                    $write("%b", _data[i]);
                    $fwrite(fid,"%b", _data[i]);
                    rx <= _data[i];
                    #(8*CLK_PERIOD);
                end
                $write("  (0x%02X)\n", _data);
                $fwrite(fid,"  (0x%02X)\n", _data);
                // Stop bit
                rx <= 1;
                #(8*CLK_PERIOD);
                // Check rx
                ready = 0;
                while (!ready) begin
                    axi_rd(UARTx_CONF, _data32, _err);
                    if (_err) begin
                        fail_count++;
                        $write("%4d:        AXI ERROR unable to read rx_empty\n", clk_count);
                        $fwrite(fid,"%4d:        AXI ERROR unable to read rx_empty\n", clk_count);
                    end
                    else if (_data32 & UARTx_CONF_RX_ERR) begin
                        fail_count++;
                        $write("%4d:        ERROR RX error flag set (0x%04X_%04X)\n",
                            clk_count, _data32[31:16], _data32[15:0]);
                        $fwrite(fid,"%4d:        ERROR RX error flag set (0x%04X_%04X)\n",
                            clk_count, _data32[31:16], _data32[15:0]);
                    end
                    ready = (_data32 & UARTx_CONF_RX_EMPTY) ? 0 : 1;
                    if (!ready) begin
                        $write("%4d:        Waiting until RX FIFO is not empty (0x%04X_%04X)\n",
                            clk_count, _data32[31:16], _data32[15:0]);
                        $fwrite(fid,"%4d:        Waiting until RX FIFO is not empty (0x%04X_%04X)\n",
                            clk_count, _data32[31:16], _data32[15:0]);
                    end
                end
                axi_rd(UARTx_DATA, _data32, _err);
                if (_err) begin
                    fail_count++;
                    $write("%4d:        AXI ERROR unable to read rx data\n", clk_count);
                    $fwrite(fid,"%4d:        AXI ERROR unable to read rx data\n", clk_count);
                end
                else if (_data32[7:0] != _data) begin
                    fail_count++;
                    $write("%4d:        ERROR received 0x%02X\n", clk_count, _data32[7:0]);
                    $fwrite(fid,"%4d:        ERROR received 0x%02X\n", clk_count, _data32[7:0]);
                end
                else begin
                    pass_count++;
                    $write("%4d:        Pass\n", clk_count);
                    $fwrite(fid,"%4d:        Pass\n", clk_count);
                end

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
                $write("\n\nFAILED    %3d tests\n\n", fail_count);
                $fwrite(fid,"\n\nFailed    %3d tests\n\n", fail_count);
            end
            else begin
                $write("\n\nPASSED all %3d tests\n\n", pass_count);
                $fwrite(fid,"\n\nPASSED all %3d tests\n\n", pass_count);
            end
            $fclose(fid);
            $finish();
        end
    end

endmodule
