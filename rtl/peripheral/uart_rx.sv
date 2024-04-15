`timescale 1ns/1ps


module uart_rx #(
        parameter BUS_CLK           = 10_000_000,       // Bus clock frequency in Hz
        parameter BAUD              = 9600              // BAUD rate
    ) (
        input  logic clk,                               // Bus clock
        input  logic clk_en,                            // Clock enable for over-8 sampling
        input  logic rst_n,                             // Reset (active-low)

        input  logic rx,                                // RX serial input

        output logic [7:0] din,                         // Receive data
        output logic busy,                              // Asserted when receiving data
        output logic recv,                              //
        output logic err                                //
    );

    enum {IDLE, START, DATA, STOP} state;

    logic [7:0] _din; // shadow data
    integer bit_idx;
    integer counter8;
    logic sample, sample2;


    // Sample data
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // nothing
        end
        else if (clk_en) begin
            case (counter8)
                3:  sample  <= rx;
                4:  sample2 <= rx;
                5:  sample  <= (sample & sample2) | (sample & rx) | (sample2 & rx);
            endcase
        end
    end


    // State machine
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state       <= IDLE;
            _din        <= 0;
            busy        <= 0;
            recv        <= 0;
            err         <= 0;
            counter8    <= 0;
        end
        else if (clk_en) begin
            case (state)

                IDLE: begin
                    recv <= 0; // clear receive flag after 1 BAUD/8 cycle
                    if (!rx) begin
                        state       <= START;
                        busy        <= 1;
                        counter8    <= 1; // set to one because this is  the first cycle of the start bit
                    end
                end

                START: begin
                    if (counter8 < 7) begin
                        counter8++;
                    end
                    else begin
                        if (!sample) begin
                            state       <= DATA;
                            bit_idx     <= 0;
                            counter8    <= 0;
                        end
                        else begin
                            // not a real start bit
                            state       <= IDLE;
                            counter8    <= 0;
                        end
                    end
                end

                DATA: begin
                    if (counter8 < 7) begin
                        counter8++;
                    end
                    else begin
                        counter8    <= 0;
                        _din[bit_idx] <= sample;
                        if (bit_idx < 7) begin
                            bit_idx++;
                        end
                        else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (counter8 < 6) begin
                        counter8++;
                    end
                    else begin
                        // return to IDLE state 1 BAUD/8 cycle early
                        // in case of back-to-back transmissions
                        state   <= IDLE;
                        din     <= _din;
                        busy    <= 0;
                        recv    <= 1;
                        err     <= !sample;
                    end
                end

                default: begin
                    state       <= IDLE;
                    _din        <= 0;
                    busy        <= 0;
                    recv        <= 0;
                    err         <= 0;
                    counter8    <= 0;
                end

            endcase
        end
    end

endmodule
