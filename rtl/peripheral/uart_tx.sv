`timescale 1ns/1ps


module uart_tx #(
        parameter BUS_CLK           = 10_000_000,       // Bus clock frequency in Hz
        parameter BAUD              = 9600              // BAUD rate
    ) (
        input  logic clk,                               // Bus clock
        input  logic clk_en,                            // Clock enable
        input  logic rst_n,                             // Reset (active-low)

        output logic tx,                                // TX serial output

        input  logic send,                              // Pulse for one bus clock cycle to start TX
        input  logic [7:0] dout,                        // Byte to send

        output logic busy                               // Asserted when busy transmitting
    );

    enum {IDLE, START, DATA} state;

    integer bit_idx;
    logic [7:0] _dout; // latch the output data


    // State Machine
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state   <= IDLE;
            tx      <= 1;
            busy    <= 0;
        end
        else if (clk_en) begin
            case (state)

                IDLE: begin
                    if (send) begin
                        state   <= START;
                        _dout   <= dout; // latch data
                        tx      <= 0; // start bit
                        busy    <= 1;
                    end
                end

                START: begin
                    state   <= DATA;
                    tx      <= _dout[0];
                    bit_idx <= 1;
                end

                DATA: begin
                    if (bit_idx < 8) begin
                        tx  <= _dout[bit_idx];
                        bit_idx++;
                    end
                    else begin
                        state   <= IDLE;
                        tx      <= 1; // stop bit
                        busy    <= 0;
                    end
                end

                default: begin
                    state   <= IDLE;
                    tx      <= 1;
                    busy    <= 0;
                end

            endcase
        end
    end

endmodule
