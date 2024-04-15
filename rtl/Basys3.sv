//depend sync.sv
//depend reset.sv
//depend soc.sv
//depend core.sv
//depend core/*.sv
//depend mem/*.sv
//depend axi4_lite_manager.sv
//depend axi4_lite_crossbar8.sv
//depend peripheral/*.sv
`timescale 1ns/1ps


// Top module for implementing Lexington CPU on the Digilent Basys3
module Basys3 (

    // Clock signal
    input  logic sys_clk_pin,                   // Basys3 input clock

    // Switches
    inout  logic [15:0] sw,

    // LEDs
    output logic [15:0] led,

    // 7 Segment Display
    output logic [6:0] seg,
    output logic [3:0] an,
    output logic dp,

    // Buttons
    inout  logic btnC,
    inout  logic btnU,
    inout  logic btnL,
    inout  logic btnR,
    inout  logic btnD,

    // Pmod Headers
    inout  logic [7:0] JA,
    inout  logic [7:0] JB,
    inout  logic [7:0] JC,
    inout  logic [7:0] JXADC,

    // VGA Connector
    output logic [3:0] vgaRed,
    output logic [3:0] vgaBlue,
    output logic [3:0] vgaGreen,
    output logic Hsync,
    output logic Vsync,

    // USB-RS232 Interface (UART)
    input  logic RsRx,
    output logic RsTx,

    // USB HID (PS/2)
    input  logic PS2Clk,
    input  logic PS2Data

);

    // SOC signals
    logic core_clk;
    logic pxclk;
    logic slow_clk;
    logic soc_raw_rst;
    logic soc_rst_n; // soc reset
    logic [15:0] gpioa;
    logic [15:0] gpiob;
    logic [15:0] gpioc;

    // PLL signals
    logic pll_rst;
    logic pll_locked;
    logic feedback_clk;

    assign pll_rst = btnC;
    assign soc_raw_rst = pll_rst | (!pll_locked);

    assign slow_clk = core_clk;
    reset RESET (
        .clk(slow_clk),
        .rst_n_i(~soc_raw_rst),
        .rst_n_o(soc_rst_n)
    );

    // assign gpioa = led;
    assign led = gpioa;
    assign gpiob = sw;
    assign gpioc[7:0] = JA;
    assign gpioc[11:8] = JB[3:0];
    assign gpioc[12] = btnU;
    assign gpioc[13] = btnL;
    assign gpioc[14] = btnR;
    assign gpioc[15] = btnD;


    soc #(
        .CLK_FREQ(10_000_000),
        .UART0_BAUD(9600),
        .UART0_FIFO_DEPTH(16)
    ) SOC (
        .clk(core_clk),
        .pxclk,
        .rst_n(soc_rst_n),
        .gpioa,
        .gpiob,
        .gpioc,
        .uart0_rx(RsRx),
        .uart0_tx(RsTx),
        .vga_r(vgaRed),
        .vga_g(vgaGreen),
        .vga_b(vgaBlue),
        .vga_hs(Hsync),
        .vga_vs(Vsync)
    );

    // MMCME2_BASE: Base Mixed Mode Clock Manager
    // 7 Series
    // Xilinx HDL Libraries Guide, version 2012.2
    // The valid FVCO range for speed grade -1 is 600MHz to 1200MHz
    // Configured to generate 10 MHz clock (100*15.625/78.125/2)
    // Parameters from Vivado Clocking Wizard
    //      Output Freq     CLKFBOUT_MULT_F     CLKOUT0_DIVIDE_F    DIVCLK_DIVIDE
    //          100 MHz         10                  10                  1
    //           90 MHz         49.5                11                  5
    //           80 MHz         10                  12.5                1
    //           70 MHz         49.875              14.25               5
    //           60 MHz         49.875              16.625              5
    //           50 MHz         10                  20                  1
    //           40 MHz         10                  25                  1
    //           30 MHz         49.875              33.25               5
    //           20 MHz          8.5                42.5                1
    //           16 MHz         10                  62.5                1
    //           12 MHz         49.875              83.125              5
    //           10 MHz         15.625              78.125              2
    //            8 MHz         10                 125                  1
    //            5 MHz         32                 128                  5
    // Parameters with 25 MHz VGA clock (CLKOUT0 = core_clk, CLKOUT1 = pxclk)
    //      Output Freq     CLKFBOUT_MULT_F     CLKOUT0_DIVIDE_F    CLK_OUT1_DIVIDE     DIVCLK_DIVIDE
    //           40 MHz         10.000              25.000              40                  1
    //           35 MHz         10.500              30.000              42                  1
    //           30 MHz          9.750              32.500              39                  1
    //           25 MHz         10.000              40.000              40                  1
    //           20 MHz         10.000              50.000              40                  1
    //           15 MHz          9.750              65.000              39                  1
    //           10 MHz         10.000             100.000              40                  1
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),    // Jitter programming (OPTIMIZED, HIGH, LOW)
        .CLKFBOUT_MULT_F(10.000),   // Multiply value for all CLKOUT (2.000-64.000).
        .CLKFBOUT_PHASE(0.0),       // Phase offset in degrees of CLKFB (-360.000-360.000).
        .CLKIN1_PERIOD(10.0),       // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
        .CLKOUT0_DIVIDE_F(100.000), // Divide amount for CLKOUT0 (1.000-128.000).
        .CLKOUT1_DIVIDE(40),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT6_DIVIDE(1),
        // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT6_DUTY_CYCLE(0.5),
        // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_PHASE(0.0),
        .CLKOUT2_PHASE(0.0),
        .CLKOUT3_PHASE(0.0),
        .CLKOUT4_PHASE(0.0),
        .CLKOUT5_PHASE(0.0),
        .CLKOUT6_PHASE(0.0),
        .CLKOUT4_CASCADE("FALSE"),  // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        .DIVCLK_DIVIDE(1),          // Master division value (1-106)
        .REF_JITTER1(0.0),          // Reference input jitter in UI (0.000-0.999).
        .STARTUP_WAIT("TRUE")       // Delays DONE until MMCM is locked (FALSE, TRUE)
    )
    MMCME2_BASE_inst (
        // Clock Outputs: 1-bit (each) output: User configurable clock outputs
        .CLKOUT0(core_clk),         // 1-bit output: CLKOUT0
        .CLKOUT0B(),                // 1-bit output: Inverted CLKOUT0
        .CLKOUT1(pxclk),            // 1-bit output: CLKOUT1
        .CLKOUT1B(),                // 1-bit output: Inverted CLKOUT1
        .CLKOUT2(),                 // 1-bit output: CLKOUT2
        .CLKOUT2B(),                // 1-bit output: Inverted CLKOUT2
        .CLKOUT3(),                 // 1-bit output: CLKOUT3
        .CLKOUT3B(),                // 1-bit output: Inverted CLKOUT3
        .CLKOUT4(),                 // 1-bit output: CLKOUT4
        .CLKOUT5(),                 // 1-bit output: CLKOUT5
        .CLKOUT6(),                 // 1-bit output: CLKOUT6
        // Feedback Clocks: 1-bit (each) output: Clock feedback ports
        .CLKFBOUT(feedback_clk),    // 1-bit output: Feedback clock
        .CLKFBOUTB(),               // 1-bit output: Inverted CLKFBOUT
        // Status Ports: 1-bit (each) output: MMCM status ports
        .LOCKED(pll_locked),        // 1-bit output: LOCK
        // Clock Inputs: 1-bit (each) input: Clock input
        .CLKIN1(sys_clk_pin),       // 1-bit input: Clock
        // Control Ports: 1-bit (each) input: MMCM control ports
        .PWRDWN(1'b0),              // 1-bit input: Power-down
        .RST(pll_rst),              // 1-bit input: Reset
        // Feedback Clocks: 1-bit (each) input: Clock feedback ports
        .CLKFBIN(feedback_clk)      // 1-bit input: Feedback clock
    );
    // End of MMCME2_BASE_inst instantiation


endmodule
