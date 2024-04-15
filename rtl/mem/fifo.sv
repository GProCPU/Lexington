`timescale 1ns/1ps


module fifo #(
        parameter WIDTH = 8,        // data width
        parameter DEPTH = 4,        // FIFO depth (must be power of 2)
        parameter FIRST_WORD_FALLTHROUGH = 0
    )
    (
        input  logic clk,
        input  logic rst_n,

        input  logic wr_en,
        input  logic [WIDTH-1:0] din,
        output logic full,

        input  logic rd_en,
        output logic [WIDTH-1:0] dout,
        output logic empty
    );

    logic [WIDTH-1:0] ram [DEPTH-1:0];

    // Read/Write pointers
    logic [$clog2(DEPTH)-1:0] head;
    logic [$clog2(DEPTH)-1:0] tail;
    logic _wr_en;
    logic _rd_en;

    generate
        if (FIRST_WORD_FALLTHROUGH) begin
            assign dout = ram[head];
        end
        else begin
            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    dout <= 0;
                end
                else begin
                    if (_rd_en) begin
                        dout <= ram[head];
                    end
                end
            end
        end
    endgenerate


    assign full = (!empty) && (head == tail);
    assign _wr_en = wr_en && !full;
    assign _rd_en = rd_en && !empty;


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            head = 0;
            tail = 0;
            empty = 1;
        end
        else begin
            if (_wr_en) begin
                ram[tail] <= din;
                tail <= (tail < DEPTH-1) ? tail+1 : 0;
                empty <= 0;
            end
            if (_rd_en) begin
                head <= (head < DEPTH-1) ? head+1 : 0;
                if (head < DEPTH-1) begin
                    head <= head + 1;
                    if (!_wr_en && (head+1)==tail) begin
                        empty <= 1;
                    end
                end
                else begin
                    head <= 0;
                    if (!_wr_en && tail==0) begin
                        empty <= 1;
                    end
                end
            end
        end
    end


endmodule
