//depend peripheral/uart_rx.sv
//depend peripheral/uart_tx.sv
//depend mem/fifo.sv
`timescale 1ns/1ps

`include "axi4_lite.sv"


module uart #(
        parameter WIDTH         = 32,           // bus data width
        parameter BUS_CLK       = 10_000_000,   // bus clock frequency in Hz
        parameter BAUD          = 9600,         // BAUD rate
        parameter FIFO_DEPTH    = 8             // FIFO depth for both TX and RX (depth 0 is invalid)
    ) (
        input  logic rx,                        // UART RX signal
        output logic tx,                        // UART TX signal
        output logic rx_int,                    // RX interrupt
        output logic tx_int,                    // TX interrupt

        axi4_lite.subordinate axi               // AXI4-Lite subordinate interface
    );

    // AXI Registers
    logic [WIDTH-1:0] UARTx_data, UARTx_conf;
    logic [2:0] _araddr;
    logic [2:0] _awaddr;

    // RX Signals
    logic rx_clk_en;
    logic [7:0] rx_data;
    logic rx_busy_slow;
    logic rx_recv_slow;
    logic rx_err_slow;
    logic rx_recv;
    logic _rx_err; // sticky bit
    // TX Signals
    logic tx_clk_en;
    logic [7:0] tx_data;
    logic tx_send_slow;
    logic tx_busy_slow;
    logic tx_done;

    // FIFO Signals
    logic [7:0] rx_fifo_din, tx_fifo_din;
    logic [7:0] rx_fifo_dout, tx_fifo_dout;
    logic rx_fifo_wr, tx_fifo_wr;
    logic rx_fifo_rd, tx_fifo_rd;
    logic rx_fifo_full, tx_fifo_full;
    logic rx_fifo_empty, tx_fifo_empty;

    // Register Fields
    logic [2:0] rx_int_conf;
    logic [1:0] tx_int_conf;
    logic sreset; //soft reset
    assign UARTx_data[7:0] = rx_fifo_din;
    assign UARTx_data[WIDTH-1:8] = 0;
    assign UARTx_conf[5:0] = {tx_fifo_empty, tx_fifo_full,
                            rx_fifo_empty, rx_fifo_full,
                            tx_busy_slow, rx_busy_slow};
    assign UARTx_conf[7:6] = rx_int_conf;
    assign UARTx_conf[9:8] = tx_int_conf;
    assign UARTx_conf[29:10] = 0;
    assign UARTx_conf[30] = sreset; assign sreset = 0; // not implemented yet
    assign UARTx_conf[31] = _rx_err;

    // Interrupt Sources
    assign rx_int = (rx_int_conf[0] && rx_recv)
                    || (rx_int_conf[1] && rx_fifo_full)
                    || (rx_int_conf[2] && _rx_err);
    assign tx_int = (tx_int_conf[0] && tx_done)
                    || (tx_int_conf[1] && tx_fifo_empty);


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: RX/TX FIFO
    ////////////////////////////////////////////////////////////
    assign rx_fifo_din = rx_data;
    fifo #(
        .WIDTH(8),
        .DEPTH(FIFO_DEPTH),
        .FIRST_WORD_FALLTHROUGH(1)
    ) rx_fifo (
        .clk(axi.aclk),
        .rst_n(axi.areset_n),
        .wr_en(rx_fifo_wr),
        .din(rx_fifo_din),
        .full(rx_fifo_full),
        .rd_en(rx_fifo_rd),
        .dout(rx_fifo_dout),
        .empty(rx_fifo_empty)
    );
    assign tx_data = tx_fifo_dout;
    fifo #(
        .WIDTH(8),
        .DEPTH(FIFO_DEPTH),
        .FIRST_WORD_FALLTHROUGH(0)
    ) tx_fifo (
        .clk(axi.aclk),
        .rst_n(axi.areset_n),
        .wr_en(tx_fifo_wr),
        .din(tx_fifo_din),
        .full(tx_fifo_full),
        .rd_en(tx_fifo_rd),
        .dout(tx_fifo_dout),
        .empty(tx_fifo_empty)
    );
    ////////////////////////////////////////////////////////////
    // END: RX/TX FIFO
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: RX/TX Submodules
    ////////////////////////////////////////////////////////////
    uart_rx #(
        .BUS_CLK(BUS_CLK),
        .BAUD(BAUD)
    ) RX (
        .clk(axi.aclk),
        .clk_en(rx_clk_en),
        .rst_n(axi.areset_n),
        .rx,
        .din(rx_data),
        .busy(rx_busy_slow),
        .recv(rx_recv_slow),
        .err(rx_err_slow)
    );
    uart_tx #(
        .BUS_CLK(BUS_CLK),
        .BAUD(BAUD)
    ) TX (
        .clk(axi.aclk),
        .clk_en(tx_clk_en),
        .rst_n(axi.areset_n),
        .tx,
        .send(tx_send_slow),
        .dout(tx_data),
        .busy(tx_busy_slow)
    );
    ////////////////////////////////////////////////////////////
    // END: RX/TX Submodules
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN:: Baud rate generator
    ////////////////////////////////////////////////////////////
    integer counter;
    integer counter8;
    localparam BAUD_DIVIDER = BUS_CLK / (8*BAUD);
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            counter     <= 0;
            counter8    <= 0;
            rx_clk_en   <= 0;
            tx_clk_en   <= 0;
        end
        else begin
            if (counter >= BAUD_DIVIDER-1) begin
                counter   <= 0;
                rx_clk_en <= 1;
                if (counter8 >= 7) begin
                    counter8 <= 0;
                    tx_clk_en <= 1;
                end
                else begin
                    counter8++;
                    tx_clk_en <= 0;
                end
            end
            else begin
                counter++;
                rx_clk_en <= 0;
                tx_clk_en <= 0;
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Baud Rate Generator
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Submodule Control Logic
    ////////////////////////////////////////////////////////////
    logic tx_busy;
    logic rx_recv_slow_prev;
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            rx_recv <= 0;       // interrupt trigger
            tx_done <= 0;       // interrupt trigger
            tx_busy <= 0;       // track state in fast clock domain
            rx_fifo_wr <= 0;
            tx_fifo_rd <= 0;
            tx_send_slow <= 0;
            rx_recv_slow_prev <= 0;
        end
        else begin
            // RX control logic
            rx_recv_slow_prev <= rx_recv_slow;
            if (rx_recv_slow && !rx_recv_slow_prev) begin // edge detect
                // Transmission received
                rx_recv     <= 1;
                rx_fifo_wr  <= 1;
            end
            else begin
                rx_recv     <= 0;
                rx_fifo_wr  <= 0;
            end
            // TX control logic
            if (tx_busy) begin
                tx_fifo_rd <= 0;
                if (tx_send_slow) begin
                    // Waiting for TX to start
                    if (tx_busy_slow) begin
                        tx_send_slow <= 0;
                    end
                end
                else begin
                    // Waiting for TX to finish
                    if (!tx_busy_slow) begin
                        tx_done <= 1;
                        tx_busy <= 0;
                    end
                end
            end
            else begin
                // TX idle
                tx_done <= 0;
                if (tx_fifo_rd) begin
                    tx_busy      <= 1;
                    tx_fifo_rd   <= 0;
                    tx_send_slow <= 1;
                end
                else if (!tx_fifo_empty) begin
                    tx_fifo_rd   <= 1;
                end
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Submodule Control Logic
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: AXI Read Channels
    ////////////////////////////////////////////////////////////
    enum {AR_READY, RD_FIFO, R_VALID} rd_state;
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            rd_state    <= AR_READY;
            axi.arready <= 1;
            axi.rvalid  <= 0;
            axi.rresp   <= axi.OKAY;
            rx_fifo_rd  <= 0;
            _rx_err     <= 0;
        end
        else begin
            case (rd_state)
                AR_READY: begin // arready asserted, waiting for arvalid
                    if (axi.arvalid) begin
                        rd_state    <= R_VALID;
                        axi.arready <= 0;
                        axi.rvalid  <= 1;
                        axi.rresp   <= (|axi.araddr[1:0]) ? axi.SLVERR : axi.OKAY;
                        _araddr     <= axi.araddr;
                        case (axi.araddr)
                            4'h0: begin
                                rd_state    <= RD_FIFO;
                                rx_fifo_rd  <= 1;
                                axi.rvalid  <= 0;
                            end
                            4'h4: begin
                                axi.rdata   <= UARTx_conf;
                                _rx_err     <= 0; // clear sticky bit
                            end
                            default: axi.rdata <= 0;
                        endcase
                    end
                end
                RD_FIFO: begin // Read data from RX FIFO
                    rd_state    <= R_VALID;
                    rx_fifo_rd  <= 0;
                    axi.rvalid  <= 1;
                    axi.rdata   <= rx_fifo_dout;
                end
                R_VALID: begin // rvalid asserted, waiting for rready
                    rx_fifo_rd <= 0;
                    if (axi.rready) begin
                        rd_state    <= AR_READY;
                        axi.arready <= 1;
                        axi.rvalid  <= 0;
                    end
                end
                default: begin // invalid state
                    rd_state    <= AR_READY;
                    rx_fifo_rd  <= 0;
                    axi.arready <= 1;
                    axi.rvalid  <= 0;
                end
            endcase
            if (rx_err_slow) begin
                // write to sticky bit
                _rx_err <= 1;
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: AXI Read Channels
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: AXI Write Channels
    ////////////////////////////////////////////////////////////
    enum {AW_READY, W_READY, B_VALID} wr_state;
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            wr_state    <= AW_READY;
            axi.awready <= 1;
            axi.wready  <= 0;
            axi.bvalid  <= 0;
            axi.bresp   <= axi.OKAY;
            rx_int_conf <= 0;
            tx_int_conf <= 0;
            _awaddr     <= 0;
            tx_fifo_wr  <= 0;
        end
        else begin
            case (wr_state)
                AW_READY: begin // awready asserted, waiting for awvalid
                    if (axi.awvalid) begin
                        wr_state    <= W_READY;
                        axi.awready <= 0;
                        axi.wready  <= 1;
                        _awaddr     <= axi.awaddr;
                    end
                end
                W_READY: begin // wready asserted, waiting for wvalid
                    if (axi.wvalid) begin
                        wr_state    <= B_VALID;
                        axi.wready  <= 0;
                        axi.bvalid  <= 1;
                        axi.bresp   <= axi.OKAY; // default to OKAY
                        case (_awaddr)
                            4'h0: begin
                                tx_fifo_wr  <= 1; // write to TX FIFO
                                tx_fifo_din <= axi.wdata[7:0];
                            end
                            4'h4: begin
                                rx_int_conf <= axi.wdata[8:6];
                                tx_int_conf <= axi.wdata[10:9];
                            end
                            default: axi.bresp <= axi.SLVERR; // address misaligned
                        endcase
                    end
                end
                B_VALID: begin // bvalid asserted, waiting for bready
                    tx_fifo_wr <= 0;
                    if (axi.bready) begin
                        wr_state    <= AW_READY;
                        axi.awready <= 1;
                        axi.bvalid  <= 0;
                    end
                end
                default: begin // invalid state
                    wr_state    <= AW_READY;
                    tx_fifo_wr  <= 0;
                    axi.awready <= 1;
                    axi.wready  <= 0;
                    axi.bvalid  <= 0;
                end
            endcase
        end
    end
    ////////////////////////////////////////////////////////////
    // END: AXI Write Channels
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


endmodule
