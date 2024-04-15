`timescale 1ns/1ps

`include "axi4_lite.sv"


module axi4_lite_crossbar8 #(
        parameter WIDTH             = 32,               // data bus width
        parameter ADDR_WIDTH        = 32,               // upstream manager address width
        parameter S00_ADDR_WIDTH    = 4,                // Subordinate 0 address width
        parameter S01_ADDR_WIDTH    = 4,                // Subordinate 1 address width
        parameter S02_ADDR_WIDTH    = 4,                // Subordinate 2 address width
        parameter S03_ADDR_WIDTH    = 4,                // Subordinate 3 address width
        parameter S04_ADDR_WIDTH    = 4,                // Subordinate 4 address width
        parameter S05_ADDR_WIDTH    = 4,                // Subordinate 5 address width
        parameter S06_ADDR_WIDTH    = 4,                // Subordinate 6 address width
        parameter S07_ADDR_WIDTH    = 4,                // Subordinate 7 address width
        parameter S00_BASE_ADDR     = 'h00,             // Subordinate 0 base address
        parameter S01_BASE_ADDR     = 'h10,             // Subordinate 1 base address
        parameter S02_BASE_ADDR     = 'h20,             // Subordinate 2 base address
        parameter S03_BASE_ADDR     = 'h30,             // Subordinate 3 base address
        parameter S04_BASE_ADDR     = 'h40,             // Subordinate 4 base address
        parameter S05_BASE_ADDR     = 'h50,             // Subordinate 5 base address
        parameter S06_BASE_ADDR     = 'h60,             // Subordinate 6 base address
        parameter S07_BASE_ADDR     = 'h70,             // Subordinate 7 base address
        parameter S00_ENABLE        = 1,                // Subordinate 0 interface used
        parameter S01_ENABLE        = 1,                // Subordinate 1 interface used
        parameter S02_ENABLE        = 1,                // Subordinate 2 interface used
        parameter S03_ENABLE        = 1,                // Subordinate 3 interface used
        parameter S04_ENABLE        = 1,                // Subordinate 4 interface used
        parameter S05_ENABLE        = 1,                // Subordinate 5 interface used
        parameter S06_ENABLE        = 1,                // Subordinate 6 interface used
        parameter S07_ENABLE        = 1                 // Subordinate 7 interface used
    ) (
        axi4_lite.subordinate axi_m,
        axi4_lite.manager axi_s00,
        axi4_lite.manager axi_s01,
        axi4_lite.manager axi_s02,
        axi4_lite.manager axi_s03,
        axi4_lite.manager axi_s04,
        axi4_lite.manager axi_s05,
        axi4_lite.manager axi_s06,
        axi4_lite.manager axi_s07
    );

    localparam COUNT = 8;

    // Address space mask function
    function automatic logic [ADDR_WIDTH-1:0] mask_upper_bits(logic [ADDR_WIDTH-1:0] addr, integer bit_width);
        logic [ADDR_WIDTH-1:0] mask;
        mask = (~(0)) << bit_width;
        return mask & addr;
    endfunction

    logic [ADDR_WIDTH-1:0] _awaddr;     // latched write address
    logic [ADDR_WIDTH-1:0] _araddr;     // latched read address
    logic [COUNT-1:0] wr_active;        // one-hot write transaction select
    logic [COUNT-1:0] rd_active;        // one-hot read transaction select


    // Decode addresses
    always_comb begin
        if (!axi_m.areset_n) begin
            wr_active = 0;
            rd_active = 0;
        end
        else begin
            // One-hot write activity vector
            wr_active[0] = (S00_ENABLE) ?
                (mask_upper_bits(S00_BASE_ADDR, 0) == mask_upper_bits(_awaddr, S00_ADDR_WIDTH))
                : 0;
            wr_active[1] = (S01_ENABLE) ?
                (mask_upper_bits(S01_BASE_ADDR, 0) == mask_upper_bits(_awaddr, S01_ADDR_WIDTH))
                : 0;
            wr_active[2] = (S02_ENABLE) ?
                (mask_upper_bits(S02_BASE_ADDR, 0) == mask_upper_bits(_awaddr, S02_ADDR_WIDTH))
                : 0;
            wr_active[3] = (S03_ENABLE) ?
                (mask_upper_bits(S03_BASE_ADDR, 0) == mask_upper_bits(_awaddr, S03_ADDR_WIDTH))
                : 0;
            wr_active[4] = (S04_ENABLE) ?
                (mask_upper_bits(S04_BASE_ADDR, 0) == mask_upper_bits(_awaddr, S04_ADDR_WIDTH))
                : 0;
            wr_active[5] = (S05_ENABLE) ?
                (mask_upper_bits(S05_BASE_ADDR, 0) == mask_upper_bits(_awaddr, S05_ADDR_WIDTH))
                : 0;
            wr_active[6] = (S06_ENABLE) ?
                (mask_upper_bits(S06_BASE_ADDR, 0) == mask_upper_bits(_awaddr, S06_ADDR_WIDTH))
                : 0;
            wr_active[7] = (S07_ENABLE) ?
                (mask_upper_bits(S07_BASE_ADDR, 0) == mask_upper_bits(_awaddr, S07_ADDR_WIDTH))
                : 0;
            // One-hot read activity vector
            rd_active[0] = (S00_ENABLE) ?
                (mask_upper_bits(S00_BASE_ADDR, 0) == mask_upper_bits(_araddr, S00_ADDR_WIDTH))
                : 0;
            rd_active[1] = (S01_ENABLE) ?
                (mask_upper_bits(S01_BASE_ADDR, 0) == mask_upper_bits(_araddr, S01_ADDR_WIDTH))
                : 0;
            rd_active[2] = (S02_ENABLE) ?
                (mask_upper_bits(S02_BASE_ADDR, 0) == mask_upper_bits(_araddr, S02_ADDR_WIDTH))
                : 0;
            rd_active[3] = (S03_ENABLE) ?
                (mask_upper_bits(S03_BASE_ADDR, 0) == mask_upper_bits(_araddr, S03_ADDR_WIDTH))
                : 0;
            rd_active[4] = (S04_ENABLE) ?
                (mask_upper_bits(S04_BASE_ADDR, 0) == mask_upper_bits(_araddr, S04_ADDR_WIDTH))
                : 0;
            rd_active[5] = (S05_ENABLE) ?
                (mask_upper_bits(S05_BASE_ADDR, 0) == mask_upper_bits(_araddr, S05_ADDR_WIDTH))
                : 0;
            rd_active[6] = (S06_ENABLE) ?
                (mask_upper_bits(S06_BASE_ADDR, 0) == mask_upper_bits(_araddr, S06_ADDR_WIDTH))
                : 0;
            rd_active[7] = (S07_ENABLE) ?
                (mask_upper_bits(S07_BASE_ADDR, 0) == mask_upper_bits(_araddr, S07_ADDR_WIDTH))
                : 0;
        end
    end


    // Latch addresses (except not a real latch)
    logic [ADDR_WIDTH-1:0] _awaddr_reg,  _araddr_reg;
    assign _awaddr = (axi_m.awvalid) ? axi_m.awaddr : _awaddr_reg;
    assign _araddr = (axi_m.arvalid) ? axi_m.araddr : _araddr_reg;
    always_ff @(posedge axi_m.aclk) begin
        if (!axi_m.areset_n) begin
            _awaddr_reg <= 0;
            _araddr_reg <= 0;
        end
        else begin
            if (axi_m.awvalid) begin
                _awaddr_reg <= axi_m.awaddr;
            end
            if (axi_m.arvalid) begin
                _araddr_reg <= axi_m.araddr;
            end
        end
    end


    // Connect shared signals

    //////////////////////////////////////////////////
    // S00
    // axi_s00 global signals
    assign axi_s00.aclk         = axi_m.aclk;
    assign axi_s00.areset_n     = axi_m.areset_n;
    // axi_s00 write address channel
    assign axi_s00.awaddr       = axi_m.awaddr;
    assign axi_s00.awprot       = axi_m.awprot;
    // axi_s00 write data channel
    assign axi_s00.wdata        = axi_m.wdata;
    assign axi_s00.wstrb        = axi_m.wstrb;
    // axi_s00 read address
    assign axi_s00.araddr       = axi_m.araddr;
    assign axi_s00.arprot       = axi_m.arprot;

    //////////////////////////////////////////////////
    // S01
    // axi_s01 global signals
    assign axi_s01.aclk         = axi_m.aclk;
    assign axi_s01.areset_n     = axi_m.areset_n;
    // axi_s01 write address channel
    assign axi_s01.awaddr       = axi_m.awaddr;
    assign axi_s01.awprot       = axi_m.awprot;
    // axi_s01 write data channel
    assign axi_s01.wdata        = axi_m.wdata;
    assign axi_s01.wstrb        = axi_m.wstrb;
    // axi_s01 read address
    assign axi_s01.araddr       = axi_m.araddr;
    assign axi_s01.arprot       = axi_m.arprot;

    //////////////////////////////////////////////////
    // S02
    // axi_s02 global signals
    assign axi_s02.aclk         = axi_m.aclk;
    assign axi_s02.areset_n     = axi_m.areset_n;
    // axi_s02 write address channel
    assign axi_s02.awaddr       = axi_m.awaddr;
    assign axi_s02.awprot       = axi_m.awprot;
    // axi_s02 write data channel
    assign axi_s02.wdata        = axi_m.wdata;
    assign axi_s02.wstrb        = axi_m.wstrb;
    // axi_s02 read address
    assign axi_s02.araddr       = axi_m.araddr;
    assign axi_s02.arprot       = axi_m.arprot;

    //////////////////////////////////////////////////
    // S03
    // axi_s03 global signals
    assign axi_s03.aclk         = axi_m.aclk;
    assign axi_s03.areset_n     = axi_m.areset_n;
    // axi_s03 write address channel
    assign axi_s03.awaddr       = axi_m.awaddr;
    assign axi_s03.awprot       = axi_m.awprot;
    // axi_s03 write data channel
    assign axi_s03.wdata        = axi_m.wdata;
    assign axi_s03.wstrb        = axi_m.wstrb;
    // axi_s03 read address
    assign axi_s03.araddr       = axi_m.araddr;
    assign axi_s03.arprot       = axi_m.arprot;

    //////////////////////////////////////////////////
    // S04
    // axi_S04 global signals
    assign axi_s04.aclk         = axi_m.aclk;
    assign axi_s04.areset_n     = axi_m.areset_n;
    // axi_S04 write address channel
    assign axi_s04.awaddr       = axi_m.awaddr;
    assign axi_s04.awprot       = axi_m.awprot;
    // axi_S04 write data channel
    assign axi_s04.wdata        = axi_m.wdata;
    assign axi_s04.wstrb        = axi_m.wstrb;
    // axi_S04 read address
    assign axi_s04.araddr       = axi_m.araddr;
    assign axi_s04.arprot       = axi_m.arprot;

    //////////////////////////////////////////////////
    // S05
    // axi_S05 global signals
    assign axi_s05.aclk         = axi_m.aclk;
    assign axi_s05.areset_n     = axi_m.areset_n;
    // axi_S05 write address channel
    assign axi_s05.awaddr       = axi_m.awaddr;
    assign axi_s05.awprot       = axi_m.awprot;
    // axi_S05 write data channel
    assign axi_s05.wdata        = axi_m.wdata;
    assign axi_s05.wstrb        = axi_m.wstrb;
    // axi_S05 read address
    assign axi_s05.araddr       = axi_m.araddr;
    assign axi_s05.arprot       = axi_m.arprot;

    //////////////////////////////////////////////////
    // S06
    // axi_S06 global signals
    assign axi_s06.aclk         = axi_m.aclk;
    assign axi_s06.areset_n     = axi_m.areset_n;
    // axi_S06 write address channel
    assign axi_s06.awaddr       = axi_m.awaddr;
    assign axi_s06.awprot       = axi_m.awprot;
    // axi_S06 write data channel
    assign axi_s06.wdata        = axi_m.wdata;
    assign axi_s06.wstrb        = axi_m.wstrb;
    // axi_S06 read address
    assign axi_s06.araddr       = axi_m.araddr;
    assign axi_s06.arprot       = axi_m.arprot;

    //////////////////////////////////////////////////
    // S07
    // axi_S07 global signals
    assign axi_s07.aclk         = axi_m.aclk;
    assign axi_s07.areset_n     = axi_m.areset_n;
    // axi_S07 write address channel
    assign axi_s07.awaddr       = axi_m.awaddr;
    assign axi_s07.awprot       = axi_m.awprot;
    // axi_S07 write data channel
    assign axi_s07.wdata        = axi_m.wdata;
    assign axi_s07.wstrb        = axi_m.wstrb;
    // axi_S07 read address
    assign axi_s07.araddr       = axi_m.araddr;
    assign axi_s07.arprot       = axi_m.arprot;


    // Connect multiplexed signals
    // axi_m
    always_comb begin

        casez (wr_active)
            // S00
            'b????_???1: begin
                axi_m.awready   = axi_s00.awready;
                axi_m.wready    = axi_s00.wready;
                axi_m.bvalid    = axi_s00.bvalid;
                axi_m.bresp     = axi_s00.bresp;
            end
            // S01
            'b????_??10: begin
                axi_m.awready   = axi_s01.awready;
                axi_m.wready    = axi_s01.wready;
                axi_m.bvalid    = axi_s01.bvalid;
                axi_m.bresp     = axi_s01.bresp;
            end
            // S02
            'b????_?100: begin
                axi_m.awready   = axi_s02.awready;
                axi_m.wready    = axi_s02.wready;
                axi_m.bvalid    = axi_s02.bvalid;
                axi_m.bresp     = axi_s02.bresp;
            end
            // S03
            'b????_1000: begin
                axi_m.awready   = axi_s03.awready;
                axi_m.wready    = axi_s03.wready;
                axi_m.bvalid    = axi_s03.bvalid;
                axi_m.bresp     = axi_s03.bresp;
            end
            // S04
            'b???1_0000: begin
                axi_m.awready   = axi_s04.awready;
                axi_m.wready    = axi_s04.wready;
                axi_m.bvalid    = axi_s04.bvalid;
                axi_m.bresp     = axi_s04.bresp;
            end
            // S05
            'b??10_0000: begin
                axi_m.awready   = axi_s05.awready;
                axi_m.wready    = axi_s05.wready;
                axi_m.bvalid    = axi_s05.bvalid;
                axi_m.bresp     = axi_s05.bresp;
            end
            // S06
            'b?100_0000: begin
                axi_m.awready   = axi_s06.awready;
                axi_m.wready    = axi_s06.wready;
                axi_m.bvalid    = axi_s06.bvalid;
                axi_m.bresp     = axi_s06.bresp;
            end
            // S07
            'b?1000_0000: begin
                axi_m.awready   = axi_s07.awready;
                axi_m.wready    = axi_s07.wready;
                axi_m.bvalid    = axi_s07.bvalid;
                axi_m.bresp     = axi_s07.bresp;
            end
            default: begin
                axi_m.awready   = 0;
                axi_m.wready    = 0;
                axi_m.bvalid    = 0;
                axi_m.bresp     = axi_m.DECERR;
            end
        endcase

        casez (rd_active)
            // S00
            'b????_???1: begin
                axi_m.arready   = axi_s00.arready;
                axi_m.rvalid    = axi_s00.rvalid;
                axi_m.rdata     = axi_s00.rdata;
                axi_m.rresp     = axi_s00.rresp;
            end
            // S01
            'b????_??10: begin
                axi_m.arready   = axi_s01.arready;
                axi_m.rvalid    = axi_s01.rvalid;
                axi_m.rdata     = axi_s01.rdata;
                axi_m.rresp     = axi_s01.rresp;
            end
            // S02
            'b????_?100: begin
                axi_m.arready   = axi_s02.arready;
                axi_m.rvalid    = axi_s02.rvalid;
                axi_m.rdata     = axi_s02.rdata;
                axi_m.rresp     = axi_s02.rresp;
            end
            // S03
            'b????_1000: begin
                axi_m.arready   = axi_s03.arready;
                axi_m.rvalid    = axi_s03.rvalid;
                axi_m.rdata     = axi_s03.rdata;
                axi_m.rresp     = axi_s03.rresp;
            end
            // S04
            'b???1_0000: begin
                axi_m.arready   = axi_s04.arready;
                axi_m.rvalid    = axi_s04.rvalid;
                axi_m.rdata     = axi_s04.rdata;
                axi_m.rresp     = axi_s04.rresp;
            end
            // S05
            'b??10_0000: begin
                axi_m.arready   = axi_s05.arready;
                axi_m.rvalid    = axi_s05.rvalid;
                axi_m.rdata     = axi_s05.rdata;
                axi_m.rresp     = axi_s05.rresp;
            end
            // S06
            'b?100_0000: begin
                axi_m.arready   = axi_s06.arready;
                axi_m.rvalid    = axi_s06.rvalid;
                axi_m.rdata     = axi_s06.rdata;
                axi_m.rresp     = axi_s06.rresp;
            end
            // S07
            'b1000_0000: begin
                axi_m.arready   = axi_s07.arready;
                axi_m.rvalid    = axi_s07.rvalid;
                axi_m.rdata     = axi_s07.rdata;
                axi_m.rresp     = axi_s07.rresp;
            end
            default: begin
                axi_m.arready   = 0;
                axi_m.rvalid    = 0;
                axi_m.rdata     = 0;
                axi_m.rresp     = axi_m.DECERR;
            end
        endcase

    end


    // S00
    assign axi_s00.awvalid      = (wr_active[0]) ? axi_m.awvalid : 0;
    assign axi_s00.wvalid       = (wr_active[0]) ? axi_m.wvalid : 0;
    assign axi_s00.bready       = (wr_active[0]) ? axi_m.bready : 0;
    assign axi_s00.arvalid      = (rd_active[0]) ? axi_m.arvalid : 0;
    assign axi_s00.rready       = (rd_active[0]) ? axi_m.rready : 0;

    // S01
    assign axi_s01.awvalid      = (wr_active[1]) ? axi_m.awvalid : 0;
    assign axi_s01.wvalid       = (wr_active[1]) ? axi_m.wvalid : 0;
    assign axi_s01.bready       = (wr_active[1]) ? axi_m.bready : 0;
    assign axi_s01.arvalid      = (rd_active[1]) ? axi_m.arvalid : 0;
    assign axi_s01.rready       = (rd_active[1]) ? axi_m.rready : 0;

    // S02
    assign axi_s02.awvalid      = (wr_active[2]) ? axi_m.awvalid : 0;
    assign axi_s02.wvalid       = (wr_active[2]) ? axi_m.wvalid : 0;
    assign axi_s02.bready       = (wr_active[2]) ? axi_m.bready : 0;
    assign axi_s02.arvalid      = (rd_active[2]) ? axi_m.arvalid : 0;
    assign axi_s02.rready       = (rd_active[2]) ? axi_m.rready : 0;

    // S03
    assign axi_s03.awvalid      = (wr_active[3]) ? axi_m.awvalid : 0;
    assign axi_s03.wvalid       = (wr_active[3]) ? axi_m.wvalid : 0;
    assign axi_s03.bready       = (wr_active[3]) ? axi_m.bready : 0;
    assign axi_s03.arvalid      = (rd_active[3]) ? axi_m.arvalid : 0;
    assign axi_s03.rready       = (rd_active[3]) ? axi_m.rready : 0;

    // S04
    assign axi_s04.awvalid      = (wr_active[4]) ? axi_m.awvalid : 0;
    assign axi_s04.wvalid       = (wr_active[4]) ? axi_m.wvalid : 0;
    assign axi_s04.bready       = (wr_active[4]) ? axi_m.bready : 0;
    assign axi_s04.arvalid      = (rd_active[4]) ? axi_m.arvalid : 0;
    assign axi_s04.rready       = (rd_active[4]) ? axi_m.rready : 0;

    // S05
    assign axi_s05.awvalid      = (wr_active[5]) ? axi_m.awvalid : 0;
    assign axi_s05.wvalid       = (wr_active[5]) ? axi_m.wvalid : 0;
    assign axi_s05.bready       = (wr_active[5]) ? axi_m.bready : 0;
    assign axi_s05.arvalid      = (rd_active[5]) ? axi_m.arvalid : 0;
    assign axi_s05.rready       = (rd_active[5]) ? axi_m.rready : 0;

    // S06
    assign axi_s06.awvalid      = (wr_active[6]) ? axi_m.awvalid : 0;
    assign axi_s06.wvalid       = (wr_active[6]) ? axi_m.wvalid : 0;
    assign axi_s06.bready       = (wr_active[6]) ? axi_m.bready : 0;
    assign axi_s06.arvalid      = (rd_active[6]) ? axi_m.arvalid : 0;
    assign axi_s06.rready       = (rd_active[6]) ? axi_m.rready : 0;

    // S07
    assign axi_s07.awvalid      = (wr_active[7]) ? axi_m.awvalid : 0;
    assign axi_s07.wvalid       = (wr_active[7]) ? axi_m.wvalid : 0;
    assign axi_s07.bready       = (wr_active[7]) ? axi_m.bready : 0;
    assign axi_s07.arvalid      = (rd_active[7]) ? axi_m.arvalid : 0;
    assign axi_s07.rready       = (rd_active[7]) ? axi_m.rready : 0;


endmodule
