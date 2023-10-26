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

    generate if (FIRST_WORD_FALLTHROUGH) begin
        assign dout = ram[head];
    end endgenerate
    assign full = (!empty) && (head == tail);
    assign wr_en = wr_en && !full;


    always_ff @(posedge clk) begin
        if (rst_n) begin
            head = 0;
            tail = 0;
            empty = 1;
        end
        else begin
            if (wr_en && !full) begin
                ram[tail] <= din;
                tail <= (tail < DEPTH-1) ? tail+1 : 0;
            end
            if (rd_en && !empty) begin
                if (!FIRST_WORD_FALLTHROUGH) begin
                    dout <= ram[head];
                end
                head <= (head < DEPTH-1) ? head+1 : 0;
                if (head < DEPTH-1) begin
                    head <= head + 1;
                    if (!wr_en && (head+1)==tail) begin
                        empty <= 1;
                    end
                end
                else begin
                    head <= 0;
                    if (!wr_en && tail==0) begin
                        empty <= 1;
                    end
                end
            end
        end
    end


endmodule
