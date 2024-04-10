//depend mem/dual_port_ram.sv
`timescale 1ns/1ps


module vga_frame_buff #(
        parameter PIXEL_WIDTH       = 640,
        parameter PIXEL_HEIGHT      = 480,
        parameter PIXEL_DEPTH       = 8,
        parameter AXI_DATA_WIDTH    = 32,
        localparam NUM_PIXELS       = PIXEL_WIDTH * PIXEL_HEIGHT,
        localparam PIXEL_ADDR_WIDTH = $clog2(NUM_PIXELS)                    // pixel-addressable
    ) (
        input  logic pxclk,
        input  logic rst_n,

        input  logic [PIXEL_ADDR_WIDTH-1:0] px_addr,
        output logic [PIXEL_DEPTH-1:0] px_data,

        axi4_lite.subordinate axi
    );

    localparam PADDED_PIXEL_DEPTH = (PIXEL_DEPTH <= 8) ? 8 :
                                    (PIXEL_DEPTH <= 16) ? 16 :
                                    32;
    localparam AXI_ADDR_WIDTH = $clog2(NUM_PIXELS * (PADDED_PIXEL_DEPTH/8));
    localparam WORD_ADDR_WIDTH = AXI_ADDR_WIDTH - $clog2(AXI_DATA_WIDTH/8);

    // VGA read signals
    logic [WORD_ADDR_WIDTH-1:0] _raw_px_addr;
    logic [AXI_DATA_WIDTH-1:0] _raw_px_data;

    // AXI read internal buffers
    logic [WORD_ADDR_WIDTH-1:0] _araddr;
    logic [AXI_DATA_WIDTH-1:0] _rdata, _rdata_reg;

    // AXI write internal buffers
    logic [WORD_ADDR_WIDTH-1:0] _awaddr;
    logic [AXI_DATA_WIDTH-1:0] _wdata;
    logic [(AXI_DATA_WIDTH/8)-1:0] _wstrb;

    // Arbiter RAM signal for AXI read/write
    logic _ram_rd_req;
    logic _ram_wr_req;
    logic _ram_rd_ack;
    logic _ram_wr_ack;
    logic _ram_en;
    logic [(AXI_DATA_WIDTH/8)-1:0] _ram_wen;
    logic [WORD_ADDR_WIDTH-1:0] _ram_addr;


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Frame Buffer RAM Instantiation
    ////////////////////////////////////////////////////////////
    bytewrite_dual_port_ram #(
        .NUM_COL(AXI_DATA_WIDTH/8), // write-enable lanes
        .COL_WIDTH(8),              // bits-per write-enable line
        .ADDR_WIDTH(WORD_ADDR_WIDTH)
        // DATA_WIDTH = NUM_COL * COL_WIDTH
    ) FRAME_BUFF (
        .clk_a(pxclk),
        .en_a(1'b1),
        .wen_a({(AXI_DATA_WIDTH/8){1'b0}}),
        .addr_a(_raw_px_addr),
        .din_a(0),
        .dout_a(_raw_px_data),
        .clk_b(axi.aclk),
        .en_b(_ram_en),
        .wen_b(_ram_wen),
        .addr_b(_ram_addr),
        .din_b(_wdata),
        .dout_b(_rdata)
    );
    ////////////////////////////////////////////////////////////
    // END: Frame Buffer RAM Instantiation
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: VGA read
    ////////////////////////////////////////////////////////////
    logic [PIXEL_ADDR_WIDTH-1:0] px_addr_buff;
    always_ff @(posedge pxclk) begin
        if (!rst_n) begin
            px_addr_buff <= 0;
        end
        else begin
            px_addr_buff <= px_addr;
        end
    end
    generate
        if (8 == PADDED_PIXEL_DEPTH) begin
            assign _raw_px_addr = px_addr >> 2;
            assign px_data = _raw_px_data >> (px_addr_buff[1:0] * PADDED_PIXEL_DEPTH);
        end
        else if (16 == PADDED_PIXEL_DEPTH) begin
            assign _raw_px_addr = px_addr >> 1;
            assign px_data = _raw_px_data >> (px_addr_buff[0] * PADDED_PIXEL_DEPTH);
        end
        else begin
            assign _raw_px_addr = px_addr;
            assign px_data = _raw_px_data;
        end
    endgenerate
    ////////////////////////////////////////////////////////////
    // END: VGA read
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: Frame Buffer AXI Arbiter
    ////////////////////////////////////////////////////////////
    always_comb begin
        if (!axi.areset_n) begin
            _ram_rd_ack = 0;
            _ram_wr_ack = 0;
            _ram_en     = 0;
            _ram_wen    = 0;
            _ram_addr   = 0;
        end
        else begin
            // prioritize writes over reads
            if (_ram_wr_req) begin
                _ram_rd_ack = 0;
                _ram_wr_ack = 1;
                _ram_en     = 1;
                _ram_wen    = _wstrb;
                _ram_addr   = _awaddr;
            end
            else if (_ram_rd_req) begin
                _ram_rd_ack = 1;
                _ram_wr_ack = 0;
                _ram_en     = 1;
                _ram_wen    = 0;
                _ram_addr   = _araddr;
            end
            else begin
                _ram_rd_ack = 0;
                _ram_wr_ack = 0;
                _ram_en     = 0;
                _ram_wen    = 0;
                _ram_addr   = 0;
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: Frame Buffer AXI Arbiter
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: AXI read (port-B)
    ////////////////////////////////////////////////////////////
    enum {AR_READY, RAM_RD, R_VALID} rd_state;
    always_ff @(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            rd_state    <= AR_READY;
            axi.arready <= 1;
            axi.rvalid  <= 0;
            axi.rresp   <= axi.OKAY;
            _araddr     <= 0;
            _rdata_reg  <= 0;
            _ram_rd_req <= 0;
        end
        else begin
            case (rd_state)

                AR_READY: begin // arready asserted, waiting for arvalid
                    if (axi.arvalid) begin
                        if (|axi.araddr[1:0]) begin // must be word-aligned
                            rd_state    <= R_VALID;
                            axi.arready <= 0;
                            axi.rvalid  <= 1;
                            axi.rresp   <= axi.SLVERR;
                        end
                        else begin
                            rd_state    <= RAM_RD;
                            axi.arready <= 0;
                            _araddr     <= axi.araddr >> $clog2(AXI_DATA_WIDTH/8);
                            _ram_rd_req <= 1;
                        end
                    end
                end

                RAM_RD: begin // waiting for RAM read
                    if (_ram_rd_ack) begin
                        rd_state    <= R_VALID;
                        axi.rvalid  <= 1;
                        axi.rresp   <= axi.OKAY;
                        _rdata_reg  <= _rdata;
                        _ram_rd_req <= 0;
                    end
                end

                R_VALID: begin // rvalid asserted, waiting for rready
                    if (axi.rready) begin
                        rd_state    <= AR_READY;
                        axi.arready <= 1;
                        axi.rvalid  <= 0;
                    end
                end

                default: begin // invalid state
                    rd_state    <= AR_READY;
                    _araddr     <= 0;
                    axi.arready <= 1;
                    axi.rvalid  <= 0;
                    axi.rresp   <= axi.OKAY;
                    _ram_rd_req <= 1;
                end

            endcase
        end
    end
    // Decode read address
    always_comb begin
        if (!rst_n) begin
            axi.rdata = 0;
        end
        else begin
            if (RAM_RD == rd_state) begin
                axi.rdata =_rdata;
            end
            else begin
                axi.rdata = _rdata_reg;
            end
        end
    end
    ////////////////////////////////////////////////////////////
    // END: AXI read (port-B)
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // BEGIN: AXI write (port-B)
    ////////////////////////////////////////////////////////////
    logic _awaddr_misaligned;
    enum {AW_READY, W_READY, RAM_WR, B_VALID} wr_state;
    always_ff@(posedge axi.aclk) begin
        if (!axi.areset_n) begin
            wr_state    <= AW_READY;
            axi.awready <= 1;
            axi.wready  <= 0;
            axi.bvalid  <= 0;
            axi.bresp   <= axi.OKAY;
            _awaddr     <= 0;
            _awaddr_misaligned <= 0;
            _wdata      <= 0;
            _wstrb      <= 0;
            _ram_wr_req <= 0;
        end
        else begin
            case (wr_state)

                AW_READY: begin // awready asserted, waiting for awvalid
                    if (axi.awvalid) begin
                        wr_state    <= W_READY;
                        _awaddr     <= axi.awaddr >> $clog2(AXI_DATA_WIDTH/8);
                        _awaddr_misaligned <= (| axi.awaddr[1:0]);
                        axi.awready <= 0;
                        axi.wready  <= 1;
                    end
                end

                W_READY: begin // wready asserted, waiting for wvalid
                    if (axi.wvalid) begin
                        if (_awaddr_misaligned) begin // must be word-aligned
                            wr_state    <= B_VALID;
                            axi.wready  <= 0;
                            axi.bvalid  <= 1;
                            axi.bresp   <= axi.SLVERR;
                        end
                        else begin
                            wr_state    <= RAM_WR;
                            axi.wready  <= 0;
                            _wdata      <= axi.wdata;
                            _wstrb      <= axi.wstrb;
                            _ram_wr_req <= 1;
                        end
                    end
                end

                RAM_WR: begin // waiting for RAM write
                    if (_ram_wr_ack) begin
                        wr_state    <= B_VALID;
                        axi.bvalid  <= 1;
                        axi.bresp   <= axi.OKAY;
                        _ram_wr_req <= 0;
                    end
                end

                B_VALID: begin // bvalid asserted, waiting for bready
                    if (axi.bready) begin
                        wr_state    <= AW_READY;
                        axi.awready <= 1;
                        axi.bvalid  <= 0;
                    end
                end

                default: begin // invalid state
                    wr_state    <= AW_READY;
                    axi.awready <= 1;
                    axi.wready  <= 0;
                    axi.bvalid  <= 0;
                    axi.bresp   <= axi.OKAY;
                    _awaddr     <= 0;
                    _awaddr_misaligned <= 0;
                    _wdata      <= 0;
                    _wstrb      <= 0;
                    _ram_wr_req <= 0;
                end

            endcase
        end
    end
    ////////////////////////////////////////////////////////////
    // END: AXI write (port-B)
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

endmodule
